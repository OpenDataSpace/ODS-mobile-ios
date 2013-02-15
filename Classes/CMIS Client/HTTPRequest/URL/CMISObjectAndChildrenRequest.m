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
//  CMISObjectAndChildrenRequest.m
//

#import "CMISObjectAndChildrenRequest.h"
#import "LinkRelationService.h"
#import "CMISURITemplateHTTPRequest.h"

@implementation CMISObjectAndChildrenRequest
@synthesize item = _item;
@synthesize children = _children;
@synthesize delegate = _delegate;
@synthesize objectRequest = _objectRequest;
@synthesize childrenRequest = _childrenRequest;
@synthesize didFinishSelector = _didFinishSelector;
@synthesize didFailSelector = _didFailSelector;
@synthesize accountUUID = _accountUUID;
@synthesize tenantID = _tenantID;

@synthesize objectRequestFactory = _objectRequestFactory;
@synthesize objectId = _objectId;
@synthesize cmisPath = _cmisPath;

- (void)dealloc
{
    [_item release];
    [_children release];
    [_objectRequest release];
    [_childrenRequest release];
    [_accountUUID release];
    [_tenantID release];
    [_objectId release];
    [_cmisPath release];
    [super dealloc];
}

- (id)init
{
    return [self initWithObjectRequestFactory:nil accountUUID:NULL tenantID:nil];
}

- (id)initWithObjectId:(NSString *)objectId accountUUID:(NSString *)uuid tenantID:(NSString *)tenantID
{
    self = [self initWithObjectRequestFactory:@selector(objectByIdRequestFactory) accountUUID:uuid tenantID:tenantID];
    if(self)
    {
        _objectId = [objectId copy];
    }
    return self;
}

- (id)initWithPath:(NSString *)path accountUUID:(NSString *)uuid tenantID:(NSString *)tenantID
{
    self = [self initWithObjectRequestFactory:@selector(objectByPathRequestFactory) accountUUID:uuid tenantID:tenantID];
    if(self)
    {
        _cmisPath = [path copy];
    }
    return self;
}

/*
 Object Request Factory
 */
- (id)objectByIdRequestFactory
{
    CMISURITemplateHTTPRequest *objectRequest = [CMISURITemplateHTTPRequest cmisObjectByIdRequest:self.objectId accountUUID:self.accountUUID tenantID:self.tenantID];
    [objectRequest setDelegate:self];
    return objectRequest;
}

- (id)objectByPathRequestFactory
{
    CMISURITemplateHTTPRequest *objectRequest = [CMISURITemplateHTTPRequest cmisObjectByPathRequest:self.cmisPath accountUUID:self.accountUUID tenantID:self.tenantID];
    [objectRequest setDelegate:self];
    return objectRequest;
}

/*
 Designated initializer
 */
- (id)initWithObjectRequestFactory:(SEL)objectRequestFactory accountUUID:(NSString *)uuid tenantID:(NSString *)tenantID
{
    self = [super init];
    if(self)
    {
        _accountUUID = [uuid copy];
        _tenantID = [tenantID copy];
        _objectRequestFactory = objectRequestFactory;
        _didFinishSelector = @selector(requestFinished:);
        _didFailSelector = @selector(requestFailed:);
        
    }
    return self;
}

- (void)startAsynchronous
{
    if(self.objectRequestFactory)
    {
        [self.objectRequest clearDelegatesAndCancel];
        [self setObjectRequest:[self performSelector:self.objectRequestFactory]];
        [self.objectRequest startAsynchronous];
    }
    else
    {
        if([self.delegate respondsToSelector:self.didFailSelector])
        {
            [self.delegate performSelector:self.didFailSelector withObject:self];
        }
    }
}

- (void)clearDelegatesAndCancel
{
    [self.objectRequest clearDelegatesAndCancel];
    [self.childrenRequest clearDelegatesAndCancel];
    [self setObjectRequest:nil];
    [self setChildrenRequest:nil];
}

#pragma mark - ASIHTTPRequestDelegate methods
- (void)requestFinished:(id)request
{
    if([request isKindOfClass:[self.objectRequest class]])
    {
        if([request respondsToSelector:@selector(repositoryItem)])
        {
            [self setItem:[request repositoryItem]];
            RepositoryItem *repositoryNode = [self item];
            NSDictionary *optionalArguments = [[LinkRelationService shared] 
                                               optionalArgumentsForFolderChildrenCollectionWithMaxItems:nil skipCount:nil filter:nil 
                                               includeAllowableActions:YES includeRelationships:NO renditionFilter:nil orderBy:nil includePathSegment:NO];
            NSURL *getChildrenURL = [[LinkRelationService shared] getChildrenURLForCMISFolder:repositoryNode 
                                                                        withOptionalArguments:optionalArguments];
            
            FolderItemsHTTPRequest *down = [[[FolderItemsHTTPRequest alloc] initWithURL:getChildrenURL accountUUID:self.accountUUID] autorelease];
            [down setDelegate:self];
            [down setItem:repositoryNode];
            [down setParentTitle:repositoryNode.title];
            [self setChildrenRequest:down];
            [down startAsynchronous];
        } 
        else 
        {
            NSLog(@"The objectRequest did not responds to the repositoryItem selector");
            if([self.delegate respondsToSelector:self.didFailSelector])
            {
                [self.delegate performSelector:self.didFailSelector withObject:self];
            }
        }
        
    }
    else if([request isKindOfClass:[FolderItemsHTTPRequest class]])
    {
        [self setChildren:[self.childrenRequest children]];
        if([self.delegate respondsToSelector:self.didFinishSelector])
        {
            [self.delegate performSelector:self.didFinishSelector withObject:self];
        }
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    alfrescoLog(AlfrescoLogLevelTrace, @"Request failed with error: %@", [request error]);
    if([self.delegate respondsToSelector:self.didFailSelector])
    {
        [self.delegate performSelector:self.didFailSelector withObject:self];
    }
}

@end
