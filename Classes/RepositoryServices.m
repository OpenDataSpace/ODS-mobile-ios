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
//  RepositoryServices.m
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
