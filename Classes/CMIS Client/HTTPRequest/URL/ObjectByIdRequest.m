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
//  ObjectByIdRequest.m
//

#import "ObjectByIdRequest.h"
#import "CMISMediaTypes.h"
#import "Utility.h"
#import "RepositoryServices.h"
#import "RepositoryItem.h"
#import "RepositoryItemParser.h"

@implementation ObjectByIdRequest
@synthesize repositoryItem = _repositoryItem;

- (void) dealloc 
{
    [_repositoryItem release];
    [super dealloc];
}

- (void)requestFinishedWithSuccessResponse
{
    RepositoryItemParser *parser = [[RepositoryItemParser alloc] initWithData:self.responseData];
    [parser setAccountUUID:self.accountUUID];
    [self setRepositoryItem:[parser parse]];
    [parser release];
}

#pragma mark - Factory Methods

+ (ObjectByIdRequest *)defaultObjectById:(NSString *)objectId accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
    RepositoryInfo *repoInfo = [[RepositoryServices shared] getRepositoryInfoForAccountUUID:uuid tenantID:aTenantID];
    if (repoInfo)
    {
        return [ObjectByIdRequest objectByIdWithTemplateURL:[repoInfo objectByIdUriTemplate] objectId:objectId accountUUID:uuid tenantID:aTenantID];
    }
    
    return nil;
}

+ (ObjectByIdRequest *)objectByIdWithTemplateURL:(NSString *)templateUrl objectId:(NSString *)objectId accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
    NSDictionary *namedParameters = [NSDictionary dictionaryWithObjectsAndKeys:objectId, @"id",
                                     @"",@"filter",
                                     @"true",@"includeAllowableActions", 
                                     @"false",@"includePolicyIds",
                                     @"none",@"includeRelationships",  //TODO:our server not support false;
                                     @"false",@"includeACL",
                                     @"cmis:thumbnail",@"renditionFilter",nil];
    
    NSString *url = replaceStringWithNamedParameters(templateUrl, namedParameters);
	ObjectByIdRequest *getRequest = [ObjectByIdRequest requestWithURL:[NSURL URLWithString:url] accountUUID:uuid];
    [getRequest setTenantID:aTenantID];
    [getRequest setShouldContinueWhenAppEntersBackground:YES];
	[getRequest setAllowCompressedResponse:YES]; // this is the default, but being verbose
	
	[getRequest addRequestHeader:@"Accept" value:kAtomPubServiceMediaType];
	[getRequest setRequestMethod:@"GET"];
    [getRequest setTimeOutSeconds:120];
	
	return [[getRequest retain] autorelease];
}

+ (ObjectByIdRequest *)objectByIdWithURL:(NSString *)locationUrl accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID {
    NSDictionary *namedParameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                     @"",@"filter",
                                     @"true",@"includeAllowableActions",
                                     @"false",@"includePolicyIds",
                                     @"none",@"includeRelationships",  //TODO:our server not support false;
                                     @"false",@"includeACL",
                                     @"cmis:thumbnail",@"renditionFilter",nil];
    
    NSString *url = replaceStringWithNamedParameters(locationUrl, namedParameters);
    ObjectByIdRequest *getRequest = [ObjectByIdRequest requestWithURL:[NSURL URLWithString:url] accountUUID:uuid];
    [getRequest setTenantID:aTenantID];
    [getRequest setShouldContinueWhenAppEntersBackground:YES];
    [getRequest setAllowCompressedResponse:YES]; // this is the default, but being verbose
    
    [getRequest addRequestHeader:@"Accept" value:kAtomPubServiceMediaType];
    [getRequest setRequestMethod:@"GET"];
    [getRequest setTimeOutSeconds:120];
    
    return [[getRequest retain] autorelease];
}

@end
