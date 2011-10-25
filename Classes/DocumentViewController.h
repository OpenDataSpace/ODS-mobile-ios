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
//  DocumentViewController.h
//

#import <UIKit/UIKit.h>

#import "MessageUI/MFMailComposeViewController.h"

@interface DocumentViewController : UIViewController   <MFMailComposeViewControllerDelegate, UIDocumentInteractionControllerDelegate, UIAlertViewDelegate, UIWebViewDelegate> 
{
    NSString *cmisObjectId;
	NSData *fileData;
	NSString *fileName;
    NSString *contentMimeType;
    
	BOOL isFavorite;
	
    IBOutlet UIToolbar *documentToolbar;
	IBOutlet UIBarButtonItem *favoriteButton;
	IBOutlet UIWebView *webView;

	UIDocumentInteractionController *docInteractionController;
}

@property (nonatomic, retain) NSString *cmisObjectId;
@property (nonatomic, retain) NSData *fileData;
@property (nonatomic, retain) NSString *fileName;
@property (nonatomic, retain) NSString *contentMimeType;
@property (nonatomic, assign) BOOL isFavorite;
@property (nonatomic, retain) UIToolbar *documentToolbar;
@property (nonatomic, retain) UIBarButtonItem *favoriteButton;
@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) UIDocumentInteractionController *docInteractionController;

- (UIBarButtonItem *)iconSpacer;
- (IBAction)sendMail;
- (IBAction)addToFavorites;
- (IBAction)actionButtonPressed:(id)sender;
- (IBAction)commentsButtonPressed:(id)sender;
- (void)downloadButtonPressed;
- (void)saveFileLocally;
- (void)trashButtonPressed;

@end
