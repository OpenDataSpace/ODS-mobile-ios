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
// DocumentTableDelegate 
//
#import "DocumentTableDelegate.h"
#import "TaskDocumentViewCell.h"
#import "DocumentItem.h"
#import "NodeThumbnailHTTPRequest.h"
#import "AsyncLoadingUIImageView.h"
#import "ASIDownloadCache.h"
#import "ObjectByIdRequest.h"
#import "RepositoryItem.h"
#import "DownloadProgressBar.h"
#import "DocumentViewController.h"
#import "IpadSupport.h"
#import "Utility.h"
#import "MetaDataTableViewController.h"

#define TEXT_FONT_SIZE_IPAD 16
#define TEXT_FONT_SIZE_IPHONE 16

#define IPAD_CELL_HEIGHT_DOCUMENT_CELL 150.0
#define IPHONE_CELL_HEIGHT_DOCUMENT_CELL 50.0

@interface DocumentTableDelegate () <DownloadProgressBarDelegate>

@property (nonatomic, retain) ObjectByIdRequest *objectByIdRequest;
@property (nonatomic, retain) DownloadProgressBar *downloadProgressBar;
@property (nonatomic, retain) MBProgressHUD *HUD;
@property (nonatomic, retain) MetaDataTableViewController *metaDataViewController;

@end

@implementation DocumentTableDelegate

@synthesize documents = _documents;
@synthesize accountUUID = _accountUUID;
@synthesize tenantID = _tenantID;
@synthesize objectByIdRequest = _objectByIdRequest;
@synthesize viewBlockedByLoadingHud = _viewBlockedByLoadingHud;
@synthesize navigationController = _navigationController;
@synthesize tableView = _tableView;
@synthesize HUD = _HUD;
@synthesize downloadProgressBar = _downloadProgressBar;
@synthesize metaDataViewController = _metaDataViewController;

- (id)init
{
    if (self = [super init])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDocumentUpdated:) name:kNotificationDocumentUpdated object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_objectByIdRequest clearDelegatesAndCancel];
    [_objectByIdRequest release];

    [_tableView release];
    [_documents release];
    [_accountUUID release];
    [_tenantID release];
    [_HUD release];
    [_downloadProgressBar release];
    [_metaDataViewController release];
    [super dealloc];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.documents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    DocumentItem *documentItem = [self.documents objectAtIndex:indexPath.row];
    if (IS_IPAD)
    {
        TaskDocumentViewCell * cell = (TaskDocumentViewCell *) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil)
        {
            cell = [[[TaskDocumentViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        }

        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.nameLabel.text = documentItem.name;
        cell.nameLabel.font = [UIFont systemFontOfSize:(IS_IPAD ? TEXT_FONT_SIZE_IPAD : TEXT_FONT_SIZE_IPHONE)];
        cell.attachmentLabel.text = [NSString stringWithFormat:NSLocalizedString(@"task.detail.attachment", nil), indexPath.row + 1, self.documents.count];

        cell.thumbnailImageView.image = nil; // Need to set it to nil. Otherwise if cell was cached, the old image is seen for a brief moment
        NodeThumbnailHTTPRequest *request = [NodeThumbnailHTTPRequest httpRequestNodeThumbnail:documentItem.nodeRef
                                                                                   accountUUID:self.accountUUID
                                                                                      tenantID:self.tenantID];

        cell.infoButton.tag = indexPath.row;
        [cell.infoButton addTarget:self action:@selector(showDocumentMetaData:) forControlEvents:UIControlEventTouchUpInside];

        request.secondsToCache = 3600;
        request.downloadCache = [ASIDownloadCache sharedCache];
        [request setCachePolicy:ASIOnlyLoadIfNotCachedCachePolicy];
        [cell.thumbnailImageView setImageWithRequest:request];

        return cell;
    }
    else 
    {
        UITableViewCell * cell = (UITableViewCell *) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil)
        {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        }

        cell.textLabel.text = documentItem.name;
        cell.textLabel.textColor = [UIColor darkGrayColor];
        cell.textLabel.font = [UIFont systemFontOfSize:15];
        cell.imageView.image = imageForFilename(documentItem.name);

        UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
        [infoButton addTarget:self action:@selector(showDocumentMetaData:) forControlEvents:UIControlEventTouchUpInside];
        cell.accessoryView = infoButton;

        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (IS_IPAD)
    {
        return IPAD_CELL_HEIGHT_DOCUMENT_CELL;
    }
    return IPHONE_CELL_HEIGHT_DOCUMENT_CELL;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DocumentItem *documentItem = [self.documents objectAtIndex:indexPath.row];
    [self startObjectByIdRequest:documentItem.nodeRef];
}

#pragma mark - Document download

- (void)startObjectByIdRequest:(NSString *)objectId
{
    if (self.objectByIdRequest == nil)
    {
        self.objectByIdRequest = [ObjectByIdRequest defaultObjectById:objectId
                                                          accountUUID:self.accountUUID
                                                             tenantID:self.tenantID];
        [self.objectByIdRequest setDidFinishSelector:@selector(startDownloadRequest:)];
        [self.objectByIdRequest setDidFailSelector:@selector(objectByIdRequestFailed:)];
        [self.objectByIdRequest setDelegate:self];
        self.objectByIdRequest.suppressAllErrors = YES;

        [self startHUD];
        [self.objectByIdRequest startAsynchronous];
    }
}

- (void)objectByIdRequestFailed: (ASIHTTPRequest *)request
{
    self.objectByIdRequest = nil;
}

- (void)startDownloadRequest:(ObjectByIdRequest *)request
{
    RepositoryItem *repositoryNode = request.repositoryItem;

    if(repositoryNode.contentLocation && request.responseStatusCode < 400)
    {
        NSString *urlStr  = repositoryNode.contentLocation;
        NSURL *contentURL = [NSURL URLWithString:urlStr];
        [self setDownloadProgressBar:[DownloadProgressBar createAndStartWithURL:contentURL delegate:self
                                                                        message:NSLocalizedString(@"Downloading Document", @"Downloading Document")
                                                                       filename:repositoryNode.title
                                                                  contentLength:[repositoryNode contentStreamLength]
                                                                    accountUUID:[request accountUUID]
                                                                       tenantID:[request tenantID]]];
        [[self downloadProgressBar] setCmisObjectId:[repositoryNode guid]];
        [[self downloadProgressBar] setCmisContentStreamMimeType:[[repositoryNode metadata] objectForKey:@"cmis:contentStreamMimeType"]];
        [[self downloadProgressBar] setVersionSeriesId:[repositoryNode versionSeriesId]];
        [[self downloadProgressBar] setRepositoryItem:repositoryNode];
    }

    if(request.responseStatusCode >= 400)
    {
        [self objectByIdNotFoundDialog];
        self.objectByIdRequest = nil;
    }

    [self stopHUD];
}

- (void)objectByIdNotFoundDialog
{
    UIAlertView *objectByIdNotFound = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"activities.document.notfound.title", @"Document not found")
                                                                  message:NSLocalizedString(@"activities.document.notfound.message", @"The document could not be found")
                                                                 delegate:nil
                                                        cancelButtonTitle:NSLocalizedString(@"Continue", nil)
                                                        otherButtonTitles:nil] autorelease];
	[objectByIdNotFound show];
}

#pragma mark - DownloadProgressBar Delegate

- (void)download:(DownloadProgressBar *)downloadProgressBar completeWithPath:(NSString *)filePath
{
	DocumentViewController *documentViewController = [[DocumentViewController alloc] initWithNibName:kFDDocumentViewController_NibName bundle:[NSBundle mainBundle]];
	[documentViewController setCmisObjectId:downloadProgressBar.cmisObjectId];
    [documentViewController setContentMimeType:[downloadProgressBar cmisContentStreamMimeType]];
    [documentViewController setHidesBottomBarWhenPushed:YES];
    [documentViewController setSelectedAccountUUID:[downloadProgressBar selectedAccountUUID]];
    [documentViewController setTenantID:downloadProgressBar.tenantID];
    [documentViewController setShowReviewButton:NO];

    DownloadMetadata *fileMetadata = downloadProgressBar.downloadMetadata;
    NSString *filename;

    if(fileMetadata.key)
    {
        filename = fileMetadata.key;
    }
    else
    {
        filename = downloadProgressBar.filename;
    }

    [documentViewController setFileName:filename];
    [documentViewController setFilePath:filePath];
    [documentViewController setFileMetadata:fileMetadata];
    [documentViewController setIsRestrictedDocument:[[AlfrescoMDMLite sharedInstance] isRestrictedDocument:fileMetadata]];

	[IpadSupport addFullScreenDetailController:documentViewController withNavigation:self.navigationController
                                     andSender:self backButtonTitle:NSLocalizedString(@"Close", nil)];
	[documentViewController release];
    
    // Allow new objectByIdRequests
    self.objectByIdRequest = nil;
}

- (void) downloadWasCancelled:(DownloadProgressBar *)down
{
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    // Allow new objectByIdRequests
    self.objectByIdRequest = nil;
}

#pragma mark - MBProgressHUD Helper Methods
- (void)startHUD
{
	if (!self.HUD)
    {
        self.HUD = createAndShowProgressHUDForView(self.viewBlockedByLoadingHud);
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

#pragma mark - Document metadata

- (void)showDocumentMetaData:(UIButton *)button
{
    DocumentItem *documentItem = [self.documents objectAtIndex:button.tag];
    self.objectByIdRequest = [ObjectByIdRequest defaultObjectById:documentItem.nodeRef
                                                      accountUUID:self.accountUUID
                                                         tenantID:self.tenantID];
    self.objectByIdRequest.suppressAllErrors = YES;
    [self.objectByIdRequest setCompletionBlock:^{

        [self stopHUD];

        MetaDataTableViewController *metaDataViewController =
                [[MetaDataTableViewController alloc] initWithStyle:UITableViewStylePlain
                                                        cmisObject:self.objectByIdRequest.repositoryItem
                                                       accountUUID:self.accountUUID
                                                          tenantID:self.tenantID];
        [metaDataViewController setCmisObjectId:self.objectByIdRequest.repositoryItem.guid];
        [metaDataViewController setMetadata:self.objectByIdRequest.repositoryItem.metadata];

        self.metaDataViewController = metaDataViewController;
        [metaDataViewController release];

        if (IS_IPAD)
        {

            self.metaDataViewController.modalPresentationStyle = UIModalPresentationFormSheet;
            self.metaDataViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

            UIBarButtonItem *closeButton = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"Close")
                                                                             style:UIBarButtonItemStyleDone
                                                                            target:self
                                                                            action:@selector(documentMetaDataCancelButtonTapped:)] autorelease];
            [self.metaDataViewController.navigationItem setLeftBarButtonItem:closeButton];
            [IpadSupport presentModalViewController:self.metaDataViewController withNavigation:nil];
        }
        else
        {
            [self.navigationController pushViewController:self.metaDataViewController animated:YES];
        }

    }];
    [self.objectByIdRequest setFailedBlock:^{
        [self stopHUD];
        NSLog(@"Could not fetch metadata for node %@", documentItem.nodeRef);
    }];

    self.objectByIdRequest.suppressAllErrors = YES;

    [self startHUD];
    [self.objectByIdRequest startAsynchronous];
}

- (void)documentMetaDataCancelButtonTapped:(id)sender
{
    [self.metaDataViewController dismissModalViewControllerAnimated:YES];
}

#pragma mark - NSNotification handlers

- (void)handleDocumentUpdated:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSString *objectId = [userInfo objectForKey:@"objectId"];
    for (DocumentItem *documentItem in self.documents)
    {
        if ([documentItem.nodeRef isEqualToString:objectId])
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.documents indexOfObject:documentItem] inSection:0];
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
    }
}

@end
