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
//  CMISObjectByPathHTTPRequest.m
//

#import "CMISURITemplateHTTPRequest.h"
#import "RepositoryItem.h"
#import "Utility.h"
#import "CMISMediaTypes.h"
#import "RepositoryInfo.h"
#import "RepositoryServices.h"
#import "RepositoryItemParser.h"

@implementation CMISURITemplateHTTPRequest
@synthesize repositoryItem = _repositoryItem;

- (void)dealloc
{
    [_repositoryItem release];
    [super dealloc];
}

- (id)initWithTemplateURL:(NSString *)templateUrl parameters:(NSDictionary *)parameters accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{   
    NSString *resultUrl = replaceStringWithNamedParameters(templateUrl, parameters);
    self = [super initWithURL:[NSURL URLWithString:resultUrl] accountUUID:uuid];
    if(self)
    {
        [self setShouldContinueWhenAppEntersBackground:YES];
        [self setAllowCompressedResponse:YES]; // this is the default, but being verbose
        
        [self addRequestHeader:@"Accept" value:kAtomPubServiceMediaType];
        [self setRequestMethod:@"GET"];
    }
	
	return self;
}

- (void)requestFinishedWithSuccessResponse
{
    RepositoryItemParser *parser = [[RepositoryItemParser alloc] initWithData:self.responseData];
    [parser setAccountUUID:self.accountUUID];
    [self setRepositoryItem:[parser parse]];
    [parser release];
}

+ (id)cmisObjectByPathRequest:(NSString *)cmisPath accountUUID:(NSString *)uuid tenantID:(NSString *)tenantID
{
    NSDictionary *namedParameters = [NSDictionary dictionaryWithObjectsAndKeys:cmisPath, @"path",
                                     @"",@"filter",
                                     @"true",@"includeAllowableActions", 
                                     @"false",@"includePolicyIds",
                                     @"false",@"includeRelationships",
                                     @"false",@"includeACL",
                                     @"",@"renditionFilter",nil];
    RepositoryInfo *repoInfo = [[RepositoryServices shared] getRepositoryInfoForAccountUUID:uuid tenantID:tenantID];
    return [[[self alloc] initWithTemplateURL:[repoInfo objectByPathUriTemplate] parameters:namedParameters accountUUID:uuid tenantID:tenantID] autorelease];
}

+ (id)cmisObjectByIdRequest:(NSString *)objectId accountUUID:(NSString *)uuid tenantID:(NSString *)tenantID
{
    NSDictionary *namedParameters = [NSDictionary dictionaryWithObjectsAndKeys:objectId, @"id",
                                     @"",@"filter",
                                     @"true",@"includeAllowableActions", 
                                     @"false",@"includePolicyIds",
                                     @"false",@"includeRelationships",
                                     @"false",@"includeACL",
                                     @"",@"renditionFilter",nil];
    RepositoryInfo *repoInfo = [[RepositoryServices shared] getRepositoryInfoForAccountUUID:uuid tenantID:tenantID];
    return [[[self alloc] initWithTemplateURL:[repoInfo objectByIdUriTemplate] parameters:namedParameters accountUUID:uuid tenantID:tenantID] autorelease];
}

@end
