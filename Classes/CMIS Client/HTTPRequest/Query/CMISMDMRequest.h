//
//  CMISMDMRequest.h
//  FreshDocs
//
//  Created by Mohamad Saeedi on 07/01/2013.
//
//

#import <Foundation/Foundation.h>
#import "CMISQueryHTTPRequest.h"

@interface CMISMDMRequest : CMISQueryHTTPRequest
{
@private
    NSString *folderObjectId;
}
@property (nonatomic, readonly) NSString *folderObjectId;

- (id)initWithSearchPattern:(NSString *)pattern accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID;
- (id)initWithSearchPattern:(NSString *)pattern folderObjectId:(NSString *)objectId accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID;


@end
