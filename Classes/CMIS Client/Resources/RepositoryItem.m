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
//  RepositoryItem.m
//

#import "RepositoryItem.h"


@implementation RepositoryItem

@synthesize identLink;
@synthesize title;
@synthesize guid;
@synthesize fileType;
@synthesize lastModifiedBy;
@synthesize lastModifiedDate;
@synthesize contentLocation;
@synthesize contentStreamLengthString;
@synthesize versionSeriesId;
@synthesize canCreateDocument;
@synthesize canCreateFolder;
@synthesize canDeleteObject;
@synthesize metadata;
@synthesize describedByURL;
@synthesize selfURL;
@synthesize linkRelations;
@synthesize node;

- (void) dealloc {
	[identLink release];
	[title release];
	[guid release];
	[fileType release];
	[lastModifiedBy release];
	[lastModifiedDate release];
	[contentLocation release];
	[contentStreamLengthString release];
    [versionSeriesId release];
	[metadata release];
	[describedByURL release];
	[selfURL release];
	[linkRelations release];
	
	[super dealloc];
}

- (id)init
{
	self = [super init];
	if (self != nil) {
        canCreateDocument = NO;
        canCreateFolder = NO;
        canDeleteObject = NO;
		[self setLastModifiedBy:[NSString string]];
		[self setLinkRelations:[NSMutableArray array]];
	}
	return self;
}

-(id) initWithDictionary:(NSDictionary*)downloadInfo
{
    self = [self init];
    
    self.title = [downloadInfo objectForKey:@"filename"];
    self.guid = [downloadInfo objectForKey:@"objectId"];
    self.fileType = [downloadInfo objectForKey:@""];
    self.lastModifiedBy = [downloadInfo objectForKey:@""];
    self.lastModifiedDate = [[downloadInfo objectForKey:@"metadata"] objectForKey:@"cmis:lastModificationDate"];
    self.contentStreamLengthString = [downloadInfo objectForKey:@""];
    self.contentLocation = [downloadInfo objectForKey:@"contentLocation"];
    self.versionSeriesId = [downloadInfo objectForKey:@"versionSeriesId"];
    self.describedByURL = [downloadInfo objectForKey:@"describedByUrl"];
    self.selfURL = [downloadInfo objectForKey:@""];
    self.linkRelations = [downloadInfo objectForKey:@"linkRelations"];
    self.metadata = [downloadInfo objectForKey:@"metadata"];
    
    return self;
}

- (BOOL)isFolder {
	return [self.fileType isEqualToString:@"folder"] || [self.fileType isEqualToString:@"cmis:folder"];
}

- (NSComparisonResult) compareTitles:(id) other {
	return [title compare:[other title] options:NSCaseInsensitiveSearch];
}

- (NSNumber*) contentStreamLength {
	if (nil == contentStreamLengthString) {
		return [NSNumber numberWithInt:0];
	} else {
		double val = [contentStreamLengthString doubleValue];
		if (0.0 == val) {
			return [NSNumber numberWithInt:0];
		} else {
			NSNumber *retv = [NSNumber numberWithLong:(long)val];
			return retv;
		}			
	}		
}

- (NSString *)contentStreamMimeType {
    return [metadata objectForKey:@"cmis:contentStreamMimeType"];
}

- (NSString *)deleteURL
{
    NSString *url = [self selfURL];
    if ([self isFolder])
    {
        url = [NSString stringByAppendingString:@"/tree" toString:url];
    }
    return url;
}

#pragma mark - 
#pragma mark NSKeyValueCoding Protocol Methods

- (id)valueForUndefinedKey:(NSString *)key
{
    NSLog(@"Undefined Key: %@", key);
    return nil;
}

@end
