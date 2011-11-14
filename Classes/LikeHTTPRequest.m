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
 * Portions created by the Initial Developer are Copyright (C) 2011
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  LikeHTTPRequest.m
//

#import "LikeHTTPRequest.h"
#import "ASIHttpRequest+Alfresco.h"
#import "ASIHTTPRequest+Utils.h"
#import "NodeRef.h"
#import "SBJSON.h"
#import "Utility.h"

@implementation LikeHTTPRequest
@synthesize likeDelegate;
@synthesize nodeRef;


#pragma mark Memory Managemen

- (void)dealloc
{
    [nodeRef release];
    
    [super dealloc];
}


#pragma Init methods

// TODO Check for the rating service
+ (id)ratingsServiceHTTPDefinitionRequest
{
    return nil;
}


//  GET  /api/node/{store_type}/{store_id}/{id}/ratings
//  KEYPATH: data.ratings.likesRatingScheme.[rating|appliedBy]
+ (id)getHTTPRequestForNodeRef:(NodeRef *)aNodeRef
{
    NSString  *urlString = [[ASIHTTPRequest alfrescoRepositoryBaseServiceUrlString] 
                            stringByAppendingFormat:@"/api/node/%@/%@/%@/ratings", 
                            [aNodeRef storeType], [aNodeRef storeId], [aNodeRef objectId]];
    NSLog(@"RatingService\r\nGET:\t%@", urlString);;
    
    LikeHTTPRequest *request = [LikeHTTPRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setTag:kLike_GET_Request];
    [request setNodeRef:aNodeRef];
    
    [request setRequestMethod:@"GET"];
    [request addBasicAuthHeader];
    
    return request;

}

//  POST  /api/node/{store_type}/{store_id}/{id}/ratings
+ (id)postHTTPRequestForNodeRef:(NodeRef *)aNodeRef
{
    // JSON: {"rating":1, "ratingScheme":"likesRatingScheme"}
    NSMutableDictionary *jsonDictionary = [[NSMutableDictionary alloc] init];
    [jsonDictionary setObject:@"1" forKey:@"rating"];
    [jsonDictionary setObject:@"likesRatingScheme" forKey:@"ratingScheme"];
    
    SBJSON *jsonWriter = [SBJSON new];
    NSString *jsonString = [jsonWriter stringWithObject:jsonDictionary];
    [jsonDictionary release];
    [jsonWriter release];
    
    NSLog(@"Like a Document JSON: %@", jsonString);
    

    NSString  *urlString = [[ASIHTTPRequest alfrescoRepositoryBaseServiceUrlString] 
                            stringByAppendingFormat:@"/api/node/%@/%@/%@/ratings", 
                            [aNodeRef storeType], [aNodeRef storeId], [aNodeRef objectId]];
    NSLog(@"RatingService\r\nPOST:\t%@", urlString);;
    
    LikeHTTPRequest *request = [LikeHTTPRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setTag:kLike_POST_Request];
    [request setNodeRef:aNodeRef];
    
    [request setPostBody:[NSMutableData dataWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]]];
    [request setContentLength:[jsonString length]];
    [request setRequestMethod:@"POST"];
    [request addBasicAuthHeader];

    return request;
}

//  DELETE  /api/node/{store_type}/{store_id}/{id}/ratings/likeRatingsScheme
// {}
+ (id)deleteHTTPRequest:(NodeRef *)aNodeRef
{
    NSString  *urlString = [[ASIHTTPRequest alfrescoRepositoryBaseServiceUrlString] 
                            stringByAppendingFormat:@"/api/node/%@/%@/%@/ratings/likesRatingScheme", 
                            [aNodeRef storeType], [aNodeRef storeId], [aNodeRef objectId]];
    NSLog(@"RatingService\r\nDELETE:\t%@", urlString);;
    
    LikeHTTPRequest *request = [LikeHTTPRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setTag:kLike_DELETE_Request];
    [request setNodeRef:aNodeRef];
    
//    [request setPostBody:[NSMutableData dataWithData:[@"{}" dataUsingEncoding:NSUTF8StringEncoding]]];
//    [request setContentLength:2];
    [request setRequestMethod:@"DELETE"];
    [request addBasicAuthHeader];

    return request;
}


#pragma mark -
#pragma Overriden ASIHTTPRequest Delegate Methods

- (void)requestFinished
{
    NSLog(@"LIKE RESPONSE: %@", [self responseString]);
    
    if (![self responseSuccessful]) {
		[self failWithError:[NSError errorWithDomain:CMISNetworkRequestErrorDomain 
												code:ASIUnhandledExceptionError userInfo:nil]];
        return;
	}
    
    SBJSON *parser = [SBJSON new];
    id jsonObject = [parser objectWithString:[self responseString]];
    [parser release];
    
    switch ([self tag]) {
        case kLike_GET_Request:
        {
            BOOL isLiked = NO;
            NSString *ratingAppliedBy = [jsonObject valueForKeyPath:@"data.ratings.likesRatingScheme.appliedBy"];
            NSInteger rating = (NSInteger)[[jsonObject valueForKeyPath:@"data.ratings.likesRatingScheme.rating"] intValue];
            if ([ratingAppliedBy isEqualToString:userPrefUsername()] && rating > 0)
            {
                isLiked = YES;
            }
            
            if ([likeDelegate respondsToSelector:@selector(likeRequest:documentIsLiked:)]) {
                [likeDelegate performSelector:@selector(likeRequest:documentIsLiked:) withObject:self withObject:(isLiked?kLike_YES_Str:kLike_No_Str)];
            }
            break;
        }
        case kLike_POST_Request:
        {
            if ([likeDelegate respondsToSelector:@selector(likeRequest:likeDocumentSuccess:)]) {
                [likeDelegate performSelector:@selector(likeRequest:likeDocumentSuccess:) withObject:self withObject:(YES?kLike_YES_Str:kLike_No_Str)];
            }
            break;
        }
        case kLike_DELETE_Request:
        {
            if ([likeDelegate respondsToSelector:@selector(likeRequest:unlikeDocumentSuccess:)]) {
                [likeDelegate performSelector:@selector(likeRequest:unlikeDocumentSuccess:) withObject:self withObject:(YES?kLike_YES_Str:kLike_No_Str)];
            }
            break;            
        }
        default:
            break;
    }
    
    [super requestFinished];
}

- (void)failWithError:(NSError *)theError
{
    if ([likeDelegate respondsToSelector:@selector(likeRequest:failedWithError:)]) {
        [likeDelegate performSelector:@selector(likeRequest:failedWithError:) withObject:self withObject:theError];
    }
    switch ([self tag]) {
        case kLike_GET_Request:
        {           
            break;
        }
        case kLike_POST_Request:
            break;
        case kLike_DELETE_Request:
            break;            
        default:
            break;
    }

    [super failWithError:theError];
}

@end

