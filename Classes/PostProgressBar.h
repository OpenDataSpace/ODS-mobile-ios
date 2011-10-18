//
//  UploadProgressBar.h
//  Alfresco
//
//  Created by Bindu Wavell on 4/10/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequestDelegate.h"
#import "ASIProgressDelegate.h"

@class PostProgressBar;

@protocol PostProgressBarDelegate

- (void) post:(PostProgressBar *)bar completeWithData:(NSData *)data;

@end

// apparently, by convention, you don't retain delegates: 
//   http://www.cocoadev.com/index.pl?DelegationAndNotification
@interface PostProgressBar : NSObject <ASIHTTPRequestDelegate, NSXMLParserDelegate, ASIProgressDelegate, UIAlertViewDelegate> {
	NSMutableData *fileData;
	UIAlertView *progressAlert;
    UIProgressView *progressView;
	id <PostProgressBarDelegate> delegate;
    
    BOOL isCmisObjectIdProperty;
    NSString *currentNamespaceUri;
    NSString *currentElementName;
    NSString *cmisObjectId;
    ASIHTTPRequest *currentRequest;
}

@property (nonatomic, retain) NSMutableData *fileData;
@property (nonatomic, retain) UIAlertView *progressAlert;
@property (nonatomic, retain) UIProgressView *progressView;
@property (nonatomic, assign) id <PostProgressBarDelegate> delegate;
@property (nonatomic, retain) NSString *cmisObjectId;
@property (nonatomic, retain) ASIHTTPRequest *currentRequest;

+ (PostProgressBar *) createAndStartWithURL:(NSURL*)url andPostBody:(NSString *)body delegate:(id <PostProgressBarDelegate>)del message:(NSString *)msg;

@end
