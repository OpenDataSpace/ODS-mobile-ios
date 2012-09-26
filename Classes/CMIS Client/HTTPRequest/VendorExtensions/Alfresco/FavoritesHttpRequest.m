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
#import "ASIHTTPRequest+Utils.h"
#import "ASIHttpRequest+Alfresco.h"
#import "Utility.h"
#import "SBJSON.h"
#import "AccountInfo.h"
#import "AccountManager.h"

@interface FavoritesHttpRequest (private)
-(NSDictionary *)favoritesNode:(NSDictionary *)responseJson;
@end


@implementation FavoritesHttpRequest
@synthesize favorites;
@synthesize requestType = _requestType;


- (void)dealloc
{
    [super dealloc];
    [favorites release];
}

#pragma mark -
#pragma mark ASIHttpRequestDelegate Methods

- (void)requestFinishedWithSuccessResponse
{
    //NSLog(@"Favorites Documents Request Finished: %@", [self responseString]);
    
    SBJSON *jsonObj = [SBJSON new];
    NSDictionary *result = [jsonObj objectWithString:[self responseString]];
    NSDictionary *favoritesNode = [self favoritesNode:result];
    NSMutableArray *requestFavorites = [NSMutableArray array];
    
    if(requestFavorites && [favoritesNode isKindOfClass:[NSString class]])
    {
        requestFavorites = [[[(NSString*)favoritesNode componentsSeparatedByString:@","] mutableCopy] autorelease];
    }
    [jsonObj release];
    
    self.favorites = requestFavorites;
}

- (NSDictionary *)favoritesNode:(NSDictionary *)responseJson
{
    NSArray *path = [NSArray arrayWithObjects:@"org",@"alfresco",@"share",@"documents",@"favourites", nil];
    NSDictionary *favoritesNode = responseJson;
    
    for(NSString *nextPath in path)
    {
        favoritesNode = [favoritesNode objectForKey:nextPath];
        
        // No favorites node, no need to continue searching
        if(favoritesNode == nil)
        {
            break;
        }
    }
    
    return favoritesNode;
}

- (void)failWithError:(NSError *)theError
{
    if (theError)
    {
        NSLog(@"Activities HTTP Request Failure: %@", theError);
    }
    
    [super failWithError:theError];
}

// GET /alfresco/service/api/people/{username}/preferences?pf=org.alfresco.share.sites
+ (id)httpRequestFavoritesWithAccountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
    if([[AccountManager sharedManager] isAccountActive:uuid])
    {
        FavoritesHttpRequest *request = [FavoritesHttpRequest requestForServerAPI:kServerAPIFavorites accountUUID:uuid tenantID:aTenantID];
        [request setRequestMethod:@"GET"];
        return request;
    }
    return nil;
}

+ (id)httpRequestSetFavoritesWithAccountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID newFavoritesList:(NSString *)newList
{
    if([[AccountManager sharedManager] isAccountActive:uuid])
    {
        NSString * jsonString = [self makeJsonRepresentation:newList];
        
        FavoritesHttpRequest *request = [FavoritesHttpRequest requestForServerAPI:kServerAPIFavorites accountUUID:uuid tenantID:aTenantID];
        [request setRequestMethod:@"POST"];
        [request addRequestHeader:@"Content-Type" value:@"application/json"];
        
        [request setPostBody:[NSMutableData dataWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]]];
        [request setContentLength:[jsonString length]];
        
        return request;
    }
    return nil;
}

+ (NSString *) makeJsonRepresentation:(NSString *) favorites
{
    NSDictionary * favoritesDictionary = [NSDictionary dictionaryWithObject:
                                          [NSDictionary dictionaryWithObject:
                                           [NSDictionary dictionaryWithObject:
                                            [NSDictionary dictionaryWithObject:
                                             [NSDictionary dictionaryWithObject:
                                              favorites forKey:@"favourites"] 
                                                                        forKey:@"documents"] 
                                                                       forKey:@"share"] 
                                                                      forKey:@"alfresco"] 
                                                                     forKey:@"org"];
    
    SBJSON *jsonObj = [SBJSON new];
    
    NSString * favoritesJSONString = [jsonObj stringWithObject:favoritesDictionary];
    
    [jsonObj release];
    
    return favoritesJSONString;
}


@end

