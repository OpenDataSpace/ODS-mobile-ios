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
 *
 * ***** END LICENSE BLOCK ***** */
//
//  FailedDownloadsViewController.m
//

#import "FailedDownloadsViewController.h"
#import "DownloadInfo.h"
#import "DownloadManager.h"
#import "DownloadFailureTableViewCell.h"
#import "FailedDownloadDetailViewController.h"
#import "UIColor+Theme.h"
#import "Utility.h"

@interface FailedDownloadsViewController ()

@end

@implementation FailedDownloadsViewController

@synthesize tableView = _tableView;
@synthesize failedDownloads = _failedDownloads;
@synthesize popover = _popover;
@synthesize downloadToDismiss = _downloadToDismiss;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.popover setDelegate:nil];

    [_tableView release];
    [_failedDownloads release];
    [_popover release];
    [_downloadToDismiss release];
    
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadQueueChanged:) name:kNotificationDownloadQueueChanged object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // View will hold the clear button
    UIView *tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 48.0f)];
    
    // UITableView
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    [tableView setDelegate:self];
    [tableView setDataSource:self];
    [tableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [self setTableView:tableView];

    // The Clear All custom button
    UIButton *clearAll = [UIButton buttonWithType:UIButtonTypeCustom];
    [clearAll setFrame:CGRectMake(64.0f, 8.0f, tableFooterView.frame.size.width - 128.0f, tableFooterView.frame.size.height - 16.0f)];
    [clearAll setTitle:NSLocalizedString(@"download.failures.clearAll", @"Clear All") forState:UIControlStateNormal];
    [clearAll.titleLabel setFont:[UIFont boldSystemFontOfSize:14.0f]];
    UIImage *buttonTemplate = [UIImage imageNamed:@"red-button"];
    UIImage *stretchedButtonImage = [buttonTemplate resizableImageWithCapInsets:UIEdgeInsetsMake(7.0f, 5.0f, 7.0f, 5.0f)];
    [clearAll setBackgroundImage:stretchedButtonImage forState:UIControlStateNormal];
    [clearAll addTarget:self action:@selector(clearButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    // Bind the views
    [tableFooterView addSubview:clearAll];
    [tableView setTableFooterView:tableFooterView];
    [self setView:tableView];

    [tableView release];
    [tableFooterView release];

    // Retry All toolbar button
    UIBarButtonItem *retryButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"download.failures.retryAll", @"Retry All") style:UIBarButtonItemStyleBordered target:self action:@selector(retryButtonAction:)];
    [self.navigationItem setRightBarButtonItem:retryButton];
    [retryButton release];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setFailedDownloads:[NSMutableArray arrayWithArray:[[DownloadManager sharedManager] failedDownloads]]];
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)setFailedDownloads:(NSMutableArray *)failedDownloads
{
    [_failedDownloads autorelease];
    _failedDownloads = [failedDownloads retain];
    
    if ([_failedDownloads count] == 0)
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - UITableViewDataSource delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.failedDownloads count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DownloadFailureTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kDownloadFailureCellIdentifier];
    if (!cell)
    {
        cell = [[[DownloadFailureTableViewCell alloc] initWithIdentifier:kDownloadFailureCellIdentifier] autorelease];
    }
    [cell setDownloadInfo:[self.failedDownloads objectAtIndex:indexPath.row]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kDefaultTableCellHeight;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    DownloadInfo *downloadInfo = [self.failedDownloads objectAtIndex:indexPath.row];
    [self setDownloadToDismiss:downloadInfo];
    if (IS_IPAD)
    {
        FailedDownloadDetailViewController *viewController = [[FailedDownloadDetailViewController alloc] initWithDownloadInfo:downloadInfo];
        [viewController setCloseTarget:self];
        [viewController setCloseAction:@selector(closeFailedDownload:)];
        
        UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:viewController];
        [self setPopover:popoverController];
        [popoverController setPopoverContentSize:viewController.view.frame.size];
        [popoverController setDelegate:self];
        [popoverController release];
        [viewController release];
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [self.popover presentPopoverFromRect:cell.accessoryView.frame inView:cell permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    else
    {
        UIAlertView *downloadFailDetail = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"download.failureDetail.title", @"Failed Download") message:[downloadInfo.error localizedDescription]  delegate:self cancelButtonTitle:NSLocalizedString(@"Close", @"Close") otherButtonTitles:NSLocalizedString(@"Retry", @"Retry"), nil];
        [downloadFailDetail show];
        [downloadFailDetail release];
    }
}

#pragma mark - FailedDownloadDetailViewController Delegate

// Called from the FailedDownloadDetailViewController and it means the user retry the failed upload
- (void)closeFailedDownload:(FailedDownloadDetailViewController *)sender
{
    if (nil != self.popover && [self.popover isPopoverVisible]) 
    {
        [self.popover setDelegate:nil];
        [self.popover dismissPopoverAnimated:YES];
        [self setPopover:nil];
    }
}

#pragma mark - UIPopoverController Delegate methods

// Called when the popover was dismissed by the user by tapping in another part of the screen,
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [[DownloadManager sharedManager] clearDownload:self.downloadToDismiss.cmisObjectId];
}

#pragma mark - UIAlertView

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (IS_IPAD)
    {
		if (nil != self.popover && [self.popover isPopoverVisible])
        {
			[self.popover dismissPopoverAnimated:YES];
            [self setPopover:nil];
		}
	}
    
    if (buttonIndex == alertView.cancelButtonIndex)
    {
        [[DownloadManager sharedManager] clearDownload:self.downloadToDismiss.cmisObjectId];
    }
    else
    {
        [[DownloadManager sharedManager] retryDownload:self.downloadToDismiss.cmisObjectId];
    }
}

#pragma mark - Download notifications

- (void)downloadQueueChanged:(NSNotification *)notification
{
    [self setFailedDownloads:[NSMutableArray arrayWithArray:[[DownloadManager sharedManager] failedDownloads]]];
    [self.tableView reloadData];
}

#pragma mark - Button actions

- (void)retryButtonAction:(id)sender
{
    for (DownloadInfo *downloadInfo in self.failedDownloads)
    {
        [[DownloadManager sharedManager] retryDownload:downloadInfo.cmisObjectId];
    }
}

- (void)clearButtonAction:(id)sender
{
    NSMutableArray *downloadObjectIds = [NSMutableArray arrayWithCapacity:[self.failedDownloads count]];
    for (DownloadInfo *downloadInfo in self.failedDownloads)
    {
        [downloadObjectIds addObject:downloadInfo.cmisObjectId];
    }

    [[DownloadManager sharedManager] clearDownloads:downloadObjectIds];
}

@end
