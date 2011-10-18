//
//  RepositoryServices.h
//  FreshDocs
//
//  Created by Gi Hyun Lee on 9/15/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RepositoryInfo.h"

extern NSString * const kAlfrescoRepositoryVendorName;
extern NSString * const kIBMRepositoryVendorName;
extern NSString * const kMicrosoftVendorName;


@interface RepositoryServices : NSObject {
@private
	NSMutableDictionary *repositories;
	RepositoryInfo *currentRepositoryInfo;
}
@property (nonatomic, readonly) NSArray *repositories;
@property (nonatomic, retain) RepositoryInfo *currentRepositoryInfo;

- (void)addRepositoryInfo:(RepositoryInfo *)repositoryInfo forRepositoryId:(NSString *)repositoryId;

// Repository Services methods
- (RepositoryInfo *)getRepositoryInfoByRepositoryId:(NSString *)repositoryId makeCurrent:(BOOL)makeCurrent;

// Utility Methods
- (BOOL)isCurrentRepositoryVendorNameEqualTo:(NSString *)testVendorName;

+ (id)shared;
@end
