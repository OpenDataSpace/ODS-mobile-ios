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
#import "Utility.h"
#import "NSData+Base64.h"
#import "GTMNSString+XML.h"
#import "NSString+Utils.h"

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
NSString * const kUploadInfoSelectedAccountUUID = @"selectedAccountUUID";
NSString * const kUploadInfoTenantID = @"tenantID";

@implementation UploadInfo
@synthesize uuid = _uuid;
@synthesize uploadFileURL = _uploadFileURL;
@synthesize filename = _filename;
@synthesize extension = _extension;
@synthesize upLinkRelation = _upLinkRelation;
@synthesize cmisObjectId = _cmisObjectId;
@synthesize uploadDate = _uploadDate;
@synthesize tags = _tags;
@synthesize uploadStatus = _uploadStatus;
@synthesize uploadType = _uploadType;
@synthesize selectedAccountUUID = _selectedAccountUUID;
@synthesize tenantID = _tenantID;

- (void)dealloc
{
    [_uuid release];
    [_uploadFileURL release];
    [_filename release];
    [_extension release];
    [_upLinkRelation release];
    [_cmisObjectId release];
    [_uploadDate release];
    [_tags release];
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
        [self setUploadStatus:[[aDecoder decodeObjectForKey:kUploadInfoType] intValue]];
        [self setSelectedAccountUUID:[aDecoder decodeObjectForKey:kUploadInfoSelectedAccountUUID]];
        [self setTenantID:[aDecoder decodeObjectForKey:kUploadInfoTenantID]];

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
    [aCoder encodeObject:self.selectedAccountUUID forKey:kUploadInfoSelectedAccountUUID];
    [aCoder encodeObject:self.tenantID forKey:kUploadInfoTenantID];
}

- (NSString *)postBody
{
    NSString *filename = [self completeFileName];
    NSString *mimeType = mimeTypeForFilename(filename);
    NSURL *fileURL = self.uploadFileURL;
    NSError *error = nil;
    NSData *uploadData = [NSData dataWithContentsOfURL:fileURL options:NSDataReadingMappedIfSafe error:&error];
    
    return [NSString stringWithFormat:@""
     "<?xml version=\"1.0\" ?>"
     "<entry xmlns=\"http://www.w3.org/2005/Atom\" xmlns:app=\"http://www.w3.org/2007/app\" xmlns:cmisra=\"http://docs.oasis-open.org/ns/cmis/restatom/200908/\">"
     "<cmisra:content>"
     "<cmisra:mediatype>%@</cmisra:mediatype>"
     "<cmisra:base64>%@</cmisra:base64>"
     "</cmisra:content>"
     "<cmisra:object xmlns:cmis=\"http://docs.oasis-open.org/ns/cmis/core/200908/\">"
     "<cmis:properties>"
     "<cmis:propertyId propertyDefinitionId=\"cmis:objectTypeId\"><cmis:value>cmis:document</cmis:value></cmis:propertyId>"
     "</cmis:properties>"
     "</cmisra:object>"
     "<title>%@</title>"
     "</entry>",
     mimeType,
     [uploadData base64EncodedString],
     [filename gtm_stringBySanitizingAndEscapingForXML]
     ];
    
}
- (NSURL *)uploadURL
{
    return [NSURL URLWithString:[self.upLinkRelation stringByAppendingFormat:@"?versionState=major"]];
}

- (NSString *)completeFileName
{
    return [self.filename stringByAppendingPathExtension:self.extension];
}

- (NSString *)extension
{
    if(!_extension)
    {
        [self setExtension:[[self.uploadFileURL pathExtension] lowercaseString]];
    }
    return _extension;
}

#pragma mark -
#pragma mark K-V Compliance

- (id)valueForUndefinedKey:(NSString *)key
{
    return nil;
}

@end
