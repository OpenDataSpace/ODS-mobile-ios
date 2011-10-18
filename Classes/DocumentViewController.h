//
//  DocumentViewController.h
//  Alfresco
//
//  Created by Michael Muller on 9/3/09.
//  Copyright 2009 Zia Consulting. All rights reserved.
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
