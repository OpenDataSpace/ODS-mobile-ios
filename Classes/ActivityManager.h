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
 * Portions created by the Initial Developer are Copyright (C) 2011-2012
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  ActivityManager.h
//
// Singleton class that unifies the retrieval of all the activities across the multiple
// accounts configured by the user

#import <Foundation/Foundation.h>
#import "ActivitiesHttpRequest.h"
#import "ASINetworkQueue.h"
@class ActivityManager;

extern NSString * const kActivityManagerErrorDomain;

/**
 * As a Delegate, this singleton will report the finish or fail for *all* the activities requests
 * only if all of the activities request fail, the activityManagerRequestFailed: method will be called
 * in the delegate. The failed activities requests will be ignored and a success will be reported.
 */
@protocol ActivityManagerDelegate <NSObject>

- (void)activityManager:(ActivityManager *)activityManager requestFinished:(NSArray *)activities;
@optional
- (void)activityManagerRequestFailed:(ActivityManager *)activityManager;

@end

@interface ActivityManager : NSObject {
    ASINetworkQueue *activitiesQueue;
    NSError *error;
    id<ActivityManagerDelegate> delegate;
    
    NSInteger requestCount;
    NSInteger requestsFailed;
    NSInteger requestsFinished;
    
    BOOL showOfflineAlert;
}

@property (nonatomic, retain) ASINetworkQueue *activitiesQueue;
@property (nonatomic, retain) NSError *error;

@property (nonatomic, assign) id<ActivityManagerDelegate> delegate;

/**
 * This method will queue and start the activities request for all the configured 
 * accounts.
 */
- (void)startActivitiesRequest;

/**
 * Returns the shared singleton
 */
+ (ActivityManager *)sharedManager;
@end
