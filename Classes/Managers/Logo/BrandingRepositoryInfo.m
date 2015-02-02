//
//  BrandingRepositoryInfo.m
//  FreshDocs
//
//  Created by  Tim Lei on 12/19/14.
//
//

#import "BrandingRepositoryInfo.h"
#import "RepositoryInfo.h"

NSString * const  kBrandingRepositoryId = @"BrandingRepositoryId";
NSString * const  kBrandingAccountUUID = @"BrandingAccountUUID";
NSString * const  kBrandingLatestChangeLogToken = @"BrandingLatestChangeLogToken";
NSString * const  kBrandingLatestUpdateDate = @"BrandingLatestUpdateDate";

@implementation BrandingRepositoryInfo
@synthesize repositoryId = _repositoryId;
@synthesize accountUUID = _accountUUID;
@synthesize latestChangeLogToken = _latestChangeLogToken;
@synthesize latestUpdatedDate = _latestUpdatedDate;

- (id) initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _repositoryId = [aDecoder decodeObjectForKey:kBrandingRepositoryId];
        _accountUUID = [aDecoder decodeObjectForKey:kBrandingAccountUUID];
        _latestChangeLogToken = [aDecoder decodeObjectForKey:kBrandingLatestChangeLogToken];
        _latestUpdatedDate = [aDecoder decodeObjectForKey:kBrandingLatestUpdateDate];
    }
    
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_repositoryId forKey:kBrandingRepositoryId];
    [aCoder encodeObject:_accountUUID forKey:kBrandingAccountUUID];
    [aCoder encodeObject:_latestChangeLogToken forKey:kBrandingLatestChangeLogToken];
    [aCoder encodeObject:_latestUpdatedDate forKey:kBrandingLatestUpdateDate];
}

+ (BrandingRepositoryInfo*) brandingRepositoryInfoWithInfo:(RepositoryInfo*) repoInfo {
    BrandingRepositoryInfo *newRepoInfo = [[BrandingRepositoryInfo alloc] init];
    
    [newRepoInfo setRepositoryId:repoInfo.repositoryId];
    [newRepoInfo setAccountUUID:repoInfo.accountUuid];
    [newRepoInfo setLatestChangeLogToken:repoInfo.latestChangeLogToken];
    [newRepoInfo setLatestUpdatedDate:[NSDate date]];
    
    return newRepoInfo;
}
@end
