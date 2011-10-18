//
//  NodeRef.h
//  FreshDocs
//
//  Created by Gi Hyun Lee on 7/20/11.
//  Copyright 2011 Zia Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NodeRef : NSObject {
@private
    NSString *cmisObjectId;
    NSString *storeType;
    NSString *storeId;
    NSString *objectId;
}
@property (nonatomic, readonly) NSString *cmisObjectId;
@property (nonatomic, readonly) NSString *storeType;
@property (nonatomic, readonly) NSString *storeId;
@property (nonatomic, readonly) NSString *objectId;

- (id)initWithCmisObjectId:(NSString *)theCmisObjectId;
+ (id)nodeRefFromCmisObjectId:(NSString *)theCmisObjectId;

@end
