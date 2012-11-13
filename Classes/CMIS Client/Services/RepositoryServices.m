/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Alfresco Mobile App.
 *
 * The Initial Developer of the Original Code is Zia Consulting, Inc.
 * Portions created by the Initial Developer are Copyright (C) 2011-2012
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  RepositoryServices.m
//
#import "RepositoryServices.h"

static void * volatile instanceObject;

NSString * const kAlfrescoRepositoryVendorName = @"Alfresco";
NSString * const kIBMRepositoryVendorName = @"IBM";
NSString * const kMicrosoftRepositoryVendorName = @"Microsoft Corporation";

@interface RepositoryServices ()
@property (atomic, readonly) NSMutableDictionary *repositories;
@end


@implementation RepositoryServices
@synthesize repositories = _repositories;

- (void)dealloc
{
	[_repositories release];
	[super dealloc];
}

- (id)init
{
	if ((self = [super init])) {
		_repositories = [[NSMutableDictionary dictionary] retain];
	}
	return self;
}


#pragma mark Load Data Methods

- (void)addTenantIDs:(NSArray *)tenatIDArray forAccountUUID:(NSString *)uuid andMigrateExisting:(BOOL)migrateExisiting
{
    NSMutableDictionary *reposByTenantIDDict = [[self repositories] objectForKey:uuid];
    NSMutableDictionary *updatedDict = [NSMutableDictionary dictionaryWithCapacity:[tenatIDArray count]];
    for (NSString *tenantID in tenatIDArray)
    {
        RepositoryInfo *info = nil;
        if (migrateExisiting)
            info = [reposByTenantIDDict objectForKey:tenantID];
        [updatedDict setObject:info forKey:tenantID];
    }
    
    [[self repositories] setObject:reposByTenantIDDict forKey:uuid];
}

- (void)addRepositoryInfo:(RepositoryInfo *)repositoryInfo forAccountUuid:(NSString *)uuid tenantID:(NSString *)tenantID
{
	if (uuid == nil) {
        NSLog(@"No uuid provided for the repositoryInfo");
		return;
	}
    if (!tenantID) {
        tenantID = kDefaultTenantID;
    }
    
    [repositoryInfo setAccountUuid:uuid];
    [repositoryInfo setTenantID:tenantID];
    [repositoryInfo setHasValidSession:YES];
    
    NSMutableDictionary *reposByTenantIDDict = [[self repositories] objectForKey:uuid];
    if (!reposByTenantIDDict) 
    {
        reposByTenantIDDict = [NSMutableDictionary dictionary];
        [[self repositories] setObject:reposByTenantIDDict forKey:uuid];
    }

	[reposByTenantIDDict setObject:repositoryInfo forKey:tenantID];
}

- (void)removeRepositoriesForAccountUuid:(NSString *)uuid
{
    [[self repositories] removeObjectForKey:uuid];
}

- (void)invalidateRepositoriesForAccountUuid:(NSString *)uuid
{
    for (RepositoryInfo *repositoryInfo in [[self.repositories objectForKey:uuid] allValues])
    {
        [repositoryInfo setHasValidSession:NO];
    }
}

- (void)unloadRepositories 
{
    [[self repositories] removeAllObjects];
}


#pragma mark Repository Services Methods

- (RepositoryInfo *)getRepositoryInfoByAccountUuid:(NSString *)uuid
{
    NSLog(@"REMOVE ME: getRepositoryInfoByAccountUuid");

    return [self getRepositoryInfoForAccountUUID:uuid tenantID:kDefaultTenantID];
}

- (NSArray *)getRepositoryInfoArrayForAccountUUID:(NSString *)uuid
{
    NSMutableDictionary *dict = [[[[self repositories] objectForKey:uuid] copy] autorelease];
    return [dict allValues];
}

- (RepositoryInfo *)getRepositoryInfoForAccountUUID:(NSString *)uuid tenantID:(NSString *)tenantID
{
    if (!tenantID) {
        tenantID = kDefaultTenantID;
    }
    return [[[self repositories] objectForKey:uuid] objectForKey:tenantID];
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

- (oneway void)release
{
    // Do nothing we're a Singleton
}

- (id)autorelease
{
	return self;
}

@end
