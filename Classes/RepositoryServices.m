//
//  RepositoryServices.m
//  FreshDocs
//
//  Created by Gi Hyun Lee on 9/15/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
//
#import "RepositoryServices.h"

static void * volatile instanceObject;

NSString * const kAlfrescoRepositoryVendorName = @"Alfresco";
NSString * const kIBMRepositoryVendorName = @"IBM";
NSString * const kMicrosoftVendorName = @"Microsoft Corporation";

@implementation RepositoryServices
@synthesize currentRepositoryInfo;

- (void)dealloc
{
	[repositories release];
	[currentRepositoryInfo release];
	[super dealloc];
}

- (id)init
{
	if ((self = [super init])) {
		repositories = [[NSMutableDictionary dictionary] retain];
	}
	return self;
}


#pragma mark Custom Getter Methods
- (NSArray *)repositories
{
	return [repositories allValues];
}


#pragma mark Load Data Methods
- (void)addRepositoryInfo:(RepositoryInfo *)repositoryInfo forRepositoryId:(NSString *)repositoryId
{
	if (repositoryId == nil) {
		repositoryId = @"repo";
	}
	[repositories setObject:repositoryInfo forKey:repositoryId];
	if ([repositories count] == 1) {
		[self setCurrentRepositoryInfo:repositoryInfo];
	}
}


#pragma mark Repository Services Methods
- (RepositoryInfo *)getRepositoryInfoByRepositoryId:(NSString *)repositoryId makeCurrent:(BOOL)makeCurrent
{
	RepositoryInfo *repoInfo = [repositories objectForKey:repositoryId];
	if (makeCurrent) {
		[self setCurrentRepositoryInfo:repoInfo];
	}
	
	return repoInfo;
}


#pragma mark Utility Methods
- (BOOL)isCurrentRepositoryVendorNameEqualTo:(NSString *)testVendorName
{
	return (([self currentRepositoryInfo] != nil) 
			? (NSOrderedSame == [[[self currentRepositoryInfo] vendorName] caseInsensitiveCompare:testVendorName]) 
			: NO);
}


#pragma mark -
#pragma mark Singleton Methods
+ (id)shared
{
	@synchronized(self) 
	{
		if (instanceObject == nil)
			instanceObject = [[RepositoryServices alloc] init];
	}	
	return instanceObject;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (instanceObject == nil) {
            instanceObject = [super allocWithZone:zone];
            return instanceObject;  // assignment and return on first allocation
        }
    }
    return nil; // on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
	return self;
}

- (NSUInteger)retainCount
{
	return NSUIntegerMax;
}

- (void)release
{
}

- (id)autorelease
{
	return self;
}

@end
