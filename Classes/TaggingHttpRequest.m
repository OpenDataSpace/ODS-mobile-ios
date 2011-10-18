//
//  TaggingHttpRequest.m
//  FreshDocs
//
//  Created by Gi Hyun Lee on 8/4/11.
//  Copyright 2011 Zia Consulting. All rights reserved.
//

#import "TaggingHttpRequest.h"


NSString * const kListAllTags = @"kListAllTags";
NSString * const kGetNodeTags = @"kGetNodeTags";
NSString * const kAddTagsToNode = @"kAddTagsToNode";
NSString * const kCreateTag = @"kCreateTag";

@implementation TaggingHttpRequest
@synthesize apiMethod;
@synthesize userDictionary;

- (void)dealloc
{
    [apiMethod release];
    [super dealloc];
}

- (id)init 
{
    self = [super init];
    if (self) {
        userDictionary = [[NSMutableDictionary alloc] init];
    }
    return self;
}


- (void)addUserProvidedObject:(id)object forKey:(NSString *)userKey
{
    [userDictionary setObject:object forKey:userKey];
}


#pragma mark -
#pragma mark ASIHttpRequestDelegate Methods

- (void)requestFinished
{
    NSLog(@"Tagging Request Finished: %@", [self responseString]);
    //	Check that we are valid
	if (![self responseSuccessful]) {
		// FIXME: Recode domain, code and userInfo.  Use ASI as an example but do for CMIS errors
		// !!!: Make sure to cleanup because we are in an error
		
		[self failWithError:[NSError errorWithDomain:CMISNetworkRequestErrorDomain 
												code:ASIUnhandledExceptionError userInfo:nil]];
        return;
	}
    
    // TODO Parse resulting tags here.
    
    [super requestFinished];
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
+ (id)httpRequestListAllTags
{
    NSString  *urlString = [[self alfrescoRepositoryBaseServiceUrlString] stringByAppendingString:@"/api/tags/workspace/SpacesStore"];
    NSLog(@"List All Tags\r\nGET:\t%@", urlString);
    TaggingHttpRequest *request = [TaggingHttpRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setRequestMethod:@"GET"];
    [request addBasicAuthHeader];
    [request setApiMethod:kListAllTags];
    return request;
}

//
// POST /alfresco/service/api/tag/{store_type}/{store_id}
//
+ (id)httpRequestCreateNewTag:(NSString *)tag
{
    NSString *json = [NSString stringWithFormat:@"{\"name\": \"%@\" }", tag];

    NSString  *urlString = [[self alfrescoRepositoryBaseServiceUrlString] stringByAppendingString:@"/api/tag/workspace/SpacesStore"];
    NSLog(@"Create New Tag\r\nPOST:\t%@\r\nPOST BODY:\t%@", urlString, json);
    
    TaggingHttpRequest *request = [TaggingHttpRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setPostBody:[NSMutableData dataWithData:[json dataUsingEncoding:NSUTF8StringEncoding]]];
    [request setContentLength:[json length]];
    [request addRequestHeader:@"Content-Type" value:@"application/json"];
    [request setRequestMethod:@"POST"];
    [request addBasicAuthHeader];
    
    [request setApiMethod:kCreateTag];
    [request addUserProvidedObject:tag forKey:@"tag"];
    
    return request;
}

// 
// GET /alfresco/service/api/node/{store_type}/{store_id}/{id}/tags
// GET /alfresco/service/api/path/{store_type}/{store_id}/{id}/tags
//
+ (id)httpRequestGetNodeTagsForNode:(NodeRef *)nodeRef
{
    NSString  *urlString = [[self alfrescoRepositoryBaseServiceUrlString] stringByAppendingFormat:@"/api/node/%@/%@/%@/tags", 
                            nodeRef.storeType, nodeRef.storeId, nodeRef.objectId];
    NSLog(@"Get Tags for Node\r\nGET:\t%@", urlString);
    
    TaggingHttpRequest *request = [TaggingHttpRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setRequestMethod:@"GET"];
    [request addBasicAuthHeader];
    [request setApiMethod:kGetNodeTags];
    return request;
}

//
// POST /alfresco/service/api/node/{store_type}/{store_id}/{id}/tags
// POST /alfresco/service/api/path/{store_type}/{store_id}/{id}/tags
//
+ (id)httpRequestAddTags:(NSArray *)tags toNode:(NodeRef *)nodeRef
{
    NSString *json = [tags componentsJoinedByString:@"\",\""];
    json = [NSString stringWithFormat:@"[\"%@\"]", json];
    
    NSString  *urlString = [[self alfrescoRepositoryBaseServiceUrlString] stringByAppendingFormat:@"/api/node/%@/%@/%@/tags", 
                            nodeRef.storeType, nodeRef.storeId, nodeRef.objectId];
    NSLog(@"Add Tags\r\nPOST:\t%@\r\nPOST BODY:\t%@", urlString, json);
    
    TaggingHttpRequest *request = [TaggingHttpRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setPostBody:[NSMutableData dataWithData:[json dataUsingEncoding:NSUTF8StringEncoding]]];
    [request setContentLength:[json length]];
    [request addRequestHeader:@"Content-Type" value:@"application/json"];
    [request setRequestMethod:@"POST"];
    [request addBasicAuthHeader];
    [request setApiMethod:kAddTagsToNode];
    return request;
}


+ (NSArray *)tagsArrayWithResponseString:(NSString *)responseString
{
    //
    // The block of code below was my quickest way to take a malformed JSON response from 
    // Alfresco.  Thecode below should be re-written in a much more elegant method as it was put together in a rush.
    // The code also accounts for wellformed-json responses.
    //
    NSString *temp = [responseString stringByReplacingOccurrencesOfString:@"[" withString:@""];
    temp = [temp stringByReplacingOccurrencesOfString:@"]" withString:@""];
    temp = [[temp stringByReplacingOccurrencesOfString:@"\r\n" withString:@""] stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    temp = [temp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSArray *splitTags = [temp componentsSeparatedByString:@","];
    NSMutableArray *finalizedTags = [NSMutableArray array];
    for (NSString *t in splitTags) {
        NSString *aTag = [t stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        aTag = [aTag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [finalizedTags addObject:aTag];
    }
    return finalizedTags;
    //
    // END
    //
}

@end
