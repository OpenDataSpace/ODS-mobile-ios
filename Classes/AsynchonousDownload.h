//
//  ***** BEGIN LICENSE BLOCK *****
//  Version: MPL 1.1
//
//  The contents of this file are subject to the Mozilla Public License Version
//  1.1 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS" basis,
//  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
//  for the specific language governing rights and limitations under the
//  License.
//
//  The Original Code is the Alfresco Mobile App.
//  The Initial Developer of the Original Code is Zia Consulting, Inc.
//  Portions created by the Initial Developer are Copyright (C) 2011
//  the Initial Developer. All Rights Reserved.
//
//
//  ***** END LICENSE BLOCK *****
//
//
//  AsynchonousDownload.h
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
