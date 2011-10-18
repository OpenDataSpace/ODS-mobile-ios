//
//  NSDictionary+URLEncoding.m
//  FreshDocs
//
//  Created by Gi Hyun Lee on 10/14/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

#import "NSDictionary+URLEncoding.h"


@implementation NSDictionary (URLEncoding)

- (NSString *)urlEncodedParameterString
{
	if ((self == nil) || ([self count] == 0)) {
		return nil;
	}
	
	NSMutableArray *parts = [NSMutableArray array];
	for (NSString *key in self) {
		NSString *value = [self objectForKey:key];
		if (value && ([value length] > 0)) {
			[parts addObject:[NSString stringWithFormat:@"%@=%@", 
							  [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], 
							  [value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
		}
	}
	
	return [parts componentsJoinedByString:@"&"];
}

@end
