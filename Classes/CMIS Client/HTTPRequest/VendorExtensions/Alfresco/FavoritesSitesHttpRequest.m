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
//  FavoritesSitesHttpRequest.m
//

#import "FavoritesSitesHttpRequest.h"

@implementation FavoritesSitesHttpRequest
@synthesize favoriteSites = _favoriteSites;

- (void)dealloc
{
    [_favoriteSites release];
    [super dealloc];
}

#pragma mark - ASIHttpRequestDelegate Methods

- (void)requestFinishedWithSuccessResponse
{
    AlfrescoLogTrace(@"Favorites Sites Request Finished: %@", [self responseString]);
    
    NSDictionary *favoritesNode = [[self dictionaryFromJSONResponse] valueForKeyPath:@"org.alfresco.share.sites.favourites"];
    NSMutableArray *requestFavoriteSites = [NSMutableArray array];
    
    for (NSString *key in favoritesNode)
    {
        id value = [favoritesNode objectForKey:key];
        if ([value boolValue] == YES)
        {
            [requestFavoriteSites addObject:key];
        }
    }
    
    self.favoriteSites = [NSArray arrayWithArray:requestFavoriteSites];
}

- (void)failWithError:(NSError *)theError
{
    if (theError)
    {
        AlfrescoLogDebug(@"FavoriteSites HTTP Request Failure: %@", theError);
    }
    
    [super failWithError:theError];
}

// GET /alfresco/service/api/people/{username}/preferences?pf=org.alfresco.share.sites
+ (id)httpRequestFavoriteSitesWithAccountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
    FavoritesSitesHttpRequest *request = [FavoritesSitesHttpRequest requestForServerAPI:kServerAPIUserPreferenceSet accountUUID:uuid tenantID:aTenantID];
    [request setRequestMethod:@"GET"];
    return request;
}

// POST /alfresco/service/api/people/{username}/preferences?pf=org.alfresco.share.sites
+ (id)httpAddFavoriteSite:(NSString *)siteName withAccountUUID:(NSString *)accountUUID tenantID:(NSString *)tenantID
{
    return [self httpPostFavoriteSite:siteName isFavorite:YES withAccountUUID:accountUUID tenantID:tenantID];
}

// POST /alfresco/service/api/people/{username}/preferences?pf=org.alfresco.share.sites
+ (id)httpRemoveFavoriteSite:(NSString *)siteName withAccountUUID:(NSString *)accountUUID tenantID:(NSString *)tenantID
{
    return [self httpPostFavoriteSite:siteName isFavorite:NO withAccountUUID:accountUUID tenantID:tenantID];
}

// Private
+ (id)httpPostFavoriteSite:(NSString *)siteName isFavorite:(BOOL)favorite withAccountUUID:(NSString *)accountUUID tenantID:(NSString *)tenantID
{
    NSDictionary *jsonObject = [NSDictionary dictionaryWithObject:
                                [NSDictionary dictionaryWithObject:
                                 [NSDictionary dictionaryWithObject:
                                  [NSDictionary dictionaryWithObject:
                                   [NSDictionary dictionaryWithObject:
                                    [NSDictionary dictionaryWithObject:
                                     [NSNumber numberWithBool:favorite]
                                                                forKey:siteName]
                                                               forKey:@"favourites"]
                                                              forKey:@"sites"]
                                                             forKey:@"share"]
                                                            forKey:@"alfresco"]
                                                           forKey:@"org"];

    FavoritesSitesHttpRequest *request = [FavoritesSitesHttpRequest requestForServerAPI:kServerAPIUserPreferenceSet accountUUID:accountUUID tenantID:tenantID];
    [request setRequestMethod:@"POST"];
    [request addRequestHeader:@"Content-Type" value:@"application/json"];
    [request setPostBody:[request mutableDataFromJSONObject:jsonObject]];
    [request setContentLength:[request.postBody length]];
    return request;
}

@end
