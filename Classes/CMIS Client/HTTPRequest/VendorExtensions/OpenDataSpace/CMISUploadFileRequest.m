//
//  CMISUploadFileRequest.m
//  FreshDocs
//
//  Created by bdt on 1/20/14.
//
//
#import <AssetsLibrary/AssetsLibrary.h>

#import "CMISUploadFileRequest.h"
#import "RepositoryItem.h"
#import "AssetUploadItem.h"
#import "ObjectByIdRequest.h"
#import "RepositoryItemParser.h"

#define APPEND_CHUNK_DATA_SIZE  4194304   //1024*1024*4  The maxmium value for chunk size.

@interface CMISUploadFileRequest() {
    uint8_t *readBuffer;   //read buffer
    FILE  *_uploadFileHandle;  //Document File Handle. If the source file url is file path.
}
@property (strong) NSRecursiveLock *cancelledLock;
@property (nonatomic, assign, readwrite) uint64_t    totalBytes;
@property (nonatomic, assign, readwrite) uint64_t    sentBytes;
@property (nonatomic, strong) ALAsset *uploadFileAsset; //Asset from library.If the source file url is asset URL
@property (nonatomic, assign) BOOL isCancelled;
@end

@implementation CMISUploadFileRequest
@synthesize delegate = _delegate;
@synthesize queue = _queue;
@synthesize uploadProgressDelegate = _uploadProgressDelegate;

@synthesize didStartSelector = _didStartSelector;
@synthesize didFinishSelector = _didFinishSelector;
@synthesize didFailSelector = _didFailSelector;

@synthesize cancelledLock = _cancelledLock;
@synthesize totalBytes = _totalBytes;
@synthesize sentBytes = _sentBytes;
@synthesize uploadFileAsset = _uploadFileAsset;

@synthesize isCancelled = _isCancelled;

#pragma mark -
#pragma mark Utils


#pragma mark -
#pragma mark Inital
- (id) init
{
    if (self = [super init]) {
        _uploadFileAsset = nil;
        _uploadFileHandle = nil;
        
        _didStartSelector = nil;
        _didFinishSelector = nil;
        _didFailSelector = nil;
        
        _totalBytes = 0;
        _sentBytes = 0;
        
        _delegate = nil;
        _queue = nil;
        _uploadProgressDelegate = nil;
        
        _isCancelled = NO;
        
        readBuffer = malloc(APPEND_CHUNK_DATA_SIZE);
        
        [self setCancelledLock:[[NSRecursiveLock alloc] init]];
    }
    
    return self;
}

- (void) dealloc
{
    free(readBuffer);
    if (_uploadFileHandle) {
        fclose(_uploadFileHandle);
    }
}

- (void) setUploadInfo:(UploadInfo *)uploadInfo
{
    _uploadInfo = uploadInfo;
    [self initUploadFile];  //check file and get file size.
}

+(CMISUploadFileRequest*)cmisUploadRequestWithUploadInfo:(UploadInfo*) info
{
    CMISUploadFileRequest *newRequest = [[self alloc] init];
    [newRequest setUploadInfo:info];
    
    return newRequest;
}

#pragma mark -
#pragma mark File Operation
- (BOOL)initUploadFile
{
    _uploadFileHandle = fopen([[_uploadInfo.uploadFileURL path] cStringUsingEncoding:NSUTF8StringEncoding], "rb");
    if (_uploadFileHandle) {
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[_uploadInfo.uploadFileURL path] error:NULL];
        self.totalBytes = [attributes fileSize];
        return YES;
    }
    
    self.uploadFileAsset = [AssetUploadItem assetFromURL:_uploadInfo.uploadFileURL];
    if (self.uploadFileAsset) {
        self.totalBytes = [[self.uploadFileAsset defaultRepresentation] size];
        return YES;
    }
    
    return NO;
}

- (BOOL)isFileExists
{
    return (_uploadFileHandle || self.uploadFileAsset);
}

- (NSMutableData*) readDataFromFile:(NSInteger) offset length:(NSInteger) length
{
    NSMutableData *data = [NSMutableData data];
    NSInteger readLen = 0;
    if (_uploadFileHandle) {
        fseek(_uploadFileHandle, 0, offset);
        readLen = fread(readBuffer, 1, length, _uploadFileHandle);
    }
    
    if (self.uploadFileAsset) {
        readLen = [[self.uploadFileAsset defaultRepresentation] getBytes:readBuffer fromOffset:offset length:length error:nil];
        
    }
    
    if (readLen > 0)
        data = [NSData dataWithBytesNoCopy:readBuffer length:readLen freeWhenDone:NO];
    
    return data;
}

#pragma mark -
#pragma mark Upload Helpers

- (BOOL) createFileOnServer   //create empty file on server.
{
    CMISUploadFileHTTPRequest *createFileRequest = [CMISUploadFileHTTPRequest cmisUploadRequestWithUploadInfo:_uploadInfo];
    [createFileRequest setRequestMethod:@"POST"];
    [createFileRequest setPromptPasswordDelegate:self];
    [createFileRequest setSuppressAccountStatusUpdateOnError:YES];
    [_uploadInfo setUploadStatus:UploadInfoStatusActive];
    
    [createFileRequest startSynchronous];
    NSError *error = [createFileRequest error];
    
    if (error == nil && [createFileRequest responseStatusCode] == 201) {  //create successful
        RepositoryItemParser *itemParser = [[RepositoryItemParser alloc] initWithData:[createFileRequest responseData]];
        _uploadInfo.repositoryItem = [itemParser parse];
        [_uploadInfo setCmisObjectId:_uploadInfo.repositoryItem.guid];
        [_uploadInfo setRepositoryItem:_uploadInfo.repositoryItem];
        
        return YES;
    }
    
    return NO;
}

- (BOOL) updateRepositoryItemInfo   //update change token for uploading file
{
    ObjectByIdRequest *objRequest = [ObjectByIdRequest defaultObjectById:_uploadInfo.repositoryItem.guid accountUUID:_uploadInfo.selectedAccountUUID tenantID:_uploadInfo.tenantID];
    [objRequest startSynchronous];
    NSError *error = [objRequest error];
    if (error == nil && [objRequest responseStatusCode] == 200) {
        _uploadInfo.repositoryItem = [objRequest repositoryItem];
        AlfrescoLogDebug(@"uploaded file size:%@",[_uploadInfo.repositoryItem.metadata objectForKey:@"cmis:contentStreamLength"]);
        self.sentBytes = [[_uploadInfo.repositoryItem.metadata objectForKey:@"cmis:contentStreamLength"] longLongValue];
        
        return YES;
    }
    return NO;
}

- (BOOL) appendChunkData:(NSMutableData*) contentData dataLength:(uint64_t) dataLength isLastChunk:(BOOL)isLastChunk
{
    @autoreleasepool {
        CMISAppendContentHTTPRequest *appendRequest = [CMISAppendContentHTTPRequest cmisAppendRequestWithUploadInfo:_uploadInfo contentData:contentData isLastChunk:isLastChunk];
        [appendRequest setUploadProgressDelegate:self];
        [appendRequest startSynchronous];
        
        NSError *error = [appendRequest error];
        if (error == nil && [appendRequest responseStatusCode] == 201) {  //put data successfully
            AlfrescoLogDebug(@"upload size:%llu  total:%llu",self.sentBytes, self.totalBytes);
            
            return YES;
        }
        
        AlfrescoLogDebug(@"appendChunkData:%@", [NSString stringWithUTF8String:[[appendRequest responseData] bytes]]);
    }
    
    return NO;
}

- (BOOL) uplaodWholeFile
{
    while (self.sentBytes != self.totalBytes) {
        uint64_t leftBytes = self.totalBytes - self.sentBytes;
        
        NSInteger readLength = (leftBytes >= APPEND_CHUNK_DATA_SIZE)?APPEND_CHUNK_DATA_SIZE:leftBytes;
        AlfrescoLogDebug(@"leftBytes:%llu readLength:%d total:%llu",leftBytes, readLength, self.totalBytes);
        NSMutableData *data = [self readDataFromFile:self.sentBytes length:readLength];
        if (!data) {
            return NO;
        }
        
        if (![self appendChunkData:data dataLength:readLength isLastChunk:(self.sentBytes + readLength == self.totalBytes)]) {
            return NO;
        }
        
        if (![self updateRepositoryItemInfo]) {
            return NO;
        }
        
        if (_isCancelled) {   //cancel upload request
            return NO;
        }
    }
    
    return YES;
}

#pragma mark -
#pragma mark ASIHttpRequest Delegate
- (void)request:(ASIHTTPRequest *)request didSendBytes:(long long)bytes
{
    self.sentBytes += bytes;
    unsigned long long value = bytes;
    id uploadQueue = _queue;
    
    [ASIHTTPRequest performSelector:@selector(request:didSendBytes:) onTarget:&uploadQueue withObject:self amount:&value callerToRetain:self];
	
    id uploadIndicatorDelegate = _uploadProgressDelegate;
    [ASIHTTPRequest updateProgressIndicator:&uploadIndicatorDelegate withProgress:self.sentBytes ofTotal:self.totalBytes];
}

#pragma mark -
#pragma mark Delegate Handler

- (void) uploadStart
{
    if (_delegate && [_delegate respondsToSelector:@selector(uploadStarted:)]) {
		[_delegate performSelector:@selector(uploadStarted:) withObject:_uploadInfo];
	}
    
    if (_queue && [_queue respondsToSelector:@selector(uploadStarted:)]) {
		[_queue performSelector:@selector(uploadStarted:) withObject:self];
	}
}

- (void) uploadFailed
{
    if (_delegate && [_delegate respondsToSelector:@selector(uploadFailed:)]) {
		[_delegate performSelector:@selector(uploadFailed:) withObject:_uploadInfo];
	}
    
    if (_queue && [_queue respondsToSelector:@selector(uploadFailed:)]) {
		[_queue performSelector:@selector(uploadFailed:) withObject:self];
	}
}

- (void) uploadFinish
{
    if (_delegate && [_delegate respondsToSelector:@selector(uploadFinished:)]) {
		[_delegate performSelector:@selector(uploadFinished:) withObject:_uploadInfo];
	}
    
    if (_queue && [_queue respondsToSelector:@selector(uploadFinished:)]) {
		[_queue performSelector:@selector(uploadFinished:) withObject:self];
	}
}

#pragma mark -
#pragma mark Main Thread

- (void)clearDelegatesAndCancel
{
	[[self cancelledLock] lock];
    
	// Clear delegates
	[self setDelegate:nil];
	[self setQueue:nil];
	[self setUploadProgressDelegate:nil];
    _isCancelled = YES;
    
	[[self cancelledLock] unlock];
	[self cancel];
}

- (void) main
{
    @autoreleasepool {
        @try {
            if (![self isFileExists]) {  //check the file url and init file handle, file size.
                [self uploadFailed];
                return;
            }
            
            if (_uploadInfo.repositoryItem.guid == nil || [_uploadInfo.repositoryItem.guid length] < 2) {  //create the file on serve if it's not exist.
                if (![self createFileOnServer]) {
                    [self uploadFailed];
                    return;
                }
            }else
            {
                if (![self updateRepositoryItemInfo]) {
                    [self uploadFailed];
                    return;
                }
            }
            [self uploadStart];
            
            if (![self uplaodWholeFile]) {
                [self uploadFailed];
                return;
            }
            
            [self uploadFinish];
        }
        @catch (NSException *exception) {
            AlfrescoLogDebug(@"Upload file request exception:%@", exception);
            [self uploadFailed];
        }
        @finally {
            
        }
    }
}
@end
