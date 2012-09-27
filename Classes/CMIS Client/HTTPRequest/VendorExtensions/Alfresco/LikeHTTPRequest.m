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
#import "ASIHTTPRequest+Utils.h"
#import "NodeRef.h"
#import "SBJSON.h"
#import "Utility.h"
#import "AccountManager.h"

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
+ (id)ratingsServiceHTTPDefinitionRequestWithAccountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
    return nil;
}


//  GET  /api/node/{store_type}/{store_id}/{id}/ratings
//  KEYPATH: data.ratings.likesRatingScheme.[rating|appliedBy]
+ (id)getHTTPRequestForNodeRef:(NodeRef *)aNodeRef accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
    NSDictionary *infoDictionary = [NSDictionary dictionaryWithObject:aNodeRef forKey:@"NodeRef"];
    LikeHTTPRequest *request = [LikeHTTPRequest requestForServerAPI:kServerAPIRatings accountUUID:uuid 
                                                           tenantID:aTenantID infoDictionary:infoDictionary];
    [request setTag:kLike_GET_Request];
    [request setNodeRef:aNodeRef];
    [request setRequestMethod:@"GET"];
    [request setShouldContinueWhenAppEntersBackground:YES];
    
    return request;
}

//  POST  /api/node/{store_type}/{store_id}/{id}/ratings
+ (id)postHTTPRequestForNodeRef:(NodeRef *)aNodeRef accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
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
    
    NSDictionary *infoDictionary = [NSDictionary dictionaryWithObject:aNodeRef forKey:@"NodeRef"];
    LikeHTTPRequest *request = [LikeHTTPRequest requestForServerAPI:kServerAPIRatings accountUUID:uuid 
                                                           tenantID:aTenantID infoDictionary:infoDictionary];
    
    [request setTag:kLike_POST_Request];
    [request setNodeRef:aNodeRef];
    
    [request setPostBody:[NSMutableData dataWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]]];
    [request setContentLength:[jsonString length]];
    [request setRequestMethod:@"POST"];
    
    return request;    
}

//  DELETE  /api/node/{store_type}/{store_id}/{id}/ratings/likeRatingsScheme
// {}
+ (id)deleteHTTPRequest:(NodeRef *)aNodeRef accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
    static NSString *likesRatingSchemeURLPathComponent = @"likesRatingScheme";
    
    NSDictionary *infoDictionary = [NSDictionary dictionaryWithObject:aNodeRef forKey:@"NodeRef"];
    LikeHTTPRequest *request = [LikeHTTPRequest requestForServerAPI:kServerAPIRatings accountUUID:uuid 
                                                           tenantID:aTenantID infoDictionary:infoDictionary];
    
    // Update the URL since the ServerAPI only is for the RatingsService
    [request setURL:[[request url] URLByAppendingPathComponent:likesRatingSchemeURLPathComponent]];
    
    [request setTag:kLike_DELETE_Request];
    [request setNodeRef:aNodeRef];
    [request setRequestMethod:@"DELETE"];
    
    return request;
}


#pragma mark -
#pragma Overriden ASIHTTPRequest Delegate Methods

- (void)requestFinishedWithSuccessResponse
{
#if MOBILE_DEBUG
    NSLog(@"LIKE RESPONSE: %@", [self responseString]);
#endif
    
    SBJSON *parser = [SBJSON new];
    id jsonObject = [parser objectWithString:[self responseString]];
    [parser release];
    
    switch ([self tag]) {
        case kLike_GET_Request:
        {
            BOOL isLiked = NO;
            NSString *ratingAppliedBy = [jsonObject valueForKeyPath:@"data.ratings.likesRatingScheme.appliedBy"];
            NSInteger rating = (NSInteger)[[jsonObject valueForKeyPath:@"data.ratings.likesRatingScheme.rating"] intValue];
            if ([ratingAppliedBy isEqualToString:[self.accountInfo username]] && rating > 0)
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

