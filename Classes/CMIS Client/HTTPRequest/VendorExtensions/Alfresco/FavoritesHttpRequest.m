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
//  FavoritesHttpRequest.m
//

#import "FavoritesHttpRequest.h"
#import "ASIHttpRequest+Alfresco.h"

@interface FavoritesHttpRequest (private)
-(NSDictionary *)favoritesNode:(NSDictionary *)responseJson;
@end

@implementation FavoritesHttpRequest

- (void)dealloc
{
    [_favorites release];
    [super dealloc];
}

#pragma mark - ASIHttpRequestDelegate Methods

- (void)requestFinishedWithSuccessResponse
{
    NSString *favoriteNodes = [[self dictionaryFromJSONResponse] valueForKeyPath:@"org.alfresco.share.documents.favourites"];
    self.favorites = [favoriteNodes componentsSeparatedByString:@","];
}

// GET /alfresco/service/api/people/{username}/preferences?pf=org.alfresco.share.sites
+ (id)httpRequestFavoritesWithAccountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
    FavoritesHttpRequest *request = [FavoritesHttpRequest requestForServerAPI:kServerAPIFavorites accountUUID:uuid tenantID:aTenantID];
    [request setRequestMethod:@"GET"];
    return request;
}

+ (id)httpRequestSetFavoritesWithAccountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID newFavoritesList:(NSString *)favorites
{
    NSDictionary *favoritesDictionary = [NSDictionary dictionaryWithObject:
                                         [NSDictionary dictionaryWithObject:
                                          [NSDictionary dictionaryWithObject:
                                           [NSDictionary dictionaryWithObject:
                                            [NSDictionary dictionaryWithObject:
                                             favorites forKey:@"favourites"]
                                                                       forKey:@"documents"]
                                                                      forKey:@"share"]
                                                                     forKey:@"alfresco"]
                                                                    forKey:@"org"];

    FavoritesHttpRequest *request = [FavoritesHttpRequest requestForServerAPI:kServerAPIFavorites accountUUID:uuid tenantID:aTenantID];
    [request setRequestMethod:@"POST"];
    [request addRequestHeader:@"Content-Type" value:@"application/json"];
    [request setPostBody:[request mutableDataFromJSONObject:favoritesDictionary]];
    [request setContentLength:[request.postBody length]];
    
    return request;
}

@end

