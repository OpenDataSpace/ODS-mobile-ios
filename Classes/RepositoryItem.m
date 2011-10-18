//
//  RepositoryItem.m
//  Alfresco
//
//  Created by Michael Muller on 10/21/09.
//  Copyright 2009 Michael J Muller. All rights reserved.
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
@synthesize canCreateDocument;
@synthesize canCreateFolder;
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
	[metadata release];
	[describedByURL release];
	[selfURL release];
	[linkRelations release];
	
	[super dealloc];
}

- (id) init
{
	self = [super init];
	if (self != nil) {
        canCreateDocument = NO;
        canCreateFolder = NO;
		[self setLastModifiedBy:[NSString string]];
		[self setLinkRelations:[NSMutableArray array]];
	}
	return self;
}


- (BOOL) isFolder {
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

#pragma mark - 
#pragma mark NSKeyValueCoding Protocol Methods

- (id)valueForUndefinedKey:(NSString *)key
{
    NSLog(@"Undefined Key: %@", key);
    return nil;
}

@end
