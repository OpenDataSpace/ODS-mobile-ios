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
//  DocumentViewController.h
//

#import <UIKit/UIKit.h>

#import "MessageUI/MFMailComposeViewController.h"
#import "ToggleBarButtonItemDecorator.h"
#import "DownloadMetadata.h"
#import "LikeHTTPRequest.h"

extern NSString* const PartnerApplicationFileMetadataKey;
extern NSString* const PartnerApplicationDocumentPathKey;

@class CommentsHttpRequest;
@class MBProgressHUD;
@class BarButtonBadge;
@class MPMoviePlayerController;
@class ImageActionSheet;

@interface DocumentViewController : UIViewController   <MFMailComposeViewControllerDelegate, UIDocumentInteractionControllerDelegate, UIAlertViewDelegate, UIWebViewDelegate,UIGestureRecognizerDelegate, UIActionSheetDelegate, LikeHTTPRequestDelegate> 
{
    NSString *cmisObjectId;
	NSData *fileData;
	NSString *fileName;
    NSString *filePath;
    NSString *contentMimeType;
    DownloadMetadata *fileMetadata;
    NSURLRequest *previewRequest;
    
	BOOL isDownloaded;
    IBOutlet UIToolbar *documentToolbar;
	IBOutlet UIBarButtonItem *favoriteButton;
	IBOutlet UIWebView *webView;
    MPMoviePlayerController *videoPlayer;
    ToggleBarButtonItemDecorator *likeBarButton;
	UIDocumentInteractionController *docInteractionController;
    UIBarButtonItem *actionButton;
    ImageActionSheet *_actionSheet;
    UIBarButtonItem *commentButton;
    LikeHTTPRequest *likeRequest;
    CommentsHttpRequest *commentsRequest;
    BOOL showLikeButton;
    BOOL isVersionDocument;
    BOOL presentNewDocumentPopover;
    MBProgressHUD *HUD;
    NSString *selectedAccountUUID;
    NSString *tenantID;
    NSString *repositoryID;
    BOOL blankRequestLoaded;
}

@property (nonatomic, retain) NSString *cmisObjectId;
@property (nonatomic, retain) NSData *fileData;
@property (nonatomic, retain) NSString *fileName;
@property (nonatomic, retain) NSString *filePath;
@property (nonatomic, retain) NSString *contentMimeType;
@property (nonatomic, retain) DownloadMetadata *fileMetadata;
@property (nonatomic, assign) BOOL isDownloaded;
@property (nonatomic, retain) UIToolbar *documentToolbar;
@property (nonatomic, retain) UIBarButtonItem *favoriteButton;
@property (nonatomic, retain) ToggleBarButtonItemDecorator *likeBarButton;
@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) MPMoviePlayerController *videoPlayer;
@property (nonatomic, retain) UIDocumentInteractionController *docInteractionController;
@property (nonatomic, retain) UIBarButtonItem *actionButton;
@property (nonatomic, retain) ImageActionSheet *actionSheet;
@property (nonatomic, retain) UIBarButtonItem *commentButton;
@property (nonatomic, retain) LikeHTTPRequest *likeRequest;
@property (nonatomic, retain) CommentsHttpRequest *commentsRequest;
@property (nonatomic, assign) BOOL showLikeButton;
@property (nonatomic, assign) BOOL showTrashButton;
@property (nonatomic, assign) BOOL isVersionDocument;
@property (nonatomic, assign) BOOL presentNewDocumentPopover;
@property (nonatomic, readwrite, retain) MBProgressHUD *HUD;
@property (nonatomic, retain) UIPopoverController *popover;
@property (nonatomic, retain) NSString *selectedAccountUUID;
@property (nonatomic, retain) NSString *tenantID;
@property (nonatomic, retain) NSString *repositoryID;

- (UIBarButtonItem *)iconSpacer;
- (void)sendMail;
- (IBAction)addToFavorites;
- (IBAction)actionButtonPressed:(id)sender;
- (IBAction)commentsButtonPressed:(id)sender;
- (void)downloadButtonPressed;
- (void)saveFileLocally;
- (void)trashButtonPressed;
- (void)performAction:(id)sender;

@end
