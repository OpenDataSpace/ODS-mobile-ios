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
//  CommentsHttpRequest.m
//

#import "CommentsHttpRequest.h"
#import "ASIHTTPRequest+Utils.h"
#import "ASIHttpRequest+Alfresco.h"
#import "JSON.h"
#import "SBJSON.h"
#import "Utility.h"
#import "AccountManager.h"

static NSString * kGetComments = @"kGetComments";
static NSString * kAddComment = @"kAddComment";


@implementation CommentsHttpRequest
@synthesize nodeRef;
@synthesize commentsDictionary;

#pragma mark -
#pragma mark Memory Management
- (void)dealloc
{
    if (requestType != nil) 
        [requestType release];
    
    [nodeRef release];
    [commentsDictionary release];    
    [super dealloc];
}


#pragma mark -
#pragma mark ASIHttpRequest Delegate Methods

-(void)requestFinishedWithSuccessResponse
{
#if MOBILE_DEBUG
    NSLog(@"Comments Response String: %@", self.responseString);
#endif
    
    SBJSON *jsonObj = [SBJSON new];
    id result = [jsonObj objectWithString:[self responseString]];
    commentsDictionary = [result retain];
    [jsonObj release];
}


-(void)failWithError:(NSError *)theError
{
    NSLog(@"CommentsHttpRequest: failWithError:");
    
    [super failWithError:theError];
}

- (void)setRequestType:(NSString *)requestTypeValue
{
    if (requestType != nil) {
        [requestType release];
        requestType = nil;
    }
    requestType = [requestTypeValue retain];
}


#pragma mark -
#pragma mark Static Class methods

// Get all comments
+ (id)commentsHttpGetRequestWithNodeRef:(NodeRef *)nodeRef accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
    NSMutableDictionary *infoDict = [NSMutableDictionary dictionary];
    [infoDict setObject:nodeRef forKey:@"NodeRef"];
    
    CommentsHttpRequest *getRequest = [CommentsHttpRequest requestForServerAPI:kServerAPIComments accountUUID:uuid tenantID:aTenantID infoDictionary:infoDict];
    [getRequest setNodeRef:nodeRef];
    [getRequest setShouldContinueWhenAppEntersBackground:YES];
    [getRequest setRequestMethod:@"GET"];
    [getRequest setRequestType:kGetComments];
    
    return getRequest;
}

// Add a new comment to a node
+ (id)CommentsHttpPostRequestForNodeRef:(NodeRef *)nodeRef comment:(NSString *)comment accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
    SBJsonWriter *writer = [SBJsonWriter alloc];
    NSString *json = [writer stringWithObject:[NSDictionary dictionaryWithObject:comment forKey:@"content"]];
    [writer release];
    
    
    NSMutableDictionary *infoDict = [NSMutableDictionary dictionary];
    [infoDict setObject:nodeRef forKey:@"NodeRef"];
    
    CommentsHttpRequest *postRequest = [CommentsHttpRequest requestForServerAPI:kServerAPIComments accountUUID:uuid tenantID:aTenantID infoDictionary:infoDict];
    [postRequest setNodeRef:nodeRef];
    [postRequest setShouldContinueWhenAppEntersBackground:YES];
    [postRequest setPostBody:[NSMutableData dataWithData:[json dataUsingEncoding:NSUTF8StringEncoding]]];
    [postRequest setContentLength:[json length]];
    [postRequest addRequestHeader:@"Content-Type" value:@"application/json"];
    [postRequest setRequestMethod:@"POST"];
    [postRequest setRequestType:kAddComment];
    
    return postRequest;
}

@end
