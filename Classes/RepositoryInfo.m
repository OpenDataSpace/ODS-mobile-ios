//
//  RepositoryInfo.m
//  FreshDocs
//
//  Created by Gi Hyun Lee on 9/27/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

#import "RepositoryInfo.h"

@implementation RepositoryInfo
@synthesize repositoryId;
@synthesize repositoryName;
@synthesize vendorName;

@synthesize rootFolderId;
@synthesize cmisVersionSupported;

@synthesize rootFolderHref;
@synthesize cmisQueryHref;

- (void)dealloc
{
	[repositoryId release];
	[repositoryName release];
	[rootFolderId release];
	[cmisVersionSupported release];
	[rootFolderHref release];
	[cmisQueryHref release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Overriden Key-Value Coding Methods
- (id)valueForUndefinedKey:(NSString *)key
{
	NSLog(@"RepositoryInfo ignoring key: '%@' in valueForUndefinedKey:", key);
	return [NSNull null];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
	NSLog(@"RepositoryInfo ignoring key: '%@' in setValue:forUndefinedKey:", key);	
}

#pragma mark -
#pragma mark Class Methods
- (BOOL)isPreReleaseCmis
{
	 NSDecimalNumber *cmisVersionDecimal = [NSDecimalNumber decimalNumberWithString:cmisVersionSupported];
	 double cmisVersionDouble = [cmisVersionDecimal doubleValue];
	 if (isnan(cmisVersionDouble)) {
		 cmisVersionDouble = 0.0;
	 }
	 
	 return (cmisVersionDouble < 1.0);
}

@end
