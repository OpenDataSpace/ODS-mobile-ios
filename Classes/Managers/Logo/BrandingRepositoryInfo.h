//
//  BrandingRepositoryInfo.h
//  FreshDocs
//
//  Created by  Tim Lei on 12/19/14.
//
//

#import <Foundation/Foundation.h>

@class RepositoryInfo;
@interface BrandingRepositoryInfo : NSObject <NSCoding>
@property (nonatomic, copy) NSString        *repositoryId;
@property (nonatomic, copy) NSString        *accountUUID;
@property (nonatomic, copy) NSString        *latestChangeLogToken;
@property (nonatomic, strong) NSDate        *latestUpdatedDate;

+ (BrandingRepositoryInfo*) brandingRepositoryInfoWithInfo:(RepositoryInfo*) repoInfo;
@end
