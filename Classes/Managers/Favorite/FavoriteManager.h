//
//  FavoriteManager.h
//  FreshDocs
//
//  Created by Mohamad Saeedi on 01/08/2012.
//  Copyright (c) 2012 . All rights reserved.
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

