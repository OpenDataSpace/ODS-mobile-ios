//
//  TaskItemDetailsHTTPRequest.h
//  FreshDocs
//
//  Created by Tijs Rademakers on 14/08/2012.
//  Copyright (c) 2012 U001b. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseHTTPRequest.h"

@interface TaskItemDetailsHTTPRequest : BaseHTTPRequest

@property (nonatomic, readonly, retain) NSArray *taskItems;

+ (TaskItemDetailsHTTPRequest *)taskItemDetailsRequestForItems:(NSArray *)items accountUUID:(NSString *)uuid tenantID:(NSString *)tenantID;

@end
