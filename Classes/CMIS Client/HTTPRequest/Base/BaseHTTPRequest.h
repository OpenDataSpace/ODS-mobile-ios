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
//  BaseHTTPRequest.h
//
// Provides standard bahaviour for an error code in the headers and a base for the ASIHTTPRequest descendants
//

#import "ASIHTTPRequest+Utils.h"
#import "AccountInfo.h"

extern NSString * const kServerAPISiteCollection;
    //  $PROTOCOL://$HOSTNAME:$PORT/$WEBAPP/$SERVICE/api/sites?format=json
extern NSString * const kServerAPISearchURL;
    //  $PROTOCOL://$HOSTNAME:$PORT/$WEBAPP/$SERVICE/search/keyword.atom?
extern NSString * const kServerAPICMISServiceInfo;
    //  $PROTOCOL://$HOSTNAME:$PORT/$WEBAPP/$SERVICE/cmis
extern NSString * const kServerAPINode;
    //  $PROTOCOL://$HOSTNAME:$PORT/$WEBAPP/$SERVICE/api/node/workspace/SpacesStore/
extern NSString * const kServerAPIActivitiesUserFeed;
    //  $PROTOCOL://$HOSTNAME:$PORT/$WEBAPP/$SERVICE/api/activities/feed/user?format=json
extern NSString * const kServerAPIFavorites;
    // $PROTOCOL://$HOSTNAME:$PORT/$WEBAPP/$SERVICE/api/people/@USERNAME/preferences?pf=org.alfresco.share.documents
extern NSString * const kServerAPIComments;
    //  $PROTOCOL://$HOSTNAME:$PORT/$WEBAPP/$SERVICE/api/node/$STORETYPE/$STOREID/$ID/comments
extern NSString * const kServerAPIRatings;
    //  $PROTOCOL://$HOSTNAME:$PORT/$WEBAPP/$SERVICE/api/node/$STORETYPE/$STOREID/$ID/ratings
extern NSString * const kServerAPITagCollection;
    //  $PROTOCOL://$HOSTNAME:$PORT/$WEBAPP/$SERVICE/api/tag/$STORETYPE/$STOREID
extern NSString * const kServerAPIListAllTags;
    //  $PROTOCOL://$HOSTNAME:$PORT/$WEBAPP/$SERVICE/api/tags/$STORETYPE/$STOREID
extern NSString * const kServerAPINodeTagCollection;
    //  $PROTOCOL://$HOSTNAME:$PORT/$WEBAPP/$SERVICE/api/node/$STORETYPE/$STOREID/$ID/tags
extern NSString * const kServerAPIUserPreferenceSet;
    //  $PROTOCOL://$HOSTNAME:$PORT/$WEBAPP/$SERVICE/api/people/@USERNAME/preferences?pf=org.alfresco.share.sites
extern NSString * const kServerAPIPersonsSiteCollection;
    //  $PROTOCOL://$HOSTNAME:$PORT/$WEBAPP/$SERVICE/api/people/$USERNAME/sites
extern NSString * const kServerAPINetworksCollection;
    // $PROTOCOL://$HOSTNAME:$PORT/$ALFRESCO/a/-default-/internal/cloud/user/$USERNAME/accounts
extern NSString * const kServerAPICloudSignup;
    // $PROTOCOL://$HOSTNAME:$PORT/$WEBAPP/$SERVICE/internal/cloud/accounts/signupqueue
extern NSString * const kServerAPICloudAccountStatus;
    // $PROTOCOL://$HOSTNAME:$PORT/$WEBAPP/$SERVICE/internal/cloud/accounts/signupqueue/$ACCOUNTID?key=$ACCOUNTKEY
extern NSString * const kServerAPIActionService;
    // $PROTOCOL://$HOSTNAME:$PORT/$WEBAPP/$SERVICE/api/actionQueue?async=$ASYNC
extern NSString * const kServerAPITaskCollection;
    // $PROTOCOL://$HOSTNAME:$PORT/$WEBAPP/$SERVICE/api/task-instances
extern NSString * const kServerAPITaskItemCollection;
    // $PROTOCOL://$HOSTNAME:$PORT/$WEBAPP/$SERVICE/api/formdefinitions
extern NSString * const kServerAPITaskItemDetailsCollection;
    // $PROTOCOL://$HOSTNAME:$PORT/$WEBAPP/$SERVICE/api/forms/picker/items
extern NSString * const kServerAPITaskCreate;
    // $PROTOCOL://$HOSTNAME:$PORT/$WEBAPP/$SERVICE/api/workflow-instances
extern NSString * const kServerAPIPersonAvatar;
    // $PROTOCOL://$HOSTNAME:$PORT/$WEBAPP/$SERVICE/slingshot/profile/avatar/$USERID
extern NSString * const kServerAPINodeThumbnail;
    // $PROTOCOL://$HOSTNAME:$PORT/$WEBAPP/$SERVICE/api/node/$STORETYPE/$STOREID/$ID/content/thumbnails/doclib
extern NSString * const kServerAPIPeopleCollection;
    // $PROTOCOL://$HOSTNAME:$PORT/$WEBAPP/$SERVICE/api/people?filter=$PEOPLEFILTER
extern NSString * const kServerAPIPersonNodeRef;
    // $PROTOCOL://$HOSTNAME:$PORT/$WEBAPP/$SERVICE/api/forms/picker/authority/children?selectableType=cm:person&searchTerm=$PERSON&size=1


@interface BaseHTTPRequest : ASIHTTPRequest
{
    BOOL hasPresentedPrompt;
}

@property (nonatomic, assign) BOOL show500StatusError;
@property (nonatomic, assign) BOOL suppressAllErrors;
@property (nonatomic, retain) NSString *serverAPI;
@property (nonatomic, retain) NSString *accountUUID;
@property (nonatomic, retain) AccountInfo *accountInfo;
@property (nonatomic, retain) NSString *tenantID;
@property (nonatomic, assign) SEL willPromptPasswordSelector;
@property (nonatomic, assign) SEL finishedPromptPasswordSelector;
@property (nonatomic, assign) SEL cancelledPromptPasswordSelector;
@property (nonatomic, assign) UIViewController *passwordPromptPresenter;
@property (nonatomic, assign) id promptPasswordDelegate;

+ (id)requestForServerAPI:(NSString *)apiKey accountUUID:(NSString *)uuid;
+ (id)requestForServerAPI:(NSString *)apiKey accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID;
+ (id)requestForServerAPI:(NSString *)apiKey accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID infoDictionary:(NSDictionary *)infoDictionary;
+ (id)requestForServerAPI:(NSString *)apiKey accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID infoDictionary:(NSDictionary *)infoDictionary useAuthentication:(BOOL)useAuthentication;

+ (id)requestWithURL:(NSURL *)newURL accountUUID:(NSString *)uuid;
+ (id)requestWithURL:(NSURL *)newURL accountUUID:(NSString *)uuid useAuthentication:(BOOL)useAuthentication;
- (id)initWithURL:(NSURL *)newURL accountUUID:(NSString *)uuid;
- (id)initWithURL:(NSURL *)newURL accountUUID:(NSString *)uuid useAuthentication:(BOOL)useAuthentication;

- (BOOL)responseSuccessful;

// All subclasses of BaseHTTPResponse should implement the following method
- (void)requestFinishedWithSuccessResponse;

// Utility method to clear any pending password prompts
+ (void)clearPasswordPromptQueue;

// Utility method to determine a password for an account
+ (NSString *)passwordForAccount:(AccountInfo *)anAccountInfo;
@end
