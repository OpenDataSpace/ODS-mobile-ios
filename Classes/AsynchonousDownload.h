//
//  AsynchonousDownload.h
//  Alfresco
//
//  Created by Michael Muller on 10/16/09.
//  Copyright 2009 Zia Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBProgressHUD.h"

extern NSString * const NSHTTPPropertyStatusCodeKey;

@class AsynchonousDownload;

@protocol AsynchronousDownloadDelegate
- (void) asyncDownloadDidComplete:(AsynchonousDownload *)async;
- (void) asyncDownload:(AsynchonousDownload *)async didFailWithError:(NSError *)error;
@end

@interface AsynchonousDownload : NSObject {
	NSMutableData *data;
	NSURL *url;
	id <AsynchronousDownloadDelegate> delegate; 
	NSURLConnection *urlConnection;
    BOOL show500StatusError;
    int responseStatusCode;
@private
	MBProgressHUD *HUD;
}

@property (nonatomic, retain) NSMutableData *data;
@property (nonatomic, retain) NSURL *url;
@property (nonatomic, assign) id <AsynchronousDownloadDelegate> delegate; // apparently, by convention, you don't retain delegates: http://www.cocoadev.com/index.pl?DelegationAndNotification
@property (nonatomic, retain) NSURLConnection *urlConnection;
@property (nonatomic, assign) BOOL show500StatusError;
@property (nonatomic, readonly) int responseStatusCode;
@property (nonatomic, assign) MBProgressHUD *HUD;

- (id)initWithURL:(NSURL *)u delegate:(id <AsynchronousDownloadDelegate>)del;
- (void)start;
- (void)restart;
- (void)cancel;

- (void)createAndShowHUD;
- (void)hideHUD;

@end
