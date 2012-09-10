//
//  ReadUnreadManager.h
//  FreshDocs
//
//  Created by Tijs Rademakers on 10/09/2012.
//  Copyright (c) 2012 U001b. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ReadUnreadManager : NSObject

- (BOOL)readStatusForTaskId:(NSString *)taskId;

- (void)saveReadStatus:(BOOL)readStatus taskId:(NSString *)taskId;

- (void)removeReadStatusForTaskId:(NSString *)taskId;

/*
 Persistes the current account status cache into the datastore
 */
- (void)synchronize;

/*
 Shared manager instance for the ReadUnreadManager class
 */
+ (ReadUnreadManager *)sharedManager;

@end
