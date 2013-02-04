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

- (void) dealloc
{
	[_identLink release];
	[_title release];
	[_guid release];
	[_fileType release];
	[_lastModifiedBy release];
	[_lastModifiedDate release];
	[_contentLocation release];
	[_contentStreamLengthString release];
    [_versionSeriesId release];
	[_metadata release];
	[_describedByURL release];
	[_selfURL release];
	[_linkRelations release];
    [_node release];
    [_aspects release];
	
	[super dealloc];
}

- (id)init
{
	self = [super init];
	if (self)
    {
        _canCreateDocument = NO;
        _canCreateFolder = NO;
        _canDeleteObject = NO;
		[self setLastModifiedBy:[NSString string]];
		[self setLinkRelations:[NSMutableArray array]];
	}
	return self;
}

- (id)initWithDictionary:(NSDictionary*)downloadInfo
{
    self = [self init];
    
    self.title = [downloadInfo objectForKey:@"filename"];
    self.guid = [downloadInfo objectForKey:@"objectId"];
    self.fileType = [downloadInfo objectForKey:@""];
    self.contentLocation = [downloadInfo objectForKey:@"contentLocation"];
    self.versionSeriesId = [downloadInfo objectForKey:@"versionSeriesId"];
    self.describedByURL = [downloadInfo objectForKey:@"describedByUrl"];
    self.selfURL = [downloadInfo objectForKey:@""];
    self.linkRelations = [downloadInfo objectForKey:@"linkRelations"];
    self.metadata = [downloadInfo objectForKey:@"metadata"];

    self.lastModifiedBy = [self.metadata objectForKey:@"cmis:lastModifiedBy"];
    self.lastModifiedDate = [self.metadata objectForKey:@"cmis:lastModificationDate"];
    self.contentStreamLengthString = [self.metadata objectForKey:@"cmis:contentStreamLength"];
    
    self.aspects = [downloadInfo objectForKey:@"aspects"];
    
    return self;
}

- (BOOL)isFolder
{
	return [self.fileType isEqualToString:@"folder"] || [self.fileType isEqualToString:@"cmis:folder"];
}

- (NSComparisonResult)compareTitles:(id)other
{
	return [self.title compare:[other title] options:NSCaseInsensitiveSearch];
}

- (NSNumber *)contentStreamLength
{
	if (nil == self.contentStreamLengthString)
    {
		return [NSNumber numberWithInt:0];
	}

    double val = [self.contentStreamLengthString doubleValue];
    if (0.0 == val)
    {
        return [NSNumber numberWithInt:0];
    }

    return [NSNumber numberWithLong:(long)val];
}

- (NSString *)contentStreamMimeType
{
    return [self.metadata objectForKey:@"cmis:contentStreamMimeType"];
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

#pragma mark - NSKeyValueCoding Protocol Methods

- (id)valueForUndefinedKey:(NSString *)key
{
    NSLog(@"Undefined Key: %@", key);
    return nil;
}

@end
