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
#import "DownloadMetadata.h"
#import "IpadSupport.h"
#import "AlfrescoAppDelegate.h"

@interface DocumentPreviewUrlHandler ()
@property (nonatomic, retain) NSString *urlSchema;
@property (nonatomic, retain) ObjectByIdRequest *objectByIdRequest;

- (void)hideHUDForWindow;
- (void)previewManager:(PreviewManager *)manager downloadCancelled:(DownloadInfo *)info;
@end

@implementation DocumentPreviewUrlHandler
@synthesize urlSchema = _urlSchema;
@synthesize objectByIdRequest = _objectByIdRequest;

static NSString * const PREFIX = @"doc-preview";

- (void)dealloc
{
    // Clear the request delegate and cancel to prevent memory leak
    [self.objectByIdRequest clearDelegatesAndCancel];

    // Just being safe and ensuring that we cleanup.
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_urlSchema release];
    [_objectByIdRequest release];
    
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
    // TODO Notify when there is no network and stop
    //

    // Fixing issue with the mailto URL not properly unencoding the ampersand
    NSString *fixedStr = [[url absoluteString] stringByReplacingOccurrencesOfString:@"%26" withString:@"&"];
    url = [NSURL URLWithString:fixedStr];

    NSDictionary *queryPairs = [url queryPairs];
    NSString *objectId = [queryPairs objectForKey:@"objectId"];
    NSString *hostname = [queryPairs objectForKey:@"hostname"];

    NSLog(@"%@: Document Preview Object ID: %@", hostname, objectId);
    
    // Check that we have an account setup with the same hostname
    AccountInfo *account = [[AccountManager sharedManager] accountInfoForHostname:hostname];
    if (account == nil)
    {    
        // Account with same host name not found, alert user.
        [self showAlertWithTitle:@"Account Required" message:[NSString stringWithFormat:@"To preview this document, an account must be configured for host %@", hostname] ];
        
        return;
    }
    
    
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    
    // The hud will dispable all input on the window
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillResignActiveNotification) 
                                                 name:UIApplicationWillResignActiveNotification object:nil];
    MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:window animated:YES];
	HUD.labelText = @"Loading Preview";
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.minShowTime = 1.5f;
    HUD.dimBackground = YES;

    ObjectByIdRequest *request = [ObjectByIdRequest defaultObjectById:objectId accountUUID:account.uuid tenantID:nil];
    
    // Request Completion Block
    [request setCompletionBlock:
     ^{  
         if ( !request.responseSuccessful ) 
         {
             NSLog(@"%d Response Code", request.responseStatusCode);
             
             [request failWithError:nil];
             
             return;
         }
         
         // Request was successful, don't hide HUD, we allow the PreviewManagerDelegate methods hide the HUD
         RepositoryItem *repoItem = request.repositoryItem;
         [[PreviewManager sharedManager] previewItem:repoItem delegate:self accountUUID:request.accountUUID tenantID:request.tenantID];
    }];
    
    // Request Failure Block
    [request setFailedBlock:
     ^{
        [self hideHUDForWindow];

        [self showAlertWithTitle:@"Connection Error" message:@"There was an issue with the preview please try again later"];
    }];
    
    [request startAsynchronous];
}

- (void)handleApplicationWillResignActiveNotification
{
    // Hiding the HUD when the application resigns active so that the app wont get 
    // locked out in the case the HUD does not hide for some off reason
    [self hideHUDForWindow];
    
    // 
    // TODO We should perhaps kill any requests that happening.
    //
}

#pragma mark -
#pragma mark Preview Manager Delegate Methods

- (void)hideHUDForWindow
{
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    [MBProgressHUD hideHUDForView:window animated:YES];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title
                                                      message:message
                                                     delegate:nil 
                                            cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK") 
                                            otherButtonTitles:nil, nil] autorelease];
    [alert show];
}

- (void)previewManager:(PreviewManager *)manager downloadCancelled:(DownloadInfo *)info
{
    [self hideHUDForWindow];
    [self showAlertWithTitle:@"Download Canceled" message:@"Download was cancelled"];
}

- (void)previewManager:(PreviewManager *)manager downloadFailed:(DownloadInfo *)info withError:(NSError *)error
{
    [self hideHUDForWindow];
    [self showAlertWithTitle:@"Download Failed" message:@"Failed to download the document for previewing"];
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
    docViewController.fileMetadata = info.downloadMetadata;
    docViewController.fileName = info.downloadMetadata.key;
    docViewController.filePath = info.tempFilePath;
    
    AlfrescoAppDelegate *appDelegate = (AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate];
	[IpadSupport pushDetailController:docViewController withNavigation:appDelegate.navigationController andSender:self];
}




@end
