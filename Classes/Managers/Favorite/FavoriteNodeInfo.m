//
//  FavoriteNodeInfo.m
//  FreshDocs
//
//  Created by Mohamad Saeedi on 01/08/2012.
//  Copyright (c) 2012 . All rights reserved.
//

#import "FavoriteNodeInfo.h"

@implementation FavoriteNodeInfo
@synthesize accountUUID = _accountUUID;
@synthesize tenantID = _tenantID;
@synthesize objectNode = _objectNode;

-(id) initWithNode:(NSString*)node accountUUID:(NSString*)uuid tenantID:(NSString*)tenant
{
    self = [super init];
    
    if(self != nil)
    {
        self.objectNode = node;
        self.accountUUID = uuid;
        self.tenantID = tenant;
    }
    
    return self;
}

@end
