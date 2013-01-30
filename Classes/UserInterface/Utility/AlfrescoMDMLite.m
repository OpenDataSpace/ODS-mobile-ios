//
//  AlfrescoMDMLite.m
//  FreshDocs
//
//  Created by Mohamad Saeedi on 18/12/2012.
//
//

#import "AlfrescoMDMLite.h"
#import "FileDownloadManager.h"
#import "FavoriteFileDownloadManager.h"
#import "AccountManager.h"
#import "SessionKeychainManager.h"

@interface AlfrescoMDMLite ()
@property (atomic, readonly) NSMutableDictionary *repoItemsForAccounts;
@property (atomic, retain) NSString * currentAccoutnUUID;
@end

@implementation AlfrescoMDMLite

@synthesize requestQueue = _requestQueue;
@synthesize repoItemsForAccounts = _repoItemsForAccounts;
@synthesize delegate = _delegate;
@synthesize serviceDelegate = _serviceDelegate;

@synthesize currentAccoutnUUID = currentAccoutnUUID;

- (BOOL)isRestrictedDownload:(NSString*)fileName
{
    return [[FileDownloadManager sharedInstance] isFileRestricted:fileName];
}

- (BOOL)isRestrictedSync:(NSString*) fileName
{
    return [[FavoriteFileDownloadManager sharedInstance] isFileRestricted:fileName];
}

- (BOOL)isDownloadExpired:(NSString*)fileName withAccountUUID:(NSString*)accountUUID
{
    AccountInfo * accountInfo = [[AccountManager sharedManager] accountInfoForUUID:accountUUID];
    BOOL auth = [accountInfo password] != nil && ![[accountInfo password] isEqualToString:@""];

    return ([self isRestrictedDownload:fileName] && [[FileDownloadManager sharedInstance] isFileExpired:fileName] && !auth);
}
 
- (BOOL)isSyncExpired:(NSString*)fileName withAccountUUID:(NSString*)accountUUID
{
    AccountInfo * accountInfo = [[AccountManager sharedManager] accountInfoForUUID:accountUUID];
    BOOL auth = [accountInfo password] != nil && ![[accountInfo password] isEqualToString:@""];
    
    return ([self isRestrictedSync:fileName] && [[FavoriteFileDownloadManager sharedInstance] isFileExpired:fileName] && !auth);
}

#pragma mark - Load MDM Info

- (void)loadMDMInfo:(NSArray*)nodes withAccountUUID:(NSString*)accountUUID andTenantId:(NSString*)tenantID
{
    if(!self.requestQueue)
    {
        [self setRequestQueue:[ASINetworkQueue queue]];
    }
    
    if ([nodes count] > 0)
    {
        [self.repoItemsForAccounts setValue:nodes forKey:accountUUID];
        NSString *pattern = [NSString stringWithFormat:@"(d.cmis:objectId='%@')", [[nodes valueForKey:@"guid"] componentsJoinedByString:@"' OR d.cmis:objectId='"]];
        
        CMISMDMRequest *down = [[[CMISMDMRequest alloc] initWithSearchPattern:pattern
                                                               folderObjectId:nil
                                                                  accountUUID:accountUUID
                                                                     tenantID:tenantID] autorelease];
        
        [self.requestQueue addOperation:down];
    }
    
    if ([self.requestQueue requestsCount] > 0)
    {
        [self.requestQueue setDelegate:self];
        [self.requestQueue setShowAccurateProgress:NO];
        [self.requestQueue setShouldCancelAllRequestsOnFailure:NO];
        [self.requestQueue setRequestDidFailSelector:@selector(requestFailed:)];
        [self.requestQueue setRequestDidFinishSelector:@selector(requestFinished:)];
        [self.requestQueue setQueueDidFinishSelector:@selector(queueFinished:)];
        [self.requestQueue go];
    }
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    NSArray *searchedDocuments = [(CMISQueryHTTPRequest *)request results];
    NSString *accountUUID = [(CMISQueryHTTPRequest *)request accountUUID];
    
    NSArray *favNodes = [self.repoItemsForAccounts objectForKey:accountUUID];
    
    for (RepositoryItem *repoItem in searchedDocuments)
    {
        for (RepositoryItem *rItem in favNodes) {
            
            if([repoItem.guid isEqualToString:rItem.guid])
            {
                [rItem.aspects setValue:@"P:mdm:restrictedAspect" forKey:@"P:mdm:restrictedAspect"];
                [rItem.metadata setValue:[repoItem.metadata objectForKey:@"mdm:offlineExpiresAfter"] forKey:@"mdm:offlineExpiresAfter"];
                break;
            }
        }
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(mdmLiteRequestFinished:forItems:)])
    {
        [self.delegate mdmLiteRequestFinished:self forItems:favNodes];
    }
    
    [self.repoItemsForAccounts removeObjectForKey:accountUUID];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSLog(@"Error: %@ ", [request.error description]);
}

- (void)queueFinished:(ASINetworkQueue *)queue
{
    
}

#pragma mark - Load CMISServiceManager

- (void)loadRepositoryInfoForAccount:(NSString*)accountUUID
{
    if(!self.currentAccoutnUUID)
    {
        self.currentAccoutnUUID = accountUUID;
        
        [[CMISServiceManager sharedManager] addQueueListener:self];
        
        if (![[CMISServiceManager sharedManager] isActive])
        {
            [[CMISServiceManager sharedManager] loadServiceDocumentForAccountUuid:accountUUID]; // loadAllServiceDocuments];
        }
    }
}

#pragma mark - CMISServiceManagerService

- (void)serviceManagerRequestsFinished:(CMISServiceManager *)serviceManager
{
    [[CMISServiceManager sharedManager] removeQueueListener:self];
    
    SessionKeychainManager *keychainManager = [SessionKeychainManager sharedManager];
    AccountInfo * accountInfo = [[AccountManager sharedManager] accountInfoForUUID:self.currentAccoutnUUID];
    BOOL auth = ([[accountInfo password] length] != 0) || ([keychainManager passwordForAccountUUID:self.currentAccoutnUUID] != 0);
    
    self.currentAccoutnUUID = nil;
    
    if (self.serviceDelegate && [self.serviceDelegate respondsToSelector:@selector(mdmServiceManagerRequestFinsished:withSuccess:)])
    {
        [self.serviceDelegate mdmServiceManagerRequestFinsished:self withSuccess:auth];
    }
}

#pragma mark - Singleton methods

+ (AlfrescoMDMLite *)sharedInstance
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

- (id)init
{
    if (self = [super init])
    {
        _repoItemsForAccounts = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_requestQueue cancelAllOperations];
    [_requestQueue release];
    [_repoItemsForAccounts release];
    
    [super dealloc];
}

@end
