//
//  NSURL+HTTPURLUtils.m
//  FreshDocs
//
//  Created by Gi Hyun Lee on 10/14/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

#import "NSURL+HTTPURLUtils.h"
#import "NSDictionary+URLEncoding.h"

@implementation NSURL (HTTPURLUtils)

- (NSURL *)URLByAppendingParameterString:(NSString *)otherParameterString
{
	NSLog(@"NSURL absoluteString: %@", [self absoluteString]);
	NSLog(@"NSURL parameterString: %@", [self parameterString]);

	
	if (otherParameterString) {
		NSString *urlString = ( ([self parameterString] || [self query])
							    ? [[self absoluteString] stringByAppendingFormat:@"&%@", otherParameterString]
							    : [[self absoluteString] stringByAppendingFormat:@"?%@", otherParameterString] );
		return [NSURL URLWithString:urlString];
	}
	else {
		return self;
	}
}

- (NSURL *)URLByAppendingParameterDictionary:(NSDictionary *)parameterdictionary
{
	return [self URLByAppendingParameterString:[parameterdictionary urlEncodedParameterString]];
}

@end
