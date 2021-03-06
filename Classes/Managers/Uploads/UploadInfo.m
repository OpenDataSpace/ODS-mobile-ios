/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Alfresco Mobile App.
 *
 * The Initial Developer of the Original Code is Zia Consulting, Inc.
 * Portions created by the Initial Developer are Copyright (C) 2011-2012
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  UploadInfo.m
//

#import "UploadInfo.h"
#import "AssetUploadItem.h"
#import "RepositoryItem.h"
#import "CMISUploadFileRequest.h"
#import "FileUtils.h"

NSString * const kUploadInfoUUID = @"uuid";
NSString * const kUploadInfoFileURL = @"uploadFileURL";
NSString * const kUploadInfoFilename = @"filename";
NSString * const kUploadInfoExtension = @"extension";
NSString * const kUploadInfoUpLinkRelation = @"upLinkRelation";
NSString * const kUploadInfoCmisObjectId = @"cmisObjectId";
NSString * const kUploadInfoDate = @"uploadDate";
NSString * const kUploadInfoTags = @"tags";
NSString * const kUploadInfoStatus = @"uploadStatus";
NSString * const kUploadInfoType = @"uploadType";
NSString * const kUploadInfoError = @"error";
NSString * const kUploadInfoFolderName = @"folderName";
NSString * const kUploadInfoSelectedAccountUUID = @"selectedAccountUUID";
NSString * const kUploadInfoTenantID = @"tenantID";
NSString * const kUploadInfoUploadFileIsTemporary = @"uploadFileIsTemporary";

@implementation UploadInfo
@synthesize uuid = _uuid;
@synthesize uploadFileURL = _uploadFileURL;
@synthesize filename = _filename;
@synthesize extension = _extension;
@synthesize upLinkRelation = _upLinkRelation;
@synthesize cmisObjectId = _cmisObjectId;
@synthesize repositoryItem = _repositoryItem;
@synthesize temporaryRrepositoryItem = _temporaryRrepositoryItem;
@synthesize uploadDate = _uploadDate;
@synthesize tags = _tags;
@synthesize uploadStatus = _uploadStatus;
@synthesize uploadType = _uploadType;
@synthesize uploadRequest = _uploadRequest;
@synthesize error = _error;
@synthesize folderName = _folderName;
@synthesize selectedAccountUUID = _selectedAccountUUID;
@synthesize tenantID = _tenantID;
@synthesize uploadFileIsTemporary = _uploadFileIsTemporary;

- (void)dealloc
{
    [self removeTemporaryUploadFile];
    [_uuid release];
    [_uploadFileURL release];
    [_filename release];
    [_extension release];
    [_upLinkRelation release];
    [_cmisObjectId release];
    [_repositoryItem release];
    [_temporaryRrepositoryItem release];
    [_uploadDate release];
    [_tags release];
    [_uploadRequest release];
    [_error release];
    [_folderName release];
    [_selectedAccountUUID release];
    [_tenantID release];
    [super dealloc];
}

#pragma mark -
#pragma mark NSCoding
- (id)init 
{
    // TODO static NSString objects
    
    self = [super init];
    if(self) {
        [self setUuid:[NSString generateUUID]];
        [self setUploadDate:[NSDate date]];
        [self setUploadStatus:UploadInfoStatusInactive];
        [self setUploadFileIsTemporary:NO];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) 
    {
        [self setUuid:[aDecoder decodeObjectForKey:kUploadInfoUUID]];
        if (nil == _uuid) {
            // We Should never get here.
            [self setUuid:[NSString generateUUID]];
        }
        
        [self setUploadFileURL:[aDecoder decodeObjectForKey:kUploadInfoFileURL]];
        [self setFilename:[aDecoder decodeObjectForKey:kUploadInfoFilename]];
        [self setExtension:[aDecoder decodeObjectForKey:kUploadInfoExtension]];
        [self setUpLinkRelation:[aDecoder decodeObjectForKey:kUploadInfoUpLinkRelation]];
        [self setCmisObjectId:[aDecoder decodeObjectForKey:kUploadInfoCmisObjectId]];
        [self setUploadDate:[aDecoder decodeObjectForKey:kUploadInfoDate]];
        [self setTags:[aDecoder decodeObjectForKey:kUploadInfoTags]];
        [self setUploadStatus:[[aDecoder decodeObjectForKey:kUploadInfoStatus] intValue]];
        [self setUploadType:[[aDecoder decodeObjectForKey:kUploadInfoType] intValue]];
        [self setError:[aDecoder decodeObjectForKey:kUploadInfoError]];
        [self setFolderName:[aDecoder decodeObjectForKey:kUploadInfoFolderName]];
        [self setSelectedAccountUUID:[aDecoder decodeObjectForKey:kUploadInfoSelectedAccountUUID]];
        [self setTenantID:[aDecoder decodeObjectForKey:kUploadInfoTenantID]];
        [self setUploadFileIsTemporary:[aDecoder decodeBoolForKey:kUploadInfoUploadFileIsTemporary]];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.uuid forKey:kUploadInfoUUID];
    [aCoder encodeObject:self.uploadFileURL forKey:kUploadInfoFileURL];
    [aCoder encodeObject:self.filename forKey:kUploadInfoFilename];
    [aCoder encodeObject:self.extension forKey:kUploadInfoExtension];
    [aCoder encodeObject:self.upLinkRelation forKey:kUploadInfoUpLinkRelation];
    [aCoder encodeObject:self.cmisObjectId forKey:kUploadInfoCmisObjectId];
    [aCoder encodeObject:self.uploadDate forKey:kUploadInfoDate];
    [aCoder encodeObject:self.tags forKey:kUploadInfoTags];
    [aCoder encodeObject:[NSNumber numberWithInt:self.uploadStatus] forKey:kUploadInfoStatus];
    [aCoder encodeObject:[NSNumber numberWithInt:self.uploadType] forKey:kUploadInfoType];
    [aCoder encodeObject:self.error forKey:kUploadInfoError];
    [aCoder encodeObject:self.folderName forKey:kUploadInfoFolderName];
    [aCoder encodeObject:self.selectedAccountUUID forKey:kUploadInfoSelectedAccountUUID];
    [aCoder encodeObject:self.tenantID forKey:kUploadInfoTenantID];
    [aCoder encodeBool:self.uploadFileIsTemporary forKey:kUploadInfoUploadFileIsTemporary];
}

- (NSURL *)uploadURL
{
    return [NSURL URLWithString:self.upLinkRelation];
}

- (NSString *)completeFileName
{
    if (self.extension == nil || [self.extension isEqualToString:@""])
    {
        return self.filename;
    }

    return [self.filename stringByAppendingPathExtension:self.extension];
}

- (id<UploadHelper>)uploadHelper
{
    if(self.uploadType == UploadFormTypePhoto)
    {
        AssetUploadItem *helper = [[[AssetUploadItem alloc] init] autorelease];
        [helper setTempImagePath:[self.uploadFileURL path]];
        return helper;
    }
    
    return nil;
}

- (void)setFilenameWithDate:(NSDate *)date andExistingDocuments:(NSArray *)existingDocuments
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH.mm.ss"];
    NSString *timestamp = [dateFormatter stringFromDate:date];
    [dateFormatter release];
    
    NSString *mediaType = [self typeDescriptionWithPlural:NO];
    
    NSString *newName = [NSString stringWithFormat:@"%@ %@", mediaType, timestamp];
    [self setFilename:newName];
    
    newName = [FileUtils nextFilename:[self completeFileName] inNodeWithDocumentNames:existingDocuments];
    if(![newName isEqualToCaseInsensitiveString:[self completeFileName]])
    {
        [self setFilename:[newName stringByDeletingPathExtension]];
    }

}

- (NSString *)typeDescriptionWithPlural:(BOOL)plural
{
    return [UploadInfo typeDescription:self.uploadType plural:plural];
}

+ (NSString *)typeDescription:(UploadFormType)type plural:(BOOL)plural
{
    NSString *typeDescription = nil;
    switch (type) {
        case UploadFormTypeAudio:
            typeDescription = plural? NSLocalizedString(@"Audios", @"Audios") : NSLocalizedString(@"Audio", @"Audio");
            break;
        case UploadFormTypePhoto:
            typeDescription = plural? NSLocalizedString(@"Photos", @"Photos") : NSLocalizedString(@"Photo", @"Photo");
            break;
        case UploadFormTypeVideo:
            typeDescription = plural? NSLocalizedString(@"Videos", @"Videos") : NSLocalizedString(@"Video", @"Video");
            break;
        default:
            typeDescription = plural? NSLocalizedString(@"Documents", @"Documents") : NSLocalizedString(@"Document", @"Document");
            break;
    }
    return typeDescription;
}

- (NSString *)extension
{
    if(!_extension)
    {
        [self setExtension:[[self.uploadFileURL pathExtension] lowercaseString]];
    }
    return _extension;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"UploadInfo: Status: %d", self.uploadStatus];
}

- (void)setUploadStatus:(UploadInfoStatus)uploadStatus
{
    _uploadStatus = uploadStatus;
    if (uploadStatus == UploadInfoStatusUploaded)
    {
        [self removeTemporaryUploadFile];
    }
}

- (void)removeTemporaryUploadFile
{
    // Clear out any temporary file, as these can build up quickly and cause iOS free space warnings
    if (_uploadFileIsTemporary)
    {
        NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
        NSString *filePath = [_uploadFileURL path];
        if ([fileManager fileExistsAtPath:filePath])
        {
            AlfrescoLogDebug(@"UploadInfo: removing temp file %@", filePath);
            [fileManager removeItemAtPath:filePath error:nil];
        }
    }
}

#pragma mark - K-V Compliance

- (id)valueForUndefinedKey:(NSString *)key
{
    return nil;
}

#pragma mark -  check source upload file

- (BOOL) sourceFileExists {
    if (!self.uploadFileURL) {
        return NO;
    }
    
    NSString *urlStr = [self.uploadFileURL absoluteString];
    if ([urlStr hasPrefix:@"assets-library://"] && [AssetUploadItem assetFromURL:self.uploadFileURL]) {
        return YES;
    }
    
    NSString *uploadPath = [self.uploadFileURL path];
    if (uploadPath && [[NSFileManager defaultManager] fileExistsAtPath:uploadPath]) {
        return YES;
    }
    
    return NO;
}
@end
