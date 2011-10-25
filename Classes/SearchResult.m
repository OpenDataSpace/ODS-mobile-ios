//
//  ***** BEGIN LICENSE BLOCK *****
//  Version: MPL 1.1
//
//  The contents of this file are subject to the Mozilla Public License Version
//  1.1 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS" basis,
//  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
//  for the specific language governing rights and limitations under the
//  License.
//
//  The Original Code is the Alfresco Mobile App.
//  The Initial Developer of the Original Code is Zia Consulting, Inc.
//  Portions created by the Initial Developer are Copyright (C) 2011
//  the Initial Developer. All Rights Reserved.
//
//
//  ***** END LICENSE BLOCK *****
//
//
//  SearchResult.m
//

#import "SearchResult.h"

@implementation SearchResult
@synthesize cmisObjectId;
@synthesize title;
@synthesize contentStreamFileName;
@synthesize relevance;
@synthesize contentLocation;
@synthesize lastModifiedDateStr;
@synthesize contentStreamLength;
@synthesize contentStreamMimeType;
@synthesize contentAuthor;
@synthesize updated;

- (void) dealloc {
    [cmisObjectId release];
	[title release];
	[contentStreamFileName release];
	[relevance release];
	[contentLocation release];
    [lastModifiedDateStr release];
    [contentStreamLength release];
    [contentStreamMimeType release];
    [contentAuthor release];
    [updated release];
    
	[super dealloc];
}

#pragma mark -
#pragma mark KeyValuePairProtocol Delegate Method
- (id)valueForUndefinedKey:(NSString *)key
{
    NSLog(@"Key '%@' is not defined", key);
    return nil;
}

@end
