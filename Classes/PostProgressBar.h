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
//  UploadProgressBar.h
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
