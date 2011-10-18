//
//  IFKeyValuePair.m
//  XpenserUtility
//
//  Created by Bindu Wavell on 1/10/10.
//  Copyright 2010 Zia Consulting, Inc.. All rights reserved.
//

#import "IFTitleSubtitlePair.h"

@implementation IFTitleSubtitlePair

@synthesize key, pairTitle, pairSubtitle;

- (void)dealloc {
	[key release];
	[pairTitle release];
	[pairSubtitle release];
	[super dealloc];
}


- (id)initWithTitle:(NSString *)newTitle andSubtitle:(NSString *)newSubtitle 
{
	self = [super init];
	if (self != nil)
	{		
		pairTitle    = [newTitle retain];
		pairSubtitle = [newSubtitle retain];
	}
	return self;
}

+ (IFTitleSubtitlePair *)titleSubtitlePairWithTitle:(NSString *)newTitle andSubtitle:(NSString *)newSubtitle 
{
	return [[[IFTitleSubtitlePair alloc] initWithTitle:newTitle andSubtitle:newSubtitle] autorelease];
}

@end
