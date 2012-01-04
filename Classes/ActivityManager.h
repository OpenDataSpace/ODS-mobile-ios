/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Alfresco Mobile App.
 *
 * The Initial Developer of the Original Code is Zia Consulting, Inc.
 * Portions created by the Initial Developer are Copyright (C) 2011
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  ActivityManager.h
//

#import <Foundation/Foundation.h>
#import "ActivitiesHttpRequest.h"
#import "ASINetworkQueue.h"
@class ActivityManager;

extern NSString * const kActivityManagerErrorDomain;

@protocol ActivityManagerDelegate <NSObject>

- (void)activityManager:(ActivityManager *)activityManager requestFinished:(NSArray *)activities;
@optional
- (void)activityManagerRequestFailed:(ActivityManager *)activityManager;

@end

@interface ActivityManager : NSObject {
    ASINetworkQueue *activitiesQueue;
    NSMutableArray *activities;
    NSError *error;
    id<ActivityManagerDelegate> delegate;
    
    NSInteger requestCount;
    NSInteger requestsFailed;
    NSInteger requestsFinished;
    
    BOOL showOfflineAlert;
}

@property (nonatomic, retain) ASINetworkQueue *activitiesQueue;
@property (atomic, readonly) NSMutableArray *activities;
@property (nonatomic, retain) NSError *error;

@property (nonatomic, assign) id<ActivityManagerDelegate> delegate;

- (void)startActivitiesRequest;

+ (ActivityManager *)sharedManager;
@end
