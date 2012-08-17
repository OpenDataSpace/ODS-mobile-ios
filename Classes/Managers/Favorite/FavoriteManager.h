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
//  FavoriteManager.h
//

#import <Foundation/Foundation.h>
#import "FavoritesHttpRequest.h"
#import "ASINetworkQueue.h"
#import "CMISServiceManager.h"
@class FavoriteManager;

extern NSString * const kFavoriteManagerErrorDomain;
extern NSString * const kSavedFavoritesFile;

@protocol FavoriteManagerDelegate <NSObject>

- (void)favoriteManager:(FavoriteManager *)favoriteManager requestFinished:(NSArray *)favorites;
@optional
- (void)favoriteManagerRequestFailed:(FavoriteManager *)favoriteManager;

@end


@interface FavoriteManager : NSObject <CMISServiceManagerListener>
{
    ASINetworkQueue *favoritesQueue;
    NSError *error;
    id<FavoriteManagerDelegate> delegate;

    NSInteger requestCount;
    NSInteger requestsFailed;
    NSInteger requestsFinished;

    BOOL showOfflineAlert;
    BOOL loadedRepositoryInfos;
}

@property (nonatomic, retain) ASINetworkQueue *favoritesQueue;
@property (nonatomic, retain) NSError *error;

@property (nonatomic, assign) id<FavoriteManagerDelegate> delegate;

/**
 * This method will queue and start the activities request for all the configured 
 * accounts.
 */
- (void)startFavoritesRequest;

/**
 * Returns the shared singleton
 */
+ (FavoriteManager *)sharedManager;
@end

