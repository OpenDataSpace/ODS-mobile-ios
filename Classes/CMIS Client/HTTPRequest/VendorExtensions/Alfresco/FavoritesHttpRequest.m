//
//  FavoritesHttpRequest.m
//  FreshDocs
//
//  Created by Mohamad Saeedi on 01/08/2012.
//  Copyright (c) 2012 . All rights reserved.
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

-(void)dealloc {
    [super dealloc];
    [favorites release];
}

#pragma mark -
#pragma mark ASIHttpRequestDelegate Methods

- (void)requestFinishedWithSuccessResponse
{
    NSLog(@"Favorites Documents Request Finished: %@", [self responseString]);
    
    SBJSON *jsonObj = [SBJSON new];
    NSDictionary *result = [jsonObj objectWithString:[self responseString]];
    NSDictionary *favoritesNode = [self favoritesNode:result];
    NSMutableArray *requestFavorties = [NSMutableArray array];
    
    if(requestFavorties && [favoritesNode isKindOfClass:[NSString class]]) {
       
        requestFavorties = [[(NSString*)favoritesNode componentsSeparatedByString:@","] mutableCopy];
    }
    [jsonObj release];
    
    self.favorites = [NSArray arrayWithArray:requestFavorties];
    [requestFavorties release];
     
}

-(NSDictionary *)favoritesNode:(NSDictionary *)responseJson {
    NSArray *path = [NSArray arrayWithObjects:@"org",@"alfresco",@"share",@"documents",@"favourites", nil];
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
+ (id)httpRequestFavoritesWithAccountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
    FavoritesHttpRequest *request = [FavoritesHttpRequest requestForServerAPI:kServerAPIFavorites accountUUID:uuid tenantID:aTenantID];
    [request setRequestMethod:@"GET"];
    return request;
}

@end

