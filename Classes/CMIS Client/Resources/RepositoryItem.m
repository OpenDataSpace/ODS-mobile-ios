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
    [_renditions release];
	
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
        _canMoveObject = NO;
		[self setLastModifiedBy:[NSString string]];
		[self setLinkRelations:[NSMutableArray array]];
	}
	return self;
}

- (id)initWithDictionary:(NSDictionary *)downloadInfo
{
    self = [self init];
    
    self.title = downloadInfo[@"filename"];
    self.guid = downloadInfo[@"objectId"];
    self.fileType = downloadInfo[@""];
    self.contentLocation = downloadInfo[@"contentLocation"];
    self.versionSeriesId = downloadInfo[@"versionSeriesId"];
    self.describedByURL = downloadInfo[@"describedByUrl"];
    self.selfURL = downloadInfo[@""];
    self.linkRelations = downloadInfo[@"linkRelations"];
    self.metadata = downloadInfo[@"metadata"];
    self.aspects = downloadInfo[@"aspects"];
    self.canSetContentStream = [downloadInfo[@"canSetContentStream"] boolValue];

    self.lastModifiedBy = self.metadata[@"cmis:lastModifiedBy"];
    self.lastModifiedDate = self.metadata[@"cmis:lastModificationDate"];
    self.contentStreamLengthString = self.metadata[@"cmis:contentStreamLength"];
    
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
        url = [url stringByReplacingOccurrencesOfString:@"entry" withString:@"descendants"];
        url = [NSString stringByAppendingString:@"&allVersions=true&unfileObjects=delete&continueOnFailure=true" toString:url];//@"/tree"
    }
    return url;
}

- (NSURL*) thumbnailURL
{
    //NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(rel == %@) && (type == %@)"
                                              //  argumentArray:[NSArray arrayWithObjects:@"alternate", @"image/png", nil]];
   
   /* NSArray *result = [[self linkRelations] filteredArrayUsingPredicate:predicate];
    if ([result count] > 0) {
        return [NSURL URLWithString:[[result objectAtIndex:0] objectForKey:@"href"]];
    }*/
    
    NSMutableString *urlTemplateString = nil;
    
    for (NSDictionary *link in [self linkRelations]) {
        if (link && [link objectForKey:@"cmisra:renditionKind"]) {
            urlTemplateString = [NSMutableString stringWithString:[link objectForKey:@"href"]];
            break;
        }
    }
    
    NSDictionary *maxSizeRendition = nil;
    //find the most max thumbnail stream id.
    for (NSDictionary *rendition in [self renditions]) {
        if (rendition) {
            if (maxSizeRendition == nil) {
                maxSizeRendition = rendition;
            }else {
                float lastWidth = [[maxSizeRendition objectForKey:@"width"] floatValue];
                float lastHeight = [[maxSizeRendition objectForKey:@"height"] floatValue];
                float currentWidth = [[rendition objectForKey:@"width"] floatValue];
                float currentHeight = [[rendition objectForKey:@"height"] floatValue];
                if (lastWidth*lastHeight < currentWidth*currentHeight) {
                    maxSizeRendition = rendition;
                }
            }
        }
    }
    
    if (urlTemplateString && maxSizeRendition) { //replace streamId to be we need
        NSRange streamIdRange = [urlTemplateString rangeOfString:@"streamId"];
        NSString *urlString = [NSString stringWithFormat:@"%@streamId=%@", [urlTemplateString substringToIndex:streamIdRange.location], [maxSizeRendition objectForKey:@"streamId"]];
        return [NSURL URLWithString:urlString];
    }
    
    return nil;
}

#pragma mark - NSKeyValueCoding Protocol Methods

- (id)valueForUndefinedKey:(NSString *)key
{
    AlfrescoLogDebug(@"Undefined Key: %@", key);
    return nil;
}

@end
