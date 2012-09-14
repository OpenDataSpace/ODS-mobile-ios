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
//  DocumentViewController.m
//

#import "DocumentViewController.h"
#import "FileUtils.h"
#import "DocumentCommentsTableViewController.h"
#import "IFTemporaryModel.h"
#import "AppProperties.h"
#import "Utility.h"
#import "ThemeProperties.h"
#import "FileDownloadManager.h"
#import "RepositoryServices.h"
#import "TransparentToolbar.h"
#import "MBProgressHUD.h"
#import "BarButtonBadge.h"
#import "AccountManager.h"
#import "FileProtectionManager.h"
#import "MediaPlayer/MPMoviePlayerController.h"
#import "AlfrescoAppDelegate.h"
#import "IpadSupport.h"
#import "ImageActionSheet.h"
#import "MessageViewController.h"
#import "TTTAttributedLabel.h"
#import "WEPopoverController.h"
#import "EditTextDocumentViewController.h"
#import "ConnectivityManager.h"
#import "FavoriteManager.h"
#import "AddTaskViewController.h"
#import "TaskItem.h"
#import "RepositoryItem.h"
#import "SaveBackMetadata.h"
#import "NodeLocationHTTPRequest.h"

#define kToolbarSpacerWidth 7.5f
#define kFrameLoadCodeError 102

#define kAlertViewOverwriteConfirmation 1
#define kAlertViewDeleteConfirmation 2

@interface DocumentViewController (private) 
- (void)newDocumentPopover;
- (void)enterEditMode:(BOOL)animated;
- (void)loadCommentsViewController:(NSDictionary *)model;
- (void)replaceCommentButtonWithBadge:(NSString *)badgeTitle;
- (void)startHUD;
- (void)stopHUD;
- (void)cancelActiveHTTPConnections;
- (NSString *)applicationDocumentsDirectory;
- (NSString *)fixMimeTypeFor:(NSString *)originalMimeType;
- (void)reachabilityChanged:(NSNotification *)notification;
@end

@implementation DocumentViewController
@synthesize cmisObjectId = _cmisObjectId;
@synthesize fileData = _fileData;
@synthesize fileName = _fileName;
@synthesize filePath = _filePath;
@synthesize contentMimeType = _contentMimeType;
@synthesize fileMetadata = _fileMetadata;
@synthesize isDownloaded = _isDownloaded;
@synthesize documentToolbar = _documentToolbar;
@synthesize favoriteButton = _favoriteButton;
@synthesize likeBarButton = _likeBarButton;
@synthesize webView = _webView;
@synthesize videoPlayer = _videoPlayer;
@synthesize docInteractionController = _docInteractionController;
@synthesize actionButton = _actionButton;
@synthesize actionSheet = _actionSheet;
@synthesize commentButton = _commentButton;
@synthesize editButton = _editButton;
@synthesize likeRequest = _likeRequest;
@synthesize commentsRequest = _commentsRequest;
@synthesize nodeLocationRequest = _nodeLocationRequest;
@synthesize showLikeButton = _showLikeButton;
@synthesize showTrashButton = _showTrashButton;
@synthesize showReviewButton = _showReviewButton;
@synthesize showFavoriteButton = _showFavoriteButton;
@synthesize isVersionDocument = _isVersionDocument;
@synthesize presentNewDocumentPopover = _presentNewDocumentPopover;
@synthesize presentEditMode = _presentEditMode;
@synthesize canEditDocument = _canEditDocument;
@synthesize hasNodeLocation = _hasNodeLocation;
@synthesize HUD = _HUD;
@synthesize popover = _popover;
@synthesize selectedAccountUUID = _selectedAccountUUID;
@synthesize tenantID = _tenantID;
@synthesize repositoryID = _repositoryID;
@synthesize backButtonTitle = _backButtonTitle;


BOOL isFullScreen = NO;

NSInteger const kGetCommentsCountTag = 6;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self cancelActiveHTTPConnections];
    
    [_cmisObjectId release];
	[_fileData release];
	[_fileName release];
    [_filePath release];
    [_contentMimeType release];
    [_fileMetadata release];
	[_documentToolbar release];
	[_favoriteButton release];
	[_webView release];
    [_videoPlayer release];
    [_likeBarButton release];
	[_docInteractionController release];
    [_actionButton release];
    [_actionSheet release];
    [_commentButton release];
    [_editButton release];
    [_likeRequest release];
    [_commentsRequest release];
    [_nodeLocationRequest release];
    [_previewRequest release];
    [_HUD release];
    [_selectedAccountUUID release];
    [_tenantID release];
    [_repositoryID release];
    
    [_backButtonTitle release];
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.showTrashButton = YES;
    }
    return self;
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.webView removeFromSuperview];
    self.webView = nil;
    
    [super viewDidUnload];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self.popover dismissPopoverAnimated:YES];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
    blankRequestLoaded = YES;

    if (self.videoPlayer)
    {
        [self.videoPlayer stop];
    }

    [super viewDidDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.presentNewDocumentPopover)
    {
        [self setPresentNewDocumentPopover:NO];
        [self newDocumentPopover];
    }
    else if (self.presentEditMode)
    {
        [self setPresentEditMode:NO];
        if (IS_IPAD)
        {
            //At this point the appear animation is happening delaying half a second
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
                [self enterEditMode:YES];
            });
        }
        else
        {
            [self enterEditMode:NO];
        }
        
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:self.fileName];
    
    if (self.filePath)
    {
        // If filepath is set, it is preferred from the filename in the temp path
        path = self.filePath;
    }
    
    NSURL *url = [NSURL fileURLWithPath:path];
    // Only reload content if the request is the blank page
    if (blankRequestLoaded)
    {
        if (self.contentMimeType)
        {
            [[FileProtectionManager sharedInstance] completeProtectionForFileAtPath:path];
            NSData *requestData = [NSData dataWithContentsOfFile:path options:NSDataWritingFileProtectionComplete error:nil];
            [self.webView loadData:requestData MIMEType:self.contentMimeType textEncodingName:@"UTF-8" baseURL:url];
        }
        else
        {
            [self.webView loadRequest:self.previewRequest];
        }

        blankRequestLoaded = NO;
    }
   
    BOOL usingAlfresco = [[AccountManager sharedManager] isAlfrescoAccountForAccountUUID:self.selectedAccountUUID];
    BOOL showCommentButton = [[AppProperties propertyForKey:kPShowCommentButton] boolValue];
    BOOL useLocalComments = [[FDKeychainUserDefaults standardUserDefaults] boolForKey:@"useLocalComments"];
    
    AccountInfo *account = [[AccountManager sharedManager] accountInfoForUUID:self.selectedAccountUUID];
    BOOL validAccount = account?YES:NO;
    
#ifdef TARGET_ALFRESCO
    if (self.isDownloaded)
    {
        showCommentButton = NO;
    }
#endif
    
    BOOL hasInternetConnection = [[ConnectivityManager sharedManager] hasInternetConnection];
    // The comment button could be disabled if the user pressed the comment button
    // we need to reenable it if there's internet connection
    [self.commentButton setEnabled:hasInternetConnection];

    // Calling the comment request service for the comment count
    // If there's no connection we should not perform the request
    if (hasInternetConnection && (showCommentButton && usingAlfresco) && !(self.isDownloaded && useLocalComments) && validAccount)
    {
        self.commentsRequest = [CommentsHttpRequest commentsHttpGetRequestWithNodeRef:[NodeRef nodeRefFromCmisObjectId:self.cmisObjectId]
                                                                          accountUUID:self.selectedAccountUUID tenantID:self.tenantID];
        [self.commentsRequest setDelegate:self];
        [self.commentsRequest setDidFinishSelector:@selector(commentsHttpRequestDidFinish:)];
        [self.commentsRequest setDidFailSelector:@selector(commentsHttpRequestDidFail:)];
        [self.commentsRequest setTag:kGetCommentsCountTag];
        [self.commentsRequest startAsynchronous];
    }
    else if (useLocalComments)
    {
        //We retrieve the count from the saved comments
        [self replaceCommentButtonWithBadge:[NSString stringWithFormat:@"%d", [self.fileMetadata.localComments count]]];
    }
}


/*
 Started with the idea in http://stackoverflow.com/questions/1110052/uiview-doesnt-resize-to-full-screen-when-hiding-the-nav-bar-tab-bar
 UIView doesn't resize to full screen when hiding the nav bar & tab bar
 
 made several changes, including changing tab bar for custom toolbar
 */
- (void) handleTap:(UIGestureRecognizer *)sender
{
    isFullScreen = !isFullScreen;
    
    [UIView beginAnimations:@"fullscreen" context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:.3];
    
    // Move tab bar up/down
    // We don't need the logic to hide the toolbar in the ipad since the toolbar is in the nav bar
    if (!IS_IPAD)
    {
        CGRect tabBarFrame = self.documentToolbar.frame;
        CGFloat tabBarHeight = tabBarFrame.size.height;
        CGFloat offset = isFullScreen ? tabBarHeight : -1 * tabBarHeight;
        CGFloat tabBarY = tabBarFrame.origin.y + offset;
        tabBarFrame.origin.y = tabBarY;
        self.documentToolbar.frame = tabBarFrame;
        
        
        CGRect webViewFrame = self.webView.frame;
        CGFloat webViewHeight = webViewFrame.size.height+ offset;
        webViewFrame.size.height = webViewHeight;
        self.webView.frame = webViewFrame;
        // Fade it in/out
        self.navigationController.navigationBar.alpha = isFullScreen ? 0 : 1;
        self.documentToolbar.alpha = isFullScreen ? 0 : 1;
        
        // Resize webview to be full screen / normal
        [self.webView removeFromSuperview];
        [self.view addSubview:self.webView];
    }
    
    [self.navigationController setNavigationBarHidden:isFullScreen animated:YES];
    [UIView commitAnimations];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSInteger spacersCount = 0;
    
    RepositoryInfo *repoInfo = [[RepositoryServices shared] getRepositoryInfoForAccountUUID:self.selectedAccountUUID tenantID:self.tenantID];
    BOOL usingAlfresco = [[AccountManager sharedManager] isAlfrescoAccountForAccountUUID:self.selectedAccountUUID];
    
    AccountInfo *account = [[AccountManager sharedManager] accountInfoForUUID:self.selectedAccountUUID];
    
    self.showLikeButton = (usingAlfresco ? [[AppProperties propertyForKey:kPShowLikeButton] boolValue] : NO);
    if (self.showLikeButton && !self.isDownloaded)
    {
        NSString *productVersion = [repoInfo productVersion];
        self.showLikeButton = ([productVersion hasPrefix:@"3.5"] || [productVersion integerValue] > 3);
    }
    
    self.showFavoriteButton = usingAlfresco;
    
    NSMutableArray *updatedItemsArray = [NSMutableArray arrayWithArray:[self.documentToolbar items]];
    NSString *title = self.fileMetadata ? self.fileMetadata.filename : self.fileName;
    
    // Double-tap toggles the navigation bar
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [tapRecognizer setDelegate:self];
    [tapRecognizer setNumberOfTapsRequired:2];
    [self.webView addGestureRecognizer:tapRecognizer];
    [tapRecognizer release];
    
    // For the ipad toolbar we don't have the flexible space as the first element of the toolbar items
	NSInteger actionButtonIndex = IS_IPAD ? 0 : 1;
    self.actionButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(performAction:)] autorelease];
    [self buildActionMenu];
    [updatedItemsArray insertObject:[self iconSpacer] atIndex:actionButtonIndex];
    spacersCount++;
    [updatedItemsArray insertObject:self.actionButton atIndex:actionButtonIndex];
    
    BOOL showCommentButton = [[AppProperties propertyForKey:kPShowCommentButton] boolValue];
    
#ifdef TARGET_ALFRESCO
    if (self.isDownloaded)
    {
        showCommentButton = NO;
        self.showLikeButton = NO;
        self.showFavoriteButton = NO;
    }
#endif
    
    if (showCommentButton && usingAlfresco && !self.isVersionDocument)
    {
        UIImage *commentIconImage = [UIImage imageNamed:@"comments.png"];
        self.commentButton = [[[UIBarButtonItem alloc] initWithImage:commentIconImage 
                                                               style:UIBarButtonItemStylePlain 
                                                              target:self action:@selector(commentsButtonPressed:)] autorelease];
        [updatedItemsArray addObject:[self iconSpacer]];
        spacersCount++;
        [updatedItemsArray addObject:self.commentButton];
    }
    
    // Show favorites bar button item
    if (self.showFavoriteButton)
    {
        [self setFavoriteButton:[[[ToggleBarButtonItemDecorator alloc ] initWithOffImage:[UIImage imageNamed:@"favorite-unchecked.png"]
                                                                                 onImage:[UIImage imageNamed:@"favorite-checked.png"]
                                                                                   style:UIBarButtonItemStylePlain
                                                                                  target:self action:@selector(addToFavorites:)]autorelease]];
        
        if ([[FavoriteManager sharedManager] isNodeFavorite:self.cmisObjectId inAccount:self.selectedAccountUUID])
        {
            [self.favoriteButton toggleImage];
        }
        
        [updatedItemsArray addObject:[self iconSpacer]];
        spacersCount++;
        [updatedItemsArray addObject:[self.favoriteButton barButton]];
    }
    

    // Calling the like request service
    if (self.showLikeButton && self.cmisObjectId && !self.isVersionDocument && !self.isDownloaded && account != nil)
    {
        if ([[ConnectivityManager sharedManager] hasInternetConnection])
        {
            self.likeRequest = [LikeHTTPRequest getHTTPRequestForNodeRef:[NodeRef nodeRefFromCmisObjectId:self.cmisObjectId] 
                                                             accountUUID:self.fileMetadata.accountUUID
                                                                tenantID:self.fileMetadata.tenantID];
            [self.likeRequest setLikeDelegate:self];
            [self.likeRequest setTag:kLike_GET_Request];
            [self.likeRequest startAsynchronous];
        }
        
        [self setLikeBarButton:[[[ToggleBarButtonItemDecorator alloc ] initWithOffImage:[UIImage imageNamed:@"like-unchecked.png"]
                                                                                onImage:[UIImage imageNamed:@"like-checked.png"]
                                                                                  style:UIBarButtonItemStylePlain 
                                                                                 target:self action:@selector(toggleLikeDocument:)]autorelease]];
        [updatedItemsArray addObject:[self iconSpacer]];
        spacersCount++;
        [updatedItemsArray addObject:[self.likeBarButton barButton]];
    }
    
    if (self.canEditDocument && [[self contentMimeType] isEqualToString:@"text/plain"] && !self.isDownloaded)
    {
        self.editButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"pencil.png"] style:UIBarButtonItemStylePlain target:self action:@selector(editDocumentAction:)] autorelease];
        [updatedItemsArray addObject:[self iconSpacer]];
        spacersCount++;
        [updatedItemsArray addObject:self.editButton];
    }
    [[self documentToolbar] setItems:updatedItemsArray];

    
    [self.webView setAlpha:0.0];
    [self.webView setScalesPageToFit:YES];
    [self.webView setMediaPlaybackRequiresUserAction:NO];
    [self.webView setAllowsInlineMediaPlayback:NO];
    
	// write the file contents to the file system
	NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:self.fileName];
    
    if (self.fileData)
    {
        [self.fileData writeToFile:path atomically:NO];
    }
    else if (self.filePath)
    {
        // If filepath is set, it is preferred from the filename in the temp path
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *tempPath = [FileUtils pathToTempFile:[self.filePath lastPathComponent]];
        //We only use it if the file is in the temp path
        if ([fileManager fileExistsAtPath:tempPath])
        {
            path = self.filePath;
        }
        else
        {
            // Can happen when ASIHTTPRequest returns a cached file
            NSError *error = nil;
            // Ignore the error
            [fileManager removeItemAtPath:path error:nil];
            [fileManager copyItemAtPath:self.filePath toPath:path error:&error];
            
            if (error)
            {
                NSLog(@"Error copying file to temp path %@", [error description]);
            }
        }
    }
	
	// Get a URL that points to the file on the filesystemw
	NSURL *url = [NSURL fileURLWithPath:path];
    
    if (!self.contentMimeType)
    {
        self.contentMimeType = mimeTypeForFilename([url lastPathComponent]);
    }
    
    self.contentMimeType = [self fixMimeTypeFor:self.contentMimeType];
    self.previewRequest = [NSURLRequest requestWithURL:url];
    BOOL isVideo = isVideoExtension([url pathExtension]);
    
    /**
     * Note: UIWebView is populated in viewDidAppear
     */
    // load the document into the view
    if (self.fileData && self.contentMimeType)
    {
        [self.webView loadData:self.fileData MIMEType:self.contentMimeType textEncodingName:@"UTF-8" baseURL:url];
    }
    else if (self.contentMimeType && !isVideo)
    {
        [[FileProtectionManager sharedInstance] completeProtectionForFileAtPath:path];
        NSData *requestData = [NSData dataWithContentsOfFile:path];
        [self.webView loadData:requestData MIMEType:self.contentMimeType textEncodingName:@"UTF-8" baseURL:url];
    }
    else if (self.contentMimeType && isVideo)
    {
        MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:url];
        [player.view setFrame:self.webView.frame];
        [player.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [player prepareToPlay];
        
        [self.webView removeFromSuperview];
        [self setWebView:nil];
        
        [self.view insertSubview:player.view belowSubview:self.documentToolbar];
        [self setVideoPlayer:player];
        [player release];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerDidExitFullscreen:) name:MPMoviePlayerDidExitFullscreenNotification object:nil];
    }
    else
    {
        [self.webView loadRequest:self.previewRequest];
    }
    
    [self.webView setDelegate:self];
	
	//We move the tool to the nav bar in the ipad
    if (IS_IPAD) 
    {
        CGFloat width = 35;
        NSInteger normalItems = [self.documentToolbar.items count] - spacersCount;
        
        TransparentToolbar *ipadToolbar = [[TransparentToolbar alloc] initWithFrame:CGRectMake(0, 0, normalItems * width + spacersCount * kToolbarSpacerWidth + 10, 44.01)];
        [ipadToolbar setTintColor:[ThemeProperties toolbarColor]];
        [ipadToolbar setItems:[self.documentToolbar items]];
        [self.documentToolbar removeFromSuperview];
        self.documentToolbar = ipadToolbar;
        
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:ipadToolbar] autorelease];
        [ipadToolbar release];
        
        // Adding the height of the toolbar
        if (self.webView)
        {
            self.webView.frame = self.view.frame;
        }
        
        // If previwing a video this will not be nil
        if (self.videoPlayer)
        {
            self.videoPlayer.view.frame = self.view.frame;
        }
    }
    
	// we want to release this object since it may take a lot of memory space
    self.fileData = nil;
	
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self setTitle:title];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentUpdated:) name:kNotificationDocumentUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];

    // Disable the buttons if there's no internet connection when loading the preview
    [self reachabilityChanged:nil];
}

- (void)newDocumentPopover
{
    NSString *createMessage = NSLocalizedString(@"create-document.popover.message", @"Popover message after a Document creation");
    MessageViewController *messageViewController = [[[MessageViewController alloc] initWithMessage:@"Test Message"] autorelease];
    [messageViewController.messageLabel setText:createMessage afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
         NSRange saveBackRange = [createMessage rangeOfString:NSLocalizedString(@"create-document.popover.save-back", @"Save Back text")];
         if (saveBackRange.length > 0) 
         {
             UIFont *boldSystemFont = [UIFont boldSystemFontOfSize:17]; 
             CTFontRef boldFont = CTFontCreateWithName((CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
             [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(id)boldFont range:saveBackRange];
         }
         return mutableAttributedString;
     }];
    
    // The popover is presented using WEPopoverController since the standard UIPopoverController will not 
    // handle the customization needed for the desired design. When using a cutom UIPopoverBackgroundView
    // the popover would add a shadow in the content and the arrow does not hide that shadow
    UIView *mainView = [[((AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate]) mainViewController] view];
    WEPopoverController *popoverController = [[[WEPopoverController alloc] initWithContentViewController:messageViewController] autorelease];
    [popoverController setContainerViewProperties:[self improvedContainerViewProperties]];
    [self setPopover:(UIPopoverController *)popoverController];
    
    UIView *buttonView = [self.actionButton valueForKey:@"view"];
    CGRect buttonFrame = [buttonView.superview convertRect:buttonView.frame toView:mainView];
    
    [self.popover presentPopoverFromRect:buttonFrame 
                                  inView:mainView
                permittedArrowDirections:(UIPopoverArrowDirectionDown | UIPopoverArrowDirectionUp)
                                animated:YES];
    
    [self setPresentNewDocumentPopover:NO];
}

- (void)enterEditMode:(BOOL)animated
{
    EditTextDocumentViewController *editController = [[[EditTextDocumentViewController alloc] initWithObjectId:self.cmisObjectId andDocumentPath:self.filePath] autorelease];
    [editController setDocumentName:[self title]];
    [editController setSelectedAccountUUID:self.selectedAccountUUID];
    [editController setTenantID:self.tenantID];
    
    UINavigationController *modalNav = [[[UINavigationController alloc] initWithRootViewController:editController] autorelease];
    [modalNav setModalPresentationStyle:UIModalPresentationFullScreen];
    [modalNav setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    AlfrescoAppDelegate *appDelegate = (AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate presentModalViewController:modalNav animated:animated];
}

- (WEPopoverContainerViewProperties *)improvedContainerViewProperties
{
	WEPopoverContainerViewProperties *props = [[WEPopoverContainerViewProperties alloc] autorelease];
	NSString *bgImageName = nil;
	CGFloat bgMargin = 0.0;
	CGFloat bgCapSize = 0.0;
	CGFloat contentMargin = 4.0;
	
	bgImageName = @"white-bg-popover.png";
	
	// These constants are determined by the popoverBg.png image file and are image dependent
	bgMargin = 13; // margin width of 13 pixels on all sides popoverBg.png (62 pixels wide - 36 pixel background) / 2 == 26 / 2 == 13 
	bgCapSize = 31; // ImageSize/2  == 62 / 2 == 31 pixels
	
	props.leftBgMargin = bgMargin;
	props.rightBgMargin = bgMargin;
	props.topBgMargin = bgMargin;
	props.bottomBgMargin = bgMargin + 1; //The bottom margin seems to be off by 1 pixel, this is hardcoded and depends on the white-bg-popover.png/white-bg-popover-arrow.png
	props.leftBgCapSize = bgCapSize;
	props.topBgCapSize = bgCapSize;
	props.bgImageName = bgImageName;
	props.leftContentMargin = contentMargin;
	props.rightContentMargin = contentMargin - 1; // Need to shift one pixel for border to look correct
	props.topContentMargin = contentMargin; 
	props.bottomContentMargin = contentMargin;
	
	props.arrowMargin = 4.0;
	
	props.upArrowImageName = @"white-bg-popover-arrow.png";
	return props;	
}


- (NSString *)fixMimeTypeFor:(NSString *)originalMimeType 
{
    NSDictionary *mimeTypesFix = [NSDictionary dictionaryWithObject:@"audio/mp4" forKey:@"audio/m4a"];
    
    NSString *fixedMimeType = [mimeTypesFix objectForKey:originalMimeType];
    return fixedMimeType?fixedMimeType:originalMimeType;
}

- (UIBarButtonItem *)iconSpacer
{       
    UIBarButtonItem *iconSpacer = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace 
                                                                                 target:nil action:nil] autorelease];
    [iconSpacer setWidth:kToolbarSpacerWidth];
    return iconSpacer;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)replaceCommentButtonWithBadge:(NSString *)badgeTitle 
{
    // Only do this replacement if the comment button exists
    if (self.commentButton)
    {
        if (![[AppProperties propertyForKey:kPShowCommentButtonBadge] boolValue])
        {
            // Dont show if the setting is not enabled
            return;
        }
        
        UIImage *commentIconImage = [UIImage imageNamed:@"comments.png"];
        NSMutableArray *updatedItemsArray = [NSMutableArray arrayWithArray:[self.documentToolbar items]];
        NSInteger commentIndex = [updatedItemsArray indexOfObject:self.commentButton];
        [updatedItemsArray removeObject:self.commentButton];
        self.commentButton = [BarButtonBadge barButtonWithImage:commentIconImage badgeString:badgeTitle atRight:NO toTarget:self action:@selector(commentsButtonPressed:)];
        [updatedItemsArray insertObject:self.commentButton atIndex:commentIndex];
        [self.documentToolbar setItems:updatedItemsArray animated:NO];
        [self.documentToolbar reloadInputViews];
    }
}

#pragma mark - Action Selectors

- (void)emailDocumentAsAttachment
{
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mailer = [[[MFMailComposeViewController alloc] init] autorelease];
        [mailer setSubject:self.fileName];
        [mailer setMessageBody:NSLocalizedString(@"email.footer.text", @"Sent from ...") isHTML:NO];

        NSString *mimeType = nil;
        if (self.contentMimeType)
        {
            mimeType = self.contentMimeType;
        }
        else
        {
            mimeType = mimeTypeForFilenameWithDefault(self.fileName, @"application/octet-stream");
        }
        
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:self.fileName];
        
        if (self.filePath)
        {
            // If filepath is set, it is preferred from the filename in the temp path
            path = self.filePath;
        }
        [mailer addAttachmentData:[NSData dataWithContentsOfFile:path] mimeType:mimeType fileName:self.fileName];

        [self presentModalViewController:mailer animated:YES];
        mailer.mailComposeDelegate = self;
    }
    else
    {
        [[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"noEmailSetupDialogTitle", @"Mail Setup")
                                     message:NSLocalizedString(@"noEmailSetupDialogMessage", @"Mail is currently not setup on your device and is required to send emails")
                                    delegate:nil
                           cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK Button Text")
                           otherButtonTitles:nil] autorelease] show];
    }
}

- (void)emailDocumentAsLink
{
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mailer = [[[MFMailComposeViewController alloc] init] autorelease];
        [mailer setSubject:self.fileName];
        
        // In a site?
        NSString *siteURL = nil;
        NSDictionary *siteLocation = [self.nodeLocationRequest siteLocation];
        if (siteLocation)
        {
            siteURL = [@"/site/" stringByAppendingString:[siteLocation objectForKey:@"site"]];
        }

        NSString *cloudHostname = [AppProperties propertyForKey:kAlfrescoCloudHostname];
        NSString *detailsPageURL = [NSString stringWithFormat:@"https://%@/share/%@/page%@/document-details?nodeRef=%@", cloudHostname, self.tenantID, siteURL, self.cmisObjectId];
        NSString *detailsPageLink = [NSString stringWithFormat:NSLocalizedString(@"email.body.link", @"Link to..."), self.fileName];

        NSString *messageBody = [NSString stringWithFormat:@"<p><a href=\"%@\">%@</a></p><br />%@", detailsPageURL, detailsPageLink, NSLocalizedString(@"email.footer.html", @"Sent from ...")];
        [mailer setMessageBody:messageBody isHTML:YES];
        
        [self presentModalViewController:mailer animated:YES];
        mailer.mailComposeDelegate = self;
    }
    else
    {
        [[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"noEmailSetupDialogTitle", @"Mail Setup")
                                     message:NSLocalizedString(@"noEmailSetupDialogMessage", @"Mail is currently not setup on your device and is required to send emails")
                                    delegate:nil
                           cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK Button Text")
                           otherButtonTitles:nil] autorelease] show];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)addToFavorites:(id) sender
{
    [self.popover dismissPopoverAnimated:YES];
    
    /*
	if ([FileUtils isSaved:fileName]) {
		[FileUtils unsave:fileName];
		//[self.favoriteButton setImage:[UIImage imageNamed:@"favorite-unchecked.png"]];
	}
	else {
		[FileUtils save:fileName];
		//[self.favoriteButton setImage:[UIImage imageNamed:@"favorite-checked.png"]];
	}
     */
    
    if ([[FavoriteManager sharedManager] isFirstUse])
    {
        [[FavoriteManager sharedManager] showSyncPreferenceAlert];
    }
    
    NSInteger shouldFavorite = self.favoriteButton.toggleState ? 1 : 0;
    
    [[FavoriteManager sharedManager] setFavoriteUnfavoriteDelegate:self];
    [[FavoriteManager sharedManager] favoriteUnfavoriteNode:self.cmisObjectId withAccountUUID:self.selectedAccountUUID andTenantID:self.tenantID favoriteAction:shouldFavorite];
    
    [self.favoriteButton.barButton setEnabled:NO];
}

- (IBAction)toggleLikeDocument:(id)sender
{
    [self.popover dismissPopoverAnimated:YES];
    NodeRef *nodeRef = [NodeRef nodeRefFromCmisObjectId:self.cmisObjectId];
    
    if (self.likeBarButton.toggleState == YES)
    {
        self.likeRequest = [LikeHTTPRequest postHTTPRequestForNodeRef:nodeRef 
                                                          accountUUID:self.fileMetadata.accountUUID
                                                             tenantID:self.fileMetadata.tenantID];
    }
    else
    {
        self.likeRequest = [LikeHTTPRequest deleteHTTPRequest:nodeRef 
                                                  accountUUID:self.fileMetadata.accountUUID
                                                     tenantID:self.fileMetadata.tenantID];
    }
    
    [self.likeRequest setLikeDelegate:self];
    [self.likeRequest startAsynchronous];
    [self.likeBarButton.barButton setEnabled:NO];
}

- (void)buildActionMenu
{
    BOOL isVideo = isVideoExtension([self.fileName pathExtension]);
    BOOL isAudio = isAudioExtension([self.fileName pathExtension]);
    
    self.actionSheet = [[[ImageActionSheet alloc] initWithTitle:@""
                                                       delegate:self
                                              cancelButtonTitle:nil
                                         destructiveButtonTitle:nil
                                     otherButtonTitlesAndImages: nil] autorelease];
    
    [self.actionSheet addButtonWithTitle:NSLocalizedString(@"documentview.action.openin", @"Open in...") andImage:[UIImage imageNamed:@"open-in.png"]];
    if ([MFMailComposeViewController canSendMail])
    {
        [self.actionSheet addButtonWithTitle:NSLocalizedString(@"documentview.action.email.attachment", @"Email attachment") andImage:[UIImage imageNamed:@"send-email.png"]];
        AccountInfo *accountInfo = [[AccountManager sharedManager] accountInfoForUUID:self.selectedAccountUUID];
        if (accountInfo.isMultitenant && !self.isDownloaded)
        {
            if (self.hasNodeLocation)
            {
                [self.actionSheet addButtonWithTitle:NSLocalizedString(@"documentview.action.email.link", @"Email link") andImage:[UIImage imageNamed:@"send-email-link.png"]];
            }
            else if (self.nodeLocationRequest == nil)
            {
                // Disable the actionButton
                [self.actionButton setEnabled:NO];
                
                // Initiate a request to get the document's location
                NodeRef *nodeRef = [NodeRef nodeRefFromCmisObjectId:self.cmisObjectId];
                self.nodeLocationRequest = [NodeLocationHTTPRequest httpRequestNodeLocation:nodeRef withAccountUUID:self.selectedAccountUUID tenantID:self.tenantID];
                [self.nodeLocationRequest setDelegate:self];
                [self.nodeLocationRequest setDidFinishSelector:@selector(nodeLocationHttpRequestDidFinish:)];
                [self.nodeLocationRequest setDidFailSelector:@selector(nodeLocationHttpRequestDidFail:)];
                [self.nodeLocationRequest startAsynchronous];
            }
        }
    }
    
    if (!self.isDownloaded)
    {
        [self.actionSheet addButtonWithTitle:NSLocalizedString(@"documentview.action.download", @"Download action text") andImage:[UIImage imageNamed:@"download-action.png"]];
    }
    else if (self.showTrashButton)
    {
        [self.actionSheet addButtonWithTitle:NSLocalizedString(@"documentview.action.delete", @"Delete action text") andImage:[UIImage imageNamed:@"delete-action.png"]];
    }
    
    if (self.showReviewButton)
    {
        [self.actionSheet addButtonWithTitle:NSLocalizedString(@"documentview.action.review", @"Start review workflow") andImage:[UIImage imageNamed:@"tabTasks.png"]];
    }
    
    // Not allowed to print audio or video files
    if (!isAudio && !isVideo)
    {
        [self.actionSheet addButtonWithTitle:NSLocalizedString(@"documentview.action.print", @"Print") andImage:[UIImage imageNamed:@"print-action.png"]];
    }
    
    [self.actionSheet setCancelButtonIndex:[self.actionSheet addButtonWithTitle:NSLocalizedString(@"add.actionsheet.cancel", @"Cancel")]];
}

- (void)performAction:(id)sender
{
    [self.popover dismissPopoverAnimated:YES];
    if (self.actionSheet.isVisible)
    {
        return;
    }
    
    if (IS_IPAD)
    {
        [self.actionSheet setActionSheetStyle:UIActionSheetStyleDefault];
        [self.actionSheet showFromBarButtonItem:sender animated:YES];
    }
    else
    {
        [self.actionSheet showInView:[[self tabBarController] view]];
    }
}

- (void)editDocumentAction:(id)sender
{
    [self enterEditMode:YES];
}

#pragma mark - UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSString *buttonLabel = [actionSheet buttonTitleAtIndex:buttonIndex];
    
	if ([buttonLabel isEqualToString:NSLocalizedString(@"documentview.action.openin", @"Open in...")]) 
    {
        [self actionButtonPressed:self.actionButton];
    } 
    else if ([buttonLabel isEqualToString:NSLocalizedString(@"documentview.action.print", @"Print")]) 
    {
        UIPrintInteractionController *printController = [UIPrintInteractionController sharedPrintController];
        
        UIPrintInfo *printInfo = [UIPrintInfo printInfo];
        printInfo.outputType = UIPrintInfoOutputGeneral;
        printInfo.jobName = self.navigationController.title;
        
        printController.printInfo = printInfo;
        printController.printFormatter = [self.webView viewPrintFormatter];
        printController.showsPageRange = YES;
        
        UIPrintInteractionCompletionHandler completionHandler = ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
            if (!completed && error)
            {
                NSLog(@"Printing could not complete because of error: %@", error);
            }
        };
        
        if (IS_IPAD)
        {
            [printController presentFromBarButtonItem:self.actionButton animated:YES completionHandler:completionHandler];
        }
        else
        {
            [printController presentAnimated:YES completionHandler:completionHandler];
        }
    }
    else if ([buttonLabel isEqualToString:NSLocalizedString(@"documentview.action.email.attachment", @"Email action text")])
    {
        [self emailDocumentAsAttachment];
    }
    else if ([buttonLabel isEqualToString:NSLocalizedString(@"documentview.action.email.link", @"Email action text")])
    {
        [self emailDocumentAsLink];
    }
    else if ([buttonLabel isEqualToString:NSLocalizedString(@"documentview.action.download", @"Download action text")])
    {
        [self downloadButtonPressed];
    }
    else if ([buttonLabel isEqualToString:NSLocalizedString(@"documentview.action.delete", @"Delete action text")])
    {
        [self trashButtonPressed];
    }
    else if ([buttonLabel isEqualToString:NSLocalizedString(@"documentview.action.review", @"Review action text")])
    {
        [self reviewButtonPressed];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
}

- (IBAction)actionButtonPressed:(UIBarButtonItem *)sender
{
    if (self.docInteractionController == nil)
    {
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:self.fileName];
        NSURL *url = [NSURL fileURLWithPath:path];
        [self setDocInteractionController:[UIDocumentInteractionController interactionControllerWithURL:url]];
        [[self docInteractionController] setDelegate:self];
    }
    else
    {
        [self.docInteractionController dismissMenuAnimated:YES];
    }
		
    if (![[self docInteractionController] presentOpenInMenuFromBarButtonItem:sender animated:YES])
    {
        [[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"noAppsAvailableDialogTitle", @"No Applications Available")
                                     message:NSLocalizedString(@"noAppsAvailableDialogMessage", @"There are no applications that are capable of opening this file on this device")
                                    delegate:nil
                           cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK Button Text")
                           otherButtonTitles:nil] autorelease] show];
    }
}


- (void)downloadButtonPressed
{
    if ([[FileDownloadManager sharedInstance] downloadExistsForKey:self.fileName])
    {
        UIAlertView *overwritePrompt = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"documentview.overwrite.download.prompt.title", @"")
                                                                   message:NSLocalizedString(@"documentview.overwrite.download.prompt.message", @"Yes/No Question")
                                                                  delegate:self 
                                                         cancelButtonTitle:NSLocalizedString(@"No", @"No Button Text") 
                                                         otherButtonTitles:NSLocalizedString(@"Yes", @"Yes Button Text"), nil] autorelease];
        
        [overwritePrompt setTag:kAlertViewOverwriteConfirmation];
        [overwritePrompt show];
    }
    else
    {
        [self saveFileLocally];
    }
}

- (void)saveFileLocally 
{
    FileDownloadManager *manager = [FileDownloadManager sharedInstance];
    [manager setOverwriteExistingDownloads:YES];
    NSString *filename = [[FileDownloadManager sharedInstance] setDownload:self.fileMetadata.downloadInfo forKey:self.fileName withFilePath:self.fileName];

    // Since the file was moved from the temp path to the save file we want to update the file path to the one in the saved documents
    self.filePath = [FileUtils pathToSavedFile:filename];
    
    UIAlertView *saveConfirmationAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"documentview.download.confirmation.title", @"")
                                                                    message:NSLocalizedString(@"documentview.download.confirmation.message", @"The document has been saved to your device")
                                                                   delegate:nil 
                                                          cancelButtonTitle: NSLocalizedString(@"okayButtonText", @"OK") 
                                                          otherButtonTitles:nil, nil];
    [saveConfirmationAlert show];
    [saveConfirmationAlert release];
}

- (void)trashButtonPressed
{
    UIAlertView *deleteConfirmationAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"documentview.delete.confirmation.title", @"")
                                                                       message:NSLocalizedString(@"documentview.delete.confirmation.message", @"Do you want to remove this document from your device?") 
                                                                      delegate:self 
                                                             cancelButtonTitle:NSLocalizedString(@"No", @"No Button Text") 
                                                             otherButtonTitles:NSLocalizedString(@"Yes", @"Yes Button Text"), nil] autorelease];

    [deleteConfirmationAlert setTag:kAlertViewDeleteConfirmation];
    [deleteConfirmationAlert show];
}

- (void)reviewButtonPressed
{
    AddTaskViewController *addTaskController = [[AddTaskViewController alloc] initWithStyle:UITableViewStyleGrouped 
                                                                                    account:self.fileMetadata.accountUUID 
                                                                                   tenantID:self.fileMetadata.tenantID 
                                                                                   workflowType:WORKFLOW_TYPE_REVIEW
                                                                                 attachment:self.fileMetadata.repositoryItem];
    addTaskController.modalPresentationStyle = UIModalPresentationFormSheet;
    addTaskController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [IpadSupport presentModalViewController:addTaskController withNavigation:nil];
    [addTaskController release];
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag)
    {
        case kAlertViewOverwriteConfirmation:
        {
            if (buttonIndex != alertView.cancelButtonIndex)
            {
                [self saveFileLocally];
            }
            break;
        }
        case kAlertViewDeleteConfirmation:
        {
            if (buttonIndex != alertView.cancelButtonIndex)
            {
                NSLog(@"User confirmed removal of file %@", self.fileName);
                [[FileDownloadManager sharedInstance] removeDownloadInfoForFilename:self.fileName];
            }
            break;
        }
        default:
        {
            NSLog(@"Unknown AlertView!");
            break;
        }
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kAlertViewDeleteConfirmation && buttonIndex != alertView.cancelButtonIndex)
    {
        [self.navigationController popViewControllerAnimated:YES];
        
        if (IS_IPAD)
        {
            [self retain];
            [IpadSupport clearDetailController];
        }
    }
}


#pragma mark - View Comments Button and related methods

- (IBAction)commentsButtonPressed:(id)sender
{
    [self.popover dismissPopoverAnimated:YES];
    self.commentButton.enabled = NO;
    BOOL useLocalComments = [[FDKeychainUserDefaults standardUserDefaults] boolForKey:@"useLocalComments"];
    AccountInfo *account = [[AccountManager sharedManager] accountInfoForUUID:self.selectedAccountUUID];
    
    // Use local comments only if it is downloaded and the useLocalComments user setting is turned on
    // Otherwise use alfresco repository code
    if (self.cmisObjectId && ([self.cmisObjectId length] > 0) && !(self.isDownloaded && useLocalComments) && account)
    {
        NSLog(@"Comment Button Pressed, retrieving Comments from current request");
        if ([self.commentsRequest isFinished])
        {
            [self loadCommentsViewController:self.commentsRequest.commentsDictionary];
        }
        else
        {
            self.commentsRequest.tag = 0;
            [self startHUD];
        }
    }
    else if (self.fileMetadata && self.isDownloaded && account)
    {
        DocumentCommentsTableViewController *viewController = [[DocumentCommentsTableViewController alloc] initWithDownloadMetadata:self.fileMetadata];
        NSMutableDictionary *commentDicts = [NSMutableDictionary dictionaryWithObject:self.fileMetadata.localComments forKey:@"items"];
        [viewController setModel:[[[IFTemporaryModel alloc] initWithDictionary:[NSMutableDictionary dictionaryWithDictionary:commentDicts]] autorelease]];
        [viewController setSelectedAccountUUID:self.selectedAccountUUID];
        [self.navigationController pushViewController:viewController animated:YES];
        [viewController release];
    }
    else
    {
        // We Should never get here, but just in case, throw an alert
        NSLog(@"NodeRef Not Available");
        [[[[UIAlertView alloc] initWithTitle:@"NodeRef Not Available"
                                     message:@"Comments are not available for this document"
                                    delegate:nil
                           cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK")
                           otherButtonTitles:nil, nil] autorelease] show];
    }
}

- (void)loadCommentsViewController:(NSDictionary *)model
{
    DocumentCommentsTableViewController *viewController = [[DocumentCommentsTableViewController alloc] initWithCMISObjectId:self.cmisObjectId];
    [viewController setModel:[[[IFTemporaryModel alloc] initWithDictionary:[NSMutableDictionary dictionaryWithDictionary:model]] autorelease]]; 
    [viewController setSelectedAccountUUID:self.selectedAccountUUID];
    [self.navigationController pushViewController:viewController animated:YES];
    [viewController release];
}

- (void)commentsHttpRequestDidFinish:(id)sender
{
    CommentsHttpRequest * request = (CommentsHttpRequest *)sender;
    
    if (request.tag == kGetCommentsCountTag)
    {
        NSArray *commentsArray = [request.commentsDictionary objectForKey:@"items"];
        [self replaceCommentButtonWithBadge:[NSString stringWithFormat:@"%d", [commentsArray count]]];
    }
    else
    {
        [self loadCommentsViewController:self.commentsRequest.commentsDictionary];
    }
    [self stopHUD];
}

- (void)commentsHttpRequestDidFail:(id)sender
{
    NSLog(@"commentsHttpRequestDidFail!");
    [self stopHUD];
}

#pragma mark - Node Location HTTP Request

- (void)nodeLocationHttpRequestDidFinish:(NodeLocationHTTPRequest *)request
{
    // We have the document's location
    self.hasNodeLocation = YES;
    
    // Rebuild the action menu
    [self buildActionMenu];

    // Re-enable the actionButton
    [self.actionButton setEnabled:YES];
}

- (void)nodeLocationHttpRequestDidFail:(id)sender
{
    // We didn't get the node's location
    self.hasNodeLocation = NO;

    // Re-enable the actionButton
    [self.actionButton setEnabled:YES];
}


#pragma mark - UIDocumentInteractionControllerDelegate Methods

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)interactionController
{
    self.docInteractionController = nil;
    return self;
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller willBeginSendingToApplication:(NSString *)application
{
    /**
     * Alfresco Generic and Quickoffice integration
     */
    SaveBackMetadata *saveBackMetadata = [[[SaveBackMetadata alloc] init] autorelease];
    saveBackMetadata.originalPath = self.filePath;
    saveBackMetadata.originalName = self.fileName;
    if (!self.isDownloaded)
    {
        saveBackMetadata.accountUUID = self.fileMetadata.accountUUID;
        saveBackMetadata.tenantID = self.fileMetadata.tenantID;
        saveBackMetadata.objectId = self.fileMetadata.objectId;
    }
    
    NSString *appIdentifier = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"AppIdentifier"];
    NSDictionary *annotation = nil;

    if ([application isEqualToString:QuickofficeBundleIdentifier])
    {
        // Quickoffice SaveBack API parameters
        annotation = [NSDictionary dictionaryWithObjectsAndKeys:
                        externalAPIKey(APIKeyQuickoffice), QuickofficeApplicationSecretUUIDKey,
                        saveBackMetadata.dictionaryRepresentation, QuickofficeApplicationInfoKey,
                        appIdentifier, QuickofficeApplicationIdentifierKey,
                        QuickofficeApplicationDocumentExtension, QuickofficeApplicationDocumentExtensionKey,
                        QuickofficeApplicationDocumentUTI, QuickofficeApplicationDocumentUTIKey,
                        nil];
    }
    else
    {
        // Alfresco SaveBack API parameters
        annotation = [NSDictionary dictionaryWithObjectsAndKeys:
                        saveBackMetadata.dictionaryRepresentation, AlfrescoSaveBackMetadataKey,
                        nil];
    }
        
    self.docInteractionController.annotation = annotation;
}

#pragma mark - UIWebViewDelegate

- (void) webViewDidFinishLoad:(UIWebView *)webView
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:kDocumentFadeInTime];
    [self.webView setAlpha:1.0];
    [UIView commitAnimations];
}

/**
 * We want to know when the document cannot be rendered
 * UIWebView throws two errors when a document cannot be previewed
 * code:100 message: "Operation could not be completed. (NSURLErrorDomain error 100.)"
 * code:102 message: "Frame load interrupted"
 *
 * Note we also get an error when loading a video, as rendering is handed off to a QuickTime plug-in
 * code:204 message: "Plug-in handled load"
 */
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"Failed to load preview: %@", [error description]);
    if ([error code] == kFrameLoadCodeError)
    {
        [self performSelectorOnMainThread:@selector(previewLoadFailed) withObject:nil waitUntilDone:NO];
    }
    [self.webView setAlpha:1.0];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeOther && [request.URL.scheme hasPrefix:@"http"])
    {
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
    
    return YES;    
}

- (void)previewLoadFailed
{
    [[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"documentview.preview.failure.title", @"")
                                 message:NSLocalizedString(@"documentview.preview.failure.message", @"Failed to preview the document" )
                                delegate:nil
                       cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK")
                       otherButtonTitles:nil, nil] autorelease] show];
    [self.webView setAlpha:1.0];
}

#pragma mark - LikeHTTPRequest Delegate

- (void)likeRequest:(LikeHTTPRequest *)request likeRatingServiceDefined:(NSString *)isDefined 
{
}
- (void)likeRequest:(LikeHTTPRequest *)request documentIsLiked:(NSString *)isLiked 
{
    BOOL boolLiked = [isLiked boolValue];
    
    if (self.likeBarButton.toggleState != boolLiked)
    {
        [self.likeBarButton toggleImage];
    }
    [self.likeBarButton.barButton setEnabled:YES];
}

- (void)likeRequest:(LikeHTTPRequest *)request likeDocumentSuccess:(NSString *)isLiked 
{
    [self.likeBarButton.barButton setEnabled:YES];
}

- (void)likeRequest:(LikeHTTPRequest *)request unlikeDocumentSuccess:(NSString *)isUnliked
{
    [self.likeBarButton.barButton setEnabled:YES];
}

- (void)likeRequest:(LikeHTTPRequest *)request failedWithError:(NSError *)theError 
{
    NSLog(@"likeRequest:failedWithError:%@", [theError description]);
    if (request.tag == kLike_GET_Request)
    {
        return;
    }
    
    NSString* errorMessage = nil;
    if (self.likeBarButton.toggleState)
    {
        errorMessage = NSLocalizedString(@"documentview.like.failure.message", @"Failed to like the document" );
    }
    else
    {
        errorMessage = NSLocalizedString(@"documentview.unlike.failure.message", @"Failed to unlike the document" );
    }
    
    [[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"documentview.like.failure.title", @"")
                                 message:errorMessage
                                delegate:nil
                       cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK")
                       otherButtonTitles:nil, nil] autorelease] show];
    
    // Toggle the button back to the previous state.
    [self.likeBarButton toggleImage];
    [self.likeBarButton.barButton setEnabled:YES];
}

#pragma mark - Favorite Manager Delegate Methods

- (void)favoriteUnfavoriteSuccessfull
{
    [self.favoriteButton.barButton setEnabled:YES];
}

- (void)favoriteUnfavoriteUnsuccessfull
{
    BOOL documentIsFavorite = [[FavoriteManager sharedManager] isNodeFavorite:self.cmisObjectId inAccount:self.selectedAccountUUID];
    
    if (self.favoriteButton.toggleState != documentIsFavorite)
    {
        [self.favoriteButton toggleImage];
    }
    
    [self.favoriteButton.barButton setEnabled:YES];
}

#pragma mark - MBProgressHUD Helper Methods

- (void)startHUD
{
	if (!self.HUD)
    {
		self.HUD = createAndShowProgressHUDForView(self.webView);
	}
}

- (void)stopHUD
{
	if (self.HUD)
    {
        stopProgressHUD(self.HUD);
		self.HUD = nil;
	}
}

#pragma mark - NotificationCenter methods

- (void)cancelActiveHTTPConnections 
{
    [self.likeRequest clearDelegatesAndCancel];
    [self.commentsRequest clearDelegatesAndCancel];
    [self.nodeLocationRequest clearDelegatesAndCancel];
}

- (void)applicationWillResignActive:(NSNotification *) notification
{
    NSLog(@"applicationWillResignActive in DocumnetViewController");
    [self cancelActiveHTTPConnections];
}

- (void)moviePlayerDidExitFullscreen:(NSNotification *)notification
{
    //This fixes an error in the iphone when the user rotates the device when previewing a video in fullscreen
    //The navigation bar would be covered by the status bar
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)documentUpdated:(NSNotification *)notification
{
    NSString *objectId = [[notification userInfo] objectForKey:@"objectId"];
    NSString *newPath = [[notification userInfo] objectForKey:@"newPath"];
    
    if ([objectId isEqualToString:self.cmisObjectId])
    {
        [self setFilePath:newPath];
        self.previewRequest = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:newPath]];
    }
}

/*
 Listening to the reachability changes to determine if we should enable/disable
 buttons that require an internet connection to work
 */
- (void)reachabilityChanged:(NSNotification *)notification
{
    BOOL enabledButton = [[ConnectivityManager sharedManager] hasInternetConnection];
    [self.editButton setEnabled:enabledButton];
    [self.likeBarButton.barButton setEnabled:enabledButton];
    [self.commentButton setEnabled:enabledButton];
    [self.favoriteButton.barButton setEnabled:enabledButton];
}

#pragma mark - File system support

- (NSString *)applicationDocumentsDirectory
{
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

@end
