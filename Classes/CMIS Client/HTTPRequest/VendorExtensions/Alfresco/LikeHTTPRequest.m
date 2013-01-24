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
//  LikeHTTPRequest.m
//

#import "LikeHTTPRequest.h"
#import "ASIHttpRequest+Alfresco.h"

@implementation LikeHTTPRequest

#pragma mark Memory Managemen

- (void)dealloc
{
    _likeDelegate = nil;
    [_nodeRef release];
    
    [super dealloc];
}


#pragma Init methods

// TODO Check for the rating service
+ (id)ratingsServiceHTTPDefinitionRequestWithAccountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
    return nil;
}


//  GET  /api/node/{store_type}/{store_id}/{id}/ratings
//  KEYPATH: data.ratings.likesRatingScheme.[rating|appliedBy]
+ (id)getHTTPRequestForNodeRef:(NodeRef *)nodeRef accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
    NSDictionary *infoDictionary = [NSDictionary dictionaryWithObject:nodeRef forKey:@"NodeRef"];
    LikeHTTPRequest *request = [LikeHTTPRequest requestForServerAPI:kServerAPIRatings accountUUID:uuid 
                                                           tenantID:aTenantID infoDictionary:infoDictionary];
    [request setTag:kLike_GET_Request];
    [request setNodeRef:nodeRef];
    [request setRequestMethod:@"GET"];
    [request setShouldContinueWhenAppEntersBackground:YES];
    
    return request;

}

//  POST  /api/node/{store_type}/{store_id}/{id}/ratings
+ (id)postHTTPRequestForNodeRef:(NodeRef *)nodeRef accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
    // JSON: {"rating":1, "ratingScheme":"likesRatingScheme"}
    NSDictionary *jsonDictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"1", @"rating",
                                    @"likesRatingScheme", @"ratingScheme",
                                    nil];
    
    NSDictionary *infoDictionary = [NSDictionary dictionaryWithObject:nodeRef forKey:@"NodeRef"];

    LikeHTTPRequest *request = [LikeHTTPRequest requestForServerAPI:kServerAPIRatings accountUUID:uuid tenantID:aTenantID infoDictionary:infoDictionary];
    [request setTag:kLike_POST_Request];
    [request setNodeRef:nodeRef];
    [request setPostBody:[request mutableDataFromJSONObject:jsonDictionary]];
    [request setContentLength:[request.postBody length]];
    [request setRequestMethod:@"POST"];

    return request;
}

//  DELETE  /api/node/{store_type}/{store_id}/{id}/ratings/likeRatingsScheme
// {}
+ (id)deleteHTTPRequest:(NodeRef *)nodeRef accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
    static NSString *likesRatingSchemeURLPathComponent = @"likesRatingScheme";
    
    NSDictionary *infoDictionary = [NSDictionary dictionaryWithObject:nodeRef forKey:@"NodeRef"];
    LikeHTTPRequest *request = [LikeHTTPRequest requestForServerAPI:kServerAPIRatings accountUUID:uuid 
                                                           tenantID:aTenantID infoDictionary:infoDictionary];
    
    // Update the URL since the ServerAPI only is for the RatingsService
    [request setURL:[[request url] URLByAppendingPathComponent:likesRatingSchemeURLPathComponent]];
    
    [request setTag:kLike_DELETE_Request];
    [request setNodeRef:nodeRef];
    [request setRequestMethod:@"DELETE"];

    return request;
}


#pragma mark - ASIHTTPRequest Delegate Methods

- (void)requestFinishedWithSuccessResponse
{
#if MOBILE_DEBUG
    NSLog(@"LIKE RESPONSE: %@", [self responseString]);
#endif
    
    NSDictionary *jsonObject = [self dictionaryFromJSONResponse];
    
    switch ([self tag])
    {
        case kLike_GET_Request:
        {
            BOOL isLiked = NO;
            NSString *ratingAppliedBy = [jsonObject valueForKeyPath:@"data.ratings.likesRatingScheme.appliedBy"];
            NSInteger rating = (NSInteger)[[jsonObject valueForKeyPath:@"data.ratings.likesRatingScheme.rating"] intValue];
            if ([ratingAppliedBy isEqualToString:[self.accountInfo username]] && rating > 0)
            {
                isLiked = YES;
            }
            
            if ([self.likeDelegate respondsToSelector:@selector(likeRequest:documentIsLiked:)])
            {
                [self.likeDelegate performSelector:@selector(likeRequest:documentIsLiked:) withObject:self withObject:(isLiked ? kLike_YES_Str : kLike_No_Str)];
            }
            break;
        }
        case kLike_POST_Request:
        {
            if ([self.likeDelegate respondsToSelector:@selector(likeRequest:likeDocumentSuccess:)])
            {
                [self.likeDelegate performSelector:@selector(likeRequest:likeDocumentSuccess:) withObject:self withObject:kLike_YES_Str];
            }
            break;
        }
        case kLike_DELETE_Request:
        {
            if ([self.likeDelegate respondsToSelector:@selector(likeRequest:unlikeDocumentSuccess:)])
            {
                [self.likeDelegate performSelector:@selector(likeRequest:unlikeDocumentSuccess:) withObject:self withObject:kLike_YES_Str];
            }
            break;            
        }
        default:
            break;
    }
}

- (void)failWithError:(NSError *)theError
{
    if ([self.likeDelegate respondsToSelector:@selector(likeRequest:failedWithError:)])
    {
        [self.likeDelegate performSelector:@selector(likeRequest:failedWithError:) withObject:self withObject:theError];
    }

    [super failWithError:theError];
}

@end

