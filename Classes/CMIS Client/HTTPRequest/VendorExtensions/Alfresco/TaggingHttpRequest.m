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
//  TaggingHttpRequest.m
//

#import "TaggingHttpRequest.h"

NSString * const kListAllTags = @"kListAllTags";
NSString * const kGetNodeTags = @"kGetNodeTags";
NSString * const kAddTagsToNode = @"kAddTagsToNode";
NSString * const kCreateTag = @"kCreateTag";

@implementation TaggingHttpRequest
@synthesize nodeRef;
@synthesize apiMethod;
@synthesize userDictionary;
@synthesize uploadUUID;

- (void)dealloc
{
    [nodeRef release];
    [apiMethod release];
    [userDictionary release];
    [uploadUUID release];
    [super dealloc];
}

- (id)init 
{
    self = [super init];
    if (self) {
        userDictionary = [[NSMutableDictionary dictionary] retain];
    }
    return self;
}


- (void)addUserProvidedObject:(id)object forKey:(NSString *)userKey
{
    [userDictionary setObject:object forKey:userKey];
}


#pragma mark -
#pragma mark ASIHttpRequestDelegate Methods

- (void)requestFinishedWithSuccessResponse
{
    AlfrescoLogTrace(@"Tagging Request Finished: %@", [self responseString]);
    // TODO Parse resulting tags here.
}

- (void)failWithError:(NSError *)theError
{
    if (theError)
        NSLog(@"Tagging HTTP Request Failure: %@", theError);
    
    [super failWithError:theError];
}



#pragma mark -
#pragma mark Static Class Methods

//
// GET /alfresco/service/api/node/{store_type}/{store_id}/{id}/tags
// GET /alfresco/service/api/path/{store_type}/{store_id}/{id}/tags
//
+ (id)httpRequestListAllTagsWithAccountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
    NSMutableDictionary *infoDictionary = [NSMutableDictionary dictionary];
    [infoDictionary setObject:[NodeRef nodeRefFromCmisObjectId:@"workspace://SpacesStore/00000"] forKey:@"NodeRef"];
    
    TaggingHttpRequest *request = [TaggingHttpRequest requestForServerAPI:kServerAPIListAllTags accountUUID:uuid tenantID:aTenantID infoDictionary:infoDictionary];
    [request setRequestMethod:@"GET"];
    [request setShouldContinueWhenAppEntersBackground:YES];
    [request setApiMethod:kListAllTags];
    return request;
}

//
// POST /alfresco/service/api/tag/{store_type}/{store_id}
//
+ (id)httpRequestCreateNewTag:(NSString *)tag accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
    NSDictionary *jsonObject = [NSDictionary dictionaryWithObject:tag forKey:@"name"];

    NSMutableDictionary *infoDictionary = [NSMutableDictionary dictionary];
    [infoDictionary setObject:[NodeRef nodeRefFromCmisObjectId:@"workspace://SpacesStore/00000"] forKey:@"NodeRef"];
    
    TaggingHttpRequest *request = [TaggingHttpRequest requestForServerAPI:kServerAPITagCollection accountUUID:uuid tenantID:aTenantID infoDictionary:infoDictionary];   
    [request setPostBody:[request mutableDataFromJSONObject:jsonObject]];
    [request setContentLength:[request.postBody length]];
    [request addRequestHeader:@"Content-Type" value:@"application/json"];
    [request setRequestMethod:@"POST"];
    [request setApiMethod:kCreateTag];
    [request addUserProvidedObject:tag forKey:@"tag"];
    
    return request;
}

// 
// GET /alfresco/service/api/node/{store_type}/{store_id}/{id}/tags
// GET /alfresco/service/api/path/{store_type}/{store_id}/{id}/tags
//
+ (id)httpRequestGetNodeTagsForNode:(NodeRef *)nodeRef accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
    NSMutableDictionary *infoDictionary = [NSMutableDictionary dictionary];
    [infoDictionary setObject:nodeRef forKey:@"NodeRef"];
    
    TaggingHttpRequest *request = [TaggingHttpRequest requestForServerAPI:kServerAPINodeTagCollection accountUUID:uuid tenantID:aTenantID infoDictionary:infoDictionary];
    [request setNodeRef:nodeRef];
    [request setRequestMethod:@"GET"];
    [request setApiMethod:kGetNodeTags];
    return request;
}

//
// POST /alfresco/service/api/node/{store_type}/{store_id}/{id}/tags
// POST /alfresco/service/api/path/{store_type}/{store_id}/{id}/tags
//
+ (id)httpRequestAddTags:(NSArray *)tags toNode:(NodeRef *)nodeRef accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
    NSMutableDictionary *infoDictionary = [NSMutableDictionary dictionary];
    [infoDictionary setObject:nodeRef forKey:@"NodeRef"];
    
    TaggingHttpRequest *request = [TaggingHttpRequest requestForServerAPI:kServerAPINodeTagCollection accountUUID:uuid tenantID:aTenantID infoDictionary:infoDictionary];
    [request setNodeRef:nodeRef];
    [request setPostBody:[request mutableDataFromJSONObject:tags]];
    [request setContentLength:[request.postBody length]];
    [request addRequestHeader:@"Content-Type" value:@"application/json"];
    [request setRequestMethod:@"POST"];
    [request setShouldContinueWhenAppEntersBackground:YES];
    [request setApiMethod:kAddTagsToNode];
    return request;
}


+ (NSArray *)tagsArrayWithResponseString:(NSString *)responseString accountUUID:(NSString *)uuid
{
    //
    // BEGIN CRAP - the block of code below was my quickest way to take a malformed JSON response from 
    // Alfresco.  The code below is crap and does need to be re-written in a much more reasonable method
    // The code also accounts for well formed-json responses.
    //
    NSString *temp = [responseString stringByReplacingOccurrencesOfString:@"[" withString:@""];
    temp = [temp stringByReplacingOccurrencesOfString:@"]" withString:@""];
    temp = [[temp stringByReplacingOccurrencesOfString:@"\r\n" withString:@""] stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    temp = [temp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSArray *splitTags = [temp componentsSeparatedByString:@","];
    NSMutableArray *finalizedTags = [NSMutableArray array];
    for (NSString *t in splitTags)
    {
        NSString *aTag = [t stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        aTag = [aTag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        // ignore empty tags
        if ([aTag length] > 0)
        {
            // ignore duplicate tags
            if (![finalizedTags containsObject:aTag])
            {
                [finalizedTags addObject:aTag];
            }
        }
    }
    
    // return the tags aplhabetically
    NSArray *sortedTags = [finalizedTags sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    return sortedTags;
    
    //
    // END CRAP
    //
}

@end
