//
//  CMISFavoriteDocsHTTPRequest.h
//  FreshDocs
//
//  Created by Mohamad Saeedi on 01/08/2012.
//  Copyright (c) 2012 . All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CMISQueryHTTPRequest.h"
@class RepositoryItemsParser;


@interface CMISFavoriteDocsHTTPRequest : CMISQueryHTTPRequest
{
    @private
    NSString *folderObjectId;
}
@property (nonatomic, readonly) NSString *folderObjectId;

- (id)initWithSearchPattern:(NSString *)pattern accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID;
- (id)initWithSearchPattern:(NSString *)pattern folderObjectId:(NSString *)objectId accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID;

@end
