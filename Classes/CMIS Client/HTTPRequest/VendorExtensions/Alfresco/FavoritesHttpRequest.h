//
//  FavoritesHttpRequest.h
//  FreshDocs
//
//  Created by Mohamad Saeedi on 01/08/2012.
//  Copyright (c) 2012 . All rights reserved.
//

#import "BaseHTTPRequest.h"

@interface FavoritesHttpRequest : BaseHTTPRequest

{
@private
    NSArray *favorites;
}

@property (nonatomic, retain) NSArray *favorites;

// GET /alfresco/service/api/people/{username}/preferences?pf=org.alfresco.share.sites
+ (id)httpRequestFavoritesWithAccountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID;


@end

