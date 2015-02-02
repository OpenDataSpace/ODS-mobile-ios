//
//  LogoItem.h
//  FreshDocs
//
//  Created by  Tim Lei on 12/16/14.
//
//

#import <Foundation/Foundation.h>

@class RepositoryItem;

@interface LogoItem : NSObject <NSCoding>
@property (nonatomic, copy) NSString    *accountUUID;
@property (nonatomic, copy) NSString    *fileName;
@property (nonatomic, copy) NSString    *urlString;
@property (nonatomic, copy) NSString    *changeToken;
@property (nonatomic, copy) NSString    *lastModifiedDate;
@property (nonatomic, strong) UIImage   *logoImage;

+ (id) logoItemWithAccountUUID:(NSString*) acctUUID repositoryItem:(RepositoryItem*) repoItem;

/* Icon url */
- (NSURL *) logoURL;
@end
