//
//  LogoServiceRequest.h
//  FreshDocs
//
//  Created by  Tim Lei on 1/6/15.
//
//

#import "BaseHTTPRequest.h"
#import "RepositoryInfo.h"

@interface LogoServiceRequest : BaseHTTPRequest

@property (nonatomic, strong) RepositoryInfo    *confRepositoryInfo;

//+ (id)httpGETRequestForAccountUUID:(NSString *)uuid;
+ (id)httpGETRequestForAccountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID;
@end
