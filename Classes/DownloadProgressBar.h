//
//  DownloadProgressBar.h
//  Alfresco
//
//  Created by Michael Muller on 10/14/09.
//  Copyright 2009 Zia Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DownloadProgressBar;

@protocol DownloadProgressBarDelegate

- (void)download:(DownloadProgressBar *)down completeWithData:(NSData *)data;

@end

// apparently, by convention, you don't retain delegates: 
//   http://www.cocoadev.com/index.pl?DelegationAndNotification

@interface DownloadProgressBar : NSObject {
	NSMutableData *fileData;
	NSNumber *totalFileSize;
	UIAlertView *progressAlert;
	UIProgressView *progressView;
	id <DownloadProgressBarDelegate> delegate;
	NSString *filename;
	BOOL isBase64Encoded;
    NSString *cmisObjectId;
    NSString *cmisContentStreamMimeType;
}

@property (nonatomic, retain) NSMutableData *fileData;
@property (nonatomic, retain) NSNumber *totalFileSize;
@property (nonatomic, retain) UIAlertView *progressAlert;
@property (nonatomic, retain) UIProgressView *progressView;
@property (nonatomic, assign) id <DownloadProgressBarDelegate> delegate;
@property (nonatomic, retain) NSString *filename;
@property (nonatomic, retain) NSString *cmisObjectId;
@property (nonatomic, retain) NSString *cmisContentStreamMimeType;

+ (DownloadProgressBar *)createAndStartWithURL:(NSURL*)url delegate:(id <DownloadProgressBarDelegate>)del message:(NSString *)msg filename:(NSString *)filename;
+ (DownloadProgressBar *)createAndStartWithURL:(NSURL*)url delegate:(id <DownloadProgressBarDelegate>)del message:(NSString *)msg filename:(NSString *)filename contentLength:(NSNumber *)contentLength;

@end
