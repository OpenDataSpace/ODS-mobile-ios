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
//  ActiveDownloadsViewController.m
//

#import "ActiveDownloadsViewController.h"
#import "DownloadInfo.h"
#import "DownloadManager.h"
#import "DownloadProgressTableViewCell.h"

NSInteger sortActiveDownloads(DownloadInfo *d1, DownloadInfo *d2, void *context)
{
    if (d1.downloadStatus == DownloadInfoStatusDownloading)
    {
        if (d2.downloadStatus == DownloadInfoStatusDownloading)
        {
            return NSOrderedSame;
        }
        return NSOrderedAscending;
    }
    if (d2.downloadStatus == DownloadInfoStatusDownloading)
    {
        return NSOrderedDescending;
    }
    return NSOrderedSame;
}

@interface ActiveDownloadsViewController ()
- (void)stopAllButtonAction:(id)sender;
@end

@implementation ActiveDownloadsViewController

@synthesize tableView = _tableView;
@synthesize activeDownloads = _activeDownloads;
@synthesize clearButton = _clearButton;
@synthesize alertView = _alertView;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.alertView setDelegate:nil];

    [_tableView release];
    [_activeDownloads release];
    [_clearButton release];
    [_alertView release];

    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadQueueChanged:) name:kNotificationDownloadQueueChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadStarted:) name:kNotificationDownloadStarted object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadFinished:) name:kNotificationDownloadFinished object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // View will hold the Stop All button
    UIView *tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 48.0f)];
    
    // UITableView
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    [tableView setDelegate:self];
    [tableView setDataSource:self];
    [tableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [self setTableView:tableView];
    
    // The Stop All custom button
    UIButton *stopAll = [UIButton buttonWithType:UIButtonTypeCustom];
    [stopAll setFrame:CGRectMake(64.0f, 8.0f, tableFooterView.frame.size.width - 128.0f, tableFooterView.frame.size.height - 16.0f)];
    [stopAll setTitle:NSLocalizedString(@"download.progress.stopAll", @"Stop All") forState:UIControlStateNormal];
    [stopAll.titleLabel setFont:[UIFont boldSystemFontOfSize:14.0f]];
    UIImage *buttonTemplate = [UIImage imageNamed:@"red-button"];
    UIImage *stretchedButtonImage = [buttonTemplate resizableImageWithCapInsets:UIEdgeInsetsMake(7.0f, 5.0f, 7.0f, 5.0f)];
    [stopAll setBackgroundImage:stretchedButtonImage forState:UIControlStateNormal];
    [stopAll addTarget:self action:@selector(stopAllButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    // Bind the views
    [tableFooterView addSubview:stopAll];
    [tableView setTableFooterView:tableFooterView];
    [self setView:tableView];
    
    [tableView release];
    [tableFooterView release];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSArray *activeDownloads = [[DownloadManager sharedManager] activeDownloads];
    [self setActiveDownloads:[NSMutableArray arrayWithArray:[activeDownloads sortedArrayUsingFunction:sortActiveDownloads context:NULL]]];
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)setActiveDownloads:(NSMutableArray *)activeDownloads
{
    [_activeDownloads autorelease];
    _activeDownloads = [activeDownloads retain];
    
    if ([_activeDownloads count] == 0)
    {
        [self.alertView dismissWithClickedButtonIndex:self.alertView.cancelButtonIndex animated:NO];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (NSIndexPath *)indexPathForObjectId:(NSString *)cmisObjectId
{
    NSIndexPath *indexPath = nil;

    for (DownloadInfo *downloadInfo in self.activeDownloads)
    {
        if ([downloadInfo.cmisObjectId isEqualToString:cmisObjectId])
        {
            indexPath = [NSIndexPath indexPathForRow:[self.activeDownloads indexOfObject:downloadInfo] inSection:0];
            break;
        }
    }
    
    return indexPath;
}

#pragma mark - UITableViewDataSource delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.activeDownloads count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DownloadProgressTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kDownloadProgressCellIdentifier];
    if (!cell)
    {
        cell = [[[DownloadProgressTableViewCell alloc] initWithIdentifier:kDownloadProgressCellIdentifier] autorelease];
    }
    [cell setDownloadInfo:[self.activeDownloads objectAtIndex:indexPath.row]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kDefaultTableCellHeight;
}

#pragma mark - Download notifications

- (void)downloadQueueChanged:(NSNotification *)notification
{
    if ([[DownloadManager sharedManager] activeDownloads].count == 0)
    {
        [self.alertView dismissWithClickedButtonIndex:self.alertView.cancelButtonIndex animated:NO];
        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        NSMutableArray *indexPaths = [NSMutableArray array];
        NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];

        for (NSUInteger index = 0; index < [self.activeDownloads count]; index++)
        {
            DownloadInfo *downloadInfo = [self.activeDownloads objectAtIndex:index];
            DownloadInfoStatus status = downloadInfo.downloadStatus;
            // Throw away inactive, downloaded or removed downloads
            if (status == DownloadInfoStatusInactive || status == DownloadInfoStatusDownloaded || [[DownloadManager sharedManager] isManagedDownload:downloadInfo.cmisObjectId] == NO)
            {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                [indexPaths addObject:indexPath];
                [indexSet addIndex:index];
            }
        }
        
        if ([indexPaths count] > 0)
        {
            [self.activeDownloads removeObjectsAtIndexes:indexSet];
            [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

- (void)downloadStarted:(NSNotification *)notification
{
    NSString *cmisObjectId = [notification.userInfo objectForKey:@"downloadObjectId"];
    NSIndexPath *indexPath = [self indexPathForObjectId:cmisObjectId];
    
    if (indexPath != nil && indexPath.row > 1)
    {
        NSInteger moveFromIndex = indexPath.row;
        NSInteger moveToIndex = 0;
        
        while ([(DownloadInfo *)[self.activeDownloads objectAtIndex:moveToIndex] downloadStatus] == DownloadInfoStatusDownloading)
        {
            moveToIndex++;
        }
        
        DownloadInfo *downloadInfo = [self.activeDownloads objectAtIndex:moveFromIndex];
        [self.activeDownloads removeObjectAtIndex:moveFromIndex];
        [self.activeDownloads insertObject:downloadInfo atIndex:moveToIndex];
        [self.tableView moveRowAtIndexPath:[NSIndexPath indexPathForRow:moveFromIndex inSection:0] toIndexPath:[NSIndexPath indexPathForRow:moveToIndex inSection:0]];
    }
}

- (void)downloadFinished:(NSNotification *)notification
{
    NSString *cmisObjectId = [notification.userInfo objectForKey:@"downloadObjectId"];
    NSIndexPath *indexPath = [self indexPathForObjectId:cmisObjectId];
    
    if (indexPath != nil)
    {
        DownloadProgressTableViewCell *cell = (DownloadProgressTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        [cell setDownloadInfo:nil];
        [self.activeDownloads removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - Button actions

- (void)stopAllButtonAction:(id)sender
{
    UIAlertView *confirmAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"download.cancel.title", @"Downloads")
                                                            message:NSLocalizedString(@"download.cancelAll.body", @"Would you like to...")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"No", @"No")
                                                  otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil] autorelease];
    [self setAlertView:confirmAlert];
    [confirmAlert show];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        [[DownloadManager sharedManager] cancelActiveDownloads];
    }
}

@end
