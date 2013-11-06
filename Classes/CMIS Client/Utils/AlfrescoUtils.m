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
//  AlfrescoUtils.m
//

#import "AlfrescoUtils.h"
#import "AccountInfo.h"
#import "AccountManager.h"

static NSMutableDictionary *sharedInstances = nil;

@implementation AlfrescoUtils

- (void) dealloc {
    [accountUUID release];
	[super dealloc];
}

- (id)initWithAccountUUID:(NSString *)uuid {
    self = [super init];
    if(self) {
        accountUUID = [uuid copy];
    }
    return self;
}

- (NSString *)hostURL
{
    AccountInfo *accountInfo = [[AccountManager sharedManager] accountInfoForUUID:accountUUID];
	NSString *protocol = [accountInfo protocol];
	NSString *host = [accountInfo hostname];
	NSString *port = [accountInfo port];
	return [NSString stringWithFormat:@"%@://%@:%@", protocol, host, port];	
}

- (NSURL *)serviceDocumentURL
{
	// FIXME: Add slash checks
	AccountInfo *accountInfo = [[AccountManager sharedManager] accountInfoForUUID:accountUUID];
	NSString *protocol = [accountInfo protocol];
	NSString *host = [accountInfo hostname];
	NSString *port = [accountInfo port];
	NSString *serviceDocRequestPath = [accountInfo serviceDocumentRequestPath];
	NSString *serviceDocumentURLString = [NSString stringWithFormat:@"%@://%@:%@%@", protocol, host, port, serviceDocRequestPath];
    AlfrescoLogDebug(@"SERVICE DOC URL: %@", serviceDocumentURLString);
    
	return [NSURL URLWithString:serviceDocumentURLString];
}

- (NSURL *)childrenURLforNode: (NSString*)node
{
	NSString *baseUrlStr = [self hostURL];
	NSString *urlStr = [NSString stringWithFormat:@"%@%@/children?includeAllowableActions=true", baseUrlStr, node];
	NSURL *u         = [NSURL URLWithString:urlStr];
	
	return u;
}

- (NSURL *)setContentURLforNode: (NSString*)nodeId
{
   /* NSString *urlStr = [NSString stringWithFormat:@"%@/i/%@", [self serviceDocumentURL], nodeId];
	NSURL *u         = [NSURL URLWithString:urlStr];
	*/
    NSString *urlStr = [NSString stringWithFormat:@"%@/content?id=%@&overwriteFlag=true", [self serviceDocumentURL],nodeId];
	NSURL *u         = [NSURL URLWithString:urlStr];
    
	return u;
}

- (NSURL *)setContentURLforNode: (NSString*)nodeId tenantId:(NSString *)tenantId
{
    /*NSString *urlStr = [NSString stringWithFormat:@"%@/a/%@/cmis/i/%@", [self serviceDocumentURL], tenantId, nodeId];
	NSURL *u         = [NSURL URLWithString:urlStr];*/
    NSString *urlStr = [NSString stringWithFormat:@"%@/%@/content?id=%@&overwriteFlag=true", [self serviceDocumentURL], tenantId, nodeId];
	NSURL *u         = [NSURL URLWithString:urlStr];
	
	return u;
}

- (NSURL *)moveObjectURLFromNode: (NSString*) sourceFolderId targetFolderId:(NSString *) targetFolderId repoId:(NSString*) repoId
{
    NSString *urlStr = [NSString stringWithFormat:@"%@/%@/children?id=%@&sourceFolderId=%@", [self serviceDocumentURL], repoId, targetFolderId, sourceFolderId];
	NSURL *u         = [NSURL URLWithString:urlStr];
	
	return u;
}

#pragma mark -
#pragma mark Singleton methods
+ (AlfrescoUtils *)sharedInstanceForAccountUUID:(NSString *)uuid
{
    AlfrescoUtils *sharedInstance = nil;
    @synchronized(self)
    {
        if (sharedInstances == nil)
			sharedInstances = [[NSMutableDictionary alloc] init];
        
        sharedInstance = [sharedInstances objectForKey:uuid];
        
        if(sharedInstance == nil) {
            sharedInstance = [[[AlfrescoUtils alloc] initWithAccountUUID:uuid] autorelease];
            [sharedInstances setObject:sharedInstance forKey:uuid];
        }
    }
    return sharedInstance;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}
@end
