//
//  #import "NSString+Trimming.h"
//  FreshDocs
//
//  Created by Michael Muller on 4/30/10.
//  Copyright 2010 Michael J Muller. All rights reserved.
//  Copyright 2011 Zia Consulting, Inc.. All rights reserved.
//

#import "NSString+Trimming.h"

@implementation NSString (Trimming)

- (NSString *)stringWithTrailingSlashRemoved
{
	if ([self hasSuffix:@"/"]) {
		return [self substringToIndex:([self length]-1)];
	}
	else {
		return self;
	}
}

- (NSString *)trimWhiteSpace
{
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

@end
