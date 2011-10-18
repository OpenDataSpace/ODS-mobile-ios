//
//  SearchResult.m
//  Alfresco
//
//  Created by Michael Muller on 10/23/09.
//  Copyright 2009 Michael J Muller. All rights reserved.
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
