//
//  IFKeyValuePair.m
//  XpenserUtility
//
//  Created by Bindu Wavell on 1/10/10.
//  Copyright 2010 Zia Consulting, Inc.. All rights reserved.
//

#import "IFLabelValuePair.h"

@implementation IFLabelValuePair

@synthesize pairLabel, pairValue;

- (void)dealloc {
	[pairLabel release];
	[pairValue release];
	[super dealloc];
}


- (id)initWithLabel:(NSString *)newLabel andValue:(NSString *)newValue {
	self = [super init];
	if (self != nil)
	{		
		pairLabel = [newLabel retain];
		pairValue = [newValue retain];
	}
	return self;
}

+ (IFLabelValuePair *)labelValuePairWithLabel:(NSString *)newLabel andValue:(NSString *)newValue {
	return [[[IFLabelValuePair alloc] initWithLabel:newLabel andValue:newValue] autorelease];
}

@end
