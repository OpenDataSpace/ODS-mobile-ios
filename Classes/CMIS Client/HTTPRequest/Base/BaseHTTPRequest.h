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
#import "PasswordPromptViewController.h"

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



@interface BaseHTTPRequest : ASIHTTPRequest <PasswordPromptDelegate>
{
@private
    BOOL show500StatusError;
    BOOL suppressAllErrors;
    
    NSString *serverAPI;
    NSString *accountUUID;
    AccountInfo *accountInfo;
    NSString *tenantID;
    PasswordPromptViewController *passwordPrompt;
    UIViewController *presentingController;
    SEL willPromptPasswordSelector;
    SEL finishedPromptPasswordSelector;
}
@property (nonatomic, assign) BOOL show500StatusError;
@property (nonatomic, assign) BOOL suppressAllErrors;
@property (nonatomic, retain) NSString *serverAPI;
@property (nonatomic, retain) NSString *accountUUID;
@property (nonatomic, retain) AccountInfo *accountInfo;
@property (nonatomic, retain) NSString *tenantID;
@property (nonatomic, retain) PasswordPromptViewController *passwordPrompt;
@property (nonatomic, retain) UIViewController *presentingController;
@property (nonatomic, assign) SEL willPromptPasswordSelector;
@property (nonatomic, assign) SEL finishedPromptPasswordSelector;

+ (id)requestForServerAPI:(NSString *)apiKey accountUUID:(NSString *)uuid;
+ (id)requestForServerAPI:(NSString *)apiKey accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID;
+ (id)requestForServerAPI:(NSString *)apiKey accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID infoDictionary:(NSDictionary *)infoDictionary;

+ (id)requestWithURL:(NSURL *)newURL accountUUID:(NSString *)uuid;
- (id)initWithURL:(NSURL *)newURL accountUUID:(NSString *)uuid;

- (BOOL)responseSuccessful;

// All subclasses of BaseHTTPResponse should implement the following method
- (void)requestFinishedWithSuccessResponse;

// Utility method to determine a password for an account
- (NSString *)passwordForAccount:(AccountInfo *)anAccountInfo;
@end
