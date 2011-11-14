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
//  FavoritesSitesHttpRequest.m
//

#import "FavoritesSitesHttpRequest.h"
#import "ASIHTTPRequest+Utils.h"
#import "ASIHttpRequest+Alfresco.h"
#import "Utility.h"
#import "SBJSON.h"

@interface FavoritesSitesHttpRequest (private)
-(NSDictionary *)favoritesNode:(NSDictionary *)responseJson;
@end

@implementation FavoritesSitesHttpRequest
@synthesize favoriteSites;

-(void)dealloc {
    [super dealloc];
    [favoriteSites release];
}

#pragma mark -
#pragma mark ASIHttpRequestDelegate Methods

- (void)requestFinished
{
    NSLog(@"Favorites Sites Request Finished: %@", [self responseString]);
    //	Check that we are valid
	if (![self responseSuccessful]) {
		// FIXME: Recode domain, code and userInfo.  Use ASI as an example but do for CMIS errors
		// !!!: Make sure to cleanup because we are in an error
		
		[self failWithError:[NSError errorWithDomain:CMISNetworkRequestErrorDomain 
												code:ASIUnhandledExceptionError userInfo:nil]];
        return;
	} else {
        SBJSON *jsonObj = [SBJSON new];
        NSDictionary *result = [jsonObj objectWithString:[self responseString]];
        NSDictionary *favoritesNode = [self favoritesNode:result];
        NSMutableArray *requestFavortieSites = [NSMutableArray array];
        
        if(requestFavortieSites) {
            for(NSString *key in favoritesNode) {
                id value = [favoritesNode objectForKey:key];
                if([value boolValue] == YES) {
                    [requestFavortieSites addObject:key];
                }
            }
        }
        [jsonObj release];
        
        self.favoriteSites = [NSArray arrayWithArray:requestFavortieSites];
    }
    
    // FIXME/TODO Parse resulting tags here.
    
    [super requestFinished];
}

-(NSDictionary *)favoritesNode:(NSDictionary *)responseJson {
    NSArray *path = [NSArray arrayWithObjects:@"org",@"alfresco",@"share",@"sites",@"favourites", nil];
    NSDictionary *favoritesNode = responseJson;
    
    for(NSString *nextPath in path) {
        favoritesNode = [favoritesNode objectForKey:nextPath];
        
        //No favorites node, no need to continue searching
        if(favoritesNode == nil) {
            break;
        }
    }
    
    return favoritesNode;
}

- (void)failWithError:(NSError *)theError
{
    if (theError)
        NSLog(@"Activities HTTP Request Failure: %@", theError);
    
    [super failWithError:theError];
}

// GET /alfresco/service/api/people/{username}/preferences?pf=org.alfresco.share.sites
+ (id)httpRequestFavoriteSites {
    NSString  *urlString = [[self alfrescoRepositoryBaseServiceUrlString] stringByAppendingFormat:@"/api/people/%@/preferences?pf=org.alfresco.share.sites", userPrefUsername()];
    NSLog(@"List All Favorite sites\r\nGET:\t%@", urlString);
    FavoritesSitesHttpRequest *request = [FavoritesSitesHttpRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setRequestMethod:@"GET"];
    [request addBasicAuthHeader];
    return request;
}

@end
