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
//  DocumentPreviewUrlHandler.m
//

#import "DocumentPreviewUrlHandler.h"
#import "ObjectByIdRequest.h"
#import "NSURL+HTTPURLUtils.h"
#import "AccountManager.h"
#import "DocumentViewController.h"
#import "DownloadInfo.h"
#import "RepositoryItem.h"
#import "IpadSupport.h"
#import "AlfrescoAppDelegate.h"
#import "AppProperties.h"

@interface DocumentPreviewUrlHandler ()
@property (nonatomic, retain) NSString *urlSchema;
@property (nonatomic, retain) ObjectByIdRequest *objectByIdRequest;
@property (nonatomic, retain) MBProgressHUD *hud;
@property (nonatomic, retain) NSString *accountUUID;
@property (nonatomic, retain) NSString *tenantID;
@property (nonatomic, retain) NSString *objectId;
@property (nonatomic, retain) NSString *userName;
@property (nonatomic, retain) NSURL *repositoryUrl;
@property (nonatomic, retain) NSURL *browserUrl;

- (void)hideHUDForWindow;
- (void)previewManager:(PreviewManager *)manager downloadCancelled:(DownloadInfo *)info;
@end

@implementation DocumentPreviewUrlHandler
@synthesize urlSchema = _urlSchema;
@synthesize objectByIdRequest = _objectByIdRequest;
@synthesize hud = _hud;
@synthesize accountUUID = _accountUUID;
@synthesize tenantID = _tenantID;
@synthesize objectId = _objectId;
@synthesize userName = _userName;
@synthesize repositoryUrl = _repositoryUrl;
@synthesize browserUrl = _browserUrl;

static NSString * const PREFIX = @"doc-preview";

- (void)dealloc
{
    // Clear the request delegate and cancel to prevent memory leak
    [self.objectByIdRequest clearDelegatesAndCancel];

    // Cleanup notification observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_urlSchema release];
    [_objectByIdRequest release];
    [_hud release];
    [_accountUUID release];
    [_tenantID release];
    [_objectId release];
    [_userName release];
    [_repositoryUrl release];
    [_browserUrl release];
    
    [super dealloc];
}

- (NSString *)handledUrlPrefix:(NSString *)defaultAppScheme
{
    [self setUrlSchema:defaultAppScheme];
    
    return [defaultAppScheme stringByAppendingString:PREFIX];
}

- (void)handleUrl:(NSURL *)url annotation:(id)annotation
{
    //
    // TODO: Notify when there is no network and stop
    //

    /**
     * mhatfield: Removed, as this prevents us passing complex URLs from web pages
     * TODO: Understand the issue this was put in place to fix.
     
    // Fixing issue with the mailto URL not properly unencoding the ampersand
    NSString *fixedStr = [[url absoluteString] stringByReplacingOccurrencesOfString:@"%26" withString:@"&"];
    url = [NSURL URLWithString:fixedStr];
     
     */

    NSDictionary *queryPairs = [url queryPairs];
    [self setTenantID:[queryPairs objectForKey:@"tenant"]];
    [self setObjectId:[queryPairs objectForKey:@"objectId"]];
    [self setUserName:[queryPairs objectForKey:@"user"]];
    [self setRepositoryUrl:[NSURL URLWithString:[queryPairs objectForKey:@"repositoryUrl"]]];
    [self setBrowserUrl:[NSURL URLWithString:[queryPairs objectForKey:@"browserUrl"]]];

    NSString *cloudHostname = [AppProperties propertyForKey:kAlfrescoCloudHostname];
    BOOL isCloud = [self.browserUrl.host isEqualToCaseInsensitiveString:cloudHostname];

    NSLog(@"%@: Document Preview Object ID: %@ and TenantID: %@", self.repositoryUrl, self.objectId, self.tenantID);
    
    // Check that we have an account setup with the same hostname
    AccountInfo *account = [[AccountManager sharedManager] accountInfoForHostname:self.repositoryUrl.host username:self.userName includeInactiveAccounts:YES];
    if (account == nil)
    {
        // Account with same host name not found.
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"AccountAutocreateConfiguration" ofType:@"plist"];
        AccountAutocreateViewController *viewController = [AccountAutocreateViewController genericTableViewWithPlistPath:plistPath andTableViewStyle:UITableViewStyleGrouped];
        [viewController setDelegate:self];
        
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
        [navController setModalPresentationStyle:UIModalPresentationFormSheet];
        [navController setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];

        AlfrescoAppDelegate *appDelegate = (AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate presentModalViewController:navController animated:YES];

        CGRect bounds = navController.view.superview.bounds;
        [viewController setData:[NSDictionary dictionaryWithObjectsAndKeys:
                                 self.userName, @"userName",
                                 self.repositoryUrl, @"repositoryUrl",
                                 self.browserUrl, @"browserUrl",
                                 [NSNumber numberWithBool:isCloud], @"isCloud",
                                 [NSValue valueWithCGRect:bounds], @"originalBounds",
                                 nil]];

        if (IS_IPAD)
        {
            // Shrink the view slightly
            [navController.view.superview setBounds:CGRectMake(0, 0, bounds.size.width, 340)];
        }
        [navController release];

        [appDelegate setSuppressHomeScreen:YES];
    }
    else if (account.accountStatus == FDAccountStatusInactive)
    {
        // Account with same host name was found, but is currently inactive
        // TODO: Ask user to navigate to account to activate?
        [self showAlertWithTitle:NSLocalizedString(@"docpreview.accountInactive.title", @"Account Inactive")
                         message:[NSString stringWithFormat:NSLocalizedString(@"docpreview.accountInactive.message", @"To preview this document, the account for host %@ must be activated"), self.repositoryUrl]];
    }
    else
    {
        // We should be able to request the object now
        [self setAccountUUID:account.uuid];
        [self startObjectByIdRequest];
    }
}

- (void)startObjectByIdRequest
{
    [self startObjectByIdRequest:NO];
}

- (void)startObjectByIdRequest:(BOOL)hasRequestedCMISServiceDocument
{
    // Check we can create an ObjectByIdRequest object
    ObjectByIdRequest *request = [ObjectByIdRequest defaultObjectById:self.objectId accountUUID:self.accountUUID tenantID:self.tenantID];

    if (request == nil)
    {
        if (hasRequestedCMISServiceDocument)
        {
            // We still can't get a request object - failure
            [self showGeneralFailureMessage];
        }
        else
        {
            // Initiate a CMISServiceDocument request - the request success will call back into this method
            CMISServiceManager *serviceManager = [CMISServiceManager sharedManager];
            [serviceManager addListener:self forAccountUuid:self.accountUUID];
            [serviceManager loadServiceDocumentForAccountUuid:self.accountUUID];
        }
    }
    else
    {
        UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
        
        // The hud will disable all input on the window
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleApplicationWillResignActiveNotification)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
        
        MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:window animated:YES]; // autoreleased
        HUD.labelText = NSLocalizedString(@"docpreview.loadingPreview", @"Loading Preview");
        HUD.mode = MBProgressHUDModeIndeterminate;
        HUD.minShowTime = .5f;
        HUD.dimBackground = YES;
        [self setHud:HUD];
        
        [request setPromptPasswordDelegate:self];
        [request setWillPromptPasswordSelector:@selector(willPromptPassword:)];
        [request setFinishedPromptPasswordSelector:@selector(finishedPromptPassword:)];
        [request setCancelledPromptPasswordSelector:@selector(cancelledPromptPassword:)];
        
        // Request Completion Block
        [request setCompletionBlock:^{
            if (!request.responseSuccessful)
            {
                NSLog(@"%d Response Code", request.responseStatusCode);
                [self showGeneralFailureMessage];
            }
            else
            {
                // Request was successful, don't hide HUD, we allow the PreviewManagerDelegate methods hide the HUD
                RepositoryItem *repoItem = request.repositoryItem;
                [[PreviewManager sharedManager] previewItem:repoItem delegate:self accountUUID:request.accountUUID tenantID:request.tenantID];
            }
        }];
        
        // Request Failure Block
        [request setFailedBlock:^{
            [self showGeneralFailureMessage];
        }];
        
        [self setObjectByIdRequest:request];
        [request startAsynchronous];
    }
}

- (void)showGeneralFailureMessage
{
    [self hideHUDForWindow];
    [self showAlertWithTitle:NSLocalizedString(@"connectionErrorTitle", @"Connection Error")
                     message:NSLocalizedString(@"docpreview.errorLoading", @"There was an issue with the preview please try again later")];
}

- (void)handleApplicationWillResignActiveNotification
{
    // Hiding the HUD when the application resigns active so that the app wont get
    // locked out in the case the HUD does not hide for some off reason
    [self hideHUDForWindow];
}

#pragma mark - Preview Manager Delegate Methods

- (void)hideHUDForWindow
{
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    [MBProgressHUD hideHUDForView:window animated:YES];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message
{
    displayErrorMessageWithTitle(message, title);
}

- (void)previewManager:(PreviewManager *)manager downloadCancelled:(DownloadInfo *)info
{
    [self showGeneralFailureMessage];
}

- (void)previewManager:(PreviewManager *)manager downloadFailed:(DownloadInfo *)info withError:(NSError *)error
{
    [self showGeneralFailureMessage];
}

- (void)previewManager:(PreviewManager *)manager downloadFinished:(DownloadInfo *)info
{
    [self hideHUDForWindow];
    
    // Setup the DocumentViewController and display
    DocumentViewController *docViewController = [[[DocumentViewController alloc] initWithNibName:kFDDocumentViewController_NibName bundle:[NSBundle mainBundle]] autorelease];
    docViewController.cmisObjectId = info.repositoryItem.guid;
    docViewController.contentMimeType = info.repositoryItem.contentStreamMimeType;
    docViewController.hidesBottomBarWhenPushed = YES;
    docViewController.selectedAccountUUID = info.selectedAccountUUID;
    docViewController.tenantID = info.tenantID;
    docViewController.showReviewButton = YES;
    docViewController.fileMetadata = info.downloadMetadata;
    docViewController.fileName = info.downloadMetadata.key;
    docViewController.filePath = info.tempFilePath;
    docViewController.isRestrictedDocument = [[AlfrescoMDMLite sharedInstance] isRestrictedDocument:info.downloadMetadata];
    
    AlfrescoAppDelegate *appDelegate = (AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate];
    UINavigationController *navController = appDelegate.documentsNavController;
    [appDelegate.tabBarController setSelectedViewController:navController];
    // Display document fullscreen
    [IpadSupport pushDetailController:docViewController withNavigation:navController andSender:self dismissPopover:YES showFullScreen:YES];
}

#pragma mark - PromptPassword delegate methods

- (void)willPromptPassword:(BaseHTTPRequest *)request
{
    [self.hud setHidden:YES];
}

- (void)finishedPromptPassword:(BaseHTTPRequest *)request
{
    [self.hud setHidden:NO];
}

- (void)cancelledPromptPassword:(BaseHTTPRequest *)request
{
    [self.hud setHidden:NO];
}

#pragma mark - CMISServiceManagerListener Methods

- (void)serviceDocumentRequestFinished:(ServiceDocumentRequest *)serviceRequest
{
    [[CMISServiceManager sharedManager] removeListener:self forAccountUuid:self.accountUUID];
    // Let's try the ObjectByIdRequest again
    [self startObjectByIdRequest:YES];
}

- (void)serviceDocumentRequestFailed:(ServiceDocumentRequest *)serviceRequest
{
    [[CMISServiceManager sharedManager] removeListener:self forAccountUuid:self.accountUUID];
    [self showGeneralFailureMessage];
}

#pragma mark - AccountViewControllerDelegate

- (void)accountControllerDidFinishSaving:(UIViewController *)accountViewController
{
    // Account hasn't been persisted yet - need to wait for the notification for that
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAccountListUpdated:) name:kNotificationAccountListUpdated object:nil];
}

- (void)accountControllerDidCancel:(UIViewController *)accountViewController
{
    // Nothing to do here.
}

#pragma mark - Account List Updated Notification Handler

- (void)handleAccountListUpdated:(NSNotification *)notification
{
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(handleAccountListUpdated:) withObject:notification waitUntilDone:NO];
        return;
    }

    NSDictionary *userInfo = [notification userInfo];
    NSString *type = [userInfo objectForKey:@"type"];
    
    if ([type isEqualToString:kAccountUpdateNotificationAdd])
    {
        // Don't listen for any more account creations
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationAccountListUpdated object:nil];
        
        NSString *uuid = [userInfo objectForKey:@"uuid"];
        AccountInfo *account = [[AccountManager sharedManager] accountInfoForUUID:uuid];

        if (account != nil)
        {
            // We should be able to request the object now
            [self setAccountUUID:account.uuid];
            [self startObjectByIdRequest];
        }
    }
}

@end
