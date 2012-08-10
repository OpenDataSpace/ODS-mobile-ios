//
//  FavoriteNodeInfo.h
//  FreshDocs
//
//  Created by Mohamad Saeedi on 01/08/2012.
//  Copyright (c) 2012 . All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FavoriteNodeInfo : NSObject


@property (nonatomic, retain) NSString *accountUUID;
@property (nonatomic, retain) NSString *tenantID;

@property (nonatomic, retain) NSString *objectNode;

-(id) initWithNode:(NSString*)node accountUUID:(NSString*)uuid tenantID:(NSString*)tenant;

@end
