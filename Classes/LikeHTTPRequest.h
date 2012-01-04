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
//  LikeHTTPRequest.h
//

#import "BaseHTTPRequest.h"
#import "NodeRef.h"

#define kLike_GET_Request 0
#define kLike_POST_Request 1
#define kLike_DELETE_Request 2
#define kLike_RatingServiceDefined_Request 3

#define kLike_YES_Str @"yes"
#define kLike_No_Str @"no"

@class LikeHTTPRequest;

@protocol LikeHTTPRequestDelegate <NSObject>
@optional
- (void)likeRequest:(LikeHTTPRequest *)request likeRatingServiceDefined:(NSString *)isDefined;
- (void)likeRequest:(LikeHTTPRequest *)request documentIsLiked:(NSString *)isLiked;
- (void)likeRequest:(LikeHTTPRequest *)request likeDocumentSuccess:(NSString *)isLiked;
- (void)likeRequest:(LikeHTTPRequest *)request unlikeDocumentSuccess:(NSString *)isUnliked;
- (void)likeRequest:(LikeHTTPRequest *)request failedWithError:(NSError *)theError;

@end

@interface LikeHTTPRequest : BaseHTTPRequest
{
    id<LikeHTTPRequestDelegate> likeDelegate;
    
    NodeRef *nodeRef;
}
@property (nonatomic, assign) id<LikeHTTPRequestDelegate> likeDelegate;
@property (nonatomic, retain) NodeRef *nodeRef;


+ (id)ratingsServiceHTTPDefinitionRequestWithAccountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID; 
+ (id)getHTTPRequestForNodeRef:(NodeRef *)aNodeRef accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID;
+ (id)postHTTPRequestForNodeRef:(NodeRef *)aNodeRef accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID;
+ (id)deleteHTTPRequest:(NodeRef *)aNodeRef accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID;

@end
