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
//  FavoriteTableCellWrapper.m
//

#import "FavoriteTableCellWrapper.h"
#import "RepositoryItem.h"
#import "UploadInfo.h"
#import "UploadProgressTableViewCell.h"
#import "FavoriteTableViewCell.h"
#import "Utility.h"
#import "AppProperties.h"
//#import "PreviewManager.h"
#import "FavoriteDownloadManager.h"
#import "FavoritesUploadManager.h"
#import "PreviewManager.h"
#import "FavoritesDownloadManagerDelegate.h"
#import "FavoriteManager.h"
#import "AlfrescoMDMLite.h"

const float yPositionOfStatusImageWithAccountName = 48.0f;
const float yPositionOfStatusImageWithoutAccountName = 36.0f;

@implementation FavoriteTableCellWrapper

@synthesize itemTitle = _itemTitle;
@synthesize repositoryItem = _repositoryItem;
@synthesize uploadInfo = _uploadInfo;
@synthesize isSearchError = _isSearchError;
@synthesize searchStatusCode = _searchStatusCode;
@synthesize tableView = _tableView;
@synthesize isActivityInProgress = _isActivityInProgress;
@synthesize isPreviewInProgress = _isPreviewInProgress;
@synthesize cell = _cell;
@synthesize fileSize = _fileSize;
@synthesize syncStatus = _syncStatus;
@synthesize documentIsFavorite = _documentIsFavorite;
@synthesize activityType = _activityType;

@synthesize accountUUID = _accountUUID;
@synthesize tenantID = _tenantID;

- (void)dealloc
{
    [_itemTitle release];
    [_repositoryItem release];
    [_uploadInfo release];
    [_tableView release];
    [_cell release];
    [_fileSize release];
    [_accountUUID release];
    [_tenantID release];
    [super dealloc];
}

- (id)initWithUploadInfo:(UploadInfo *)uploadInfo
{
    self = [super init];
    if (self)
    {
        [self setUploadInfo:uploadInfo];
    }
    return self;
}

- (id)initWithRepositoryItem:(RepositoryItem *)repositoryItem
{
    self = [super init];
    if (self)
    {
        [self setRepositoryItem:repositoryItem];
        self.syncStatus = SyncStatusDisabled;
        self.documentIsFavorite = YES;
        self.activityType = SyncActivityTypeIdle;
    }
    return self;    
}

- (RepositoryItem *)anyRepositoryItem
{
    if (self.repositoryItem)
    {
        return self.repositoryItem;
    }
    else if (self.uploadInfo.repositoryItem) 
    {
        return self.uploadInfo.repositoryItem;
    }
    
    return nil;
}

- (void)setIsActivityInProgress:(BOOL)isActivityInProgress
{
    _isActivityInProgress = isActivityInProgress;
    
    if (isActivityInProgress)
    {
        [self.cell setAccessoryView:[self makeCancelPreviewDisclosureButton]];
    }
    else
    {
        [self.cell setAccessoryView:[self makeDetailDisclosureButton]];
    }
    
}

- (UITableViewCell *)createUploadCellInTableView:(UITableView *)tableView
{
    UploadProgressTableViewCell *uploadCell = [tableView dequeueReusableCellWithIdentifier:@"UploadProgressTableViewCell"];
    if (!uploadCell)
    {
        uploadCell = [[[UploadProgressTableViewCell alloc] initWithIdentifier:@"UploadProgressTableViewCell"] autorelease];
    }
    [self setCell:uploadCell];
    [uploadCell setUploadInfo:self.uploadInfo];
    return uploadCell;
}

- (UIButton *)makeDetailDisclosureButton
{
    UIButton *button = nil;
    BOOL showMetadataDisclosure = [[AppProperties propertyForKey:kBShowMetadataDisclosure] boolValue];
    if (showMetadataDisclosure)
    {
        button = [UIButton buttonWithType:UIButtonTypeInfoDark];
        button.tag = 0;
        [button addTarget:self action:@selector(accessoryButtonTapped:withEvent:) forControlEvents:UIControlEventTouchUpInside];
    }
    return button;
}

- (UIButton *)makeCancelPreviewDisclosureButton
{
    UIImage *buttonImage = [UIImage imageNamed:@"stop-transfer"];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height)];
    [button setImage:buttonImage forState:UIControlStateNormal];
    [button setShowsTouchWhenHighlighted:YES];
    button.tag = 1;
    [button addTarget:self action:@selector(accessoryButtonTapped:withEvent:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIButton *)makeFailureDisclosureButton
{
    UIImage *errorBadgeImage = [UIImage imageNamed:@"ui-button-bar-badge-error.png"];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:CGRectMake(0, 0, errorBadgeImage.size.width, errorBadgeImage.size.height)];
    [button setBackgroundImage:errorBadgeImage forState:UIControlStateNormal];
    button.tag = 2;
    [button addTarget:self action:@selector(accessoryButtonTapped:withEvent:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)accessoryButtonTapped:(UIControl *)button withEvent:(UIEvent *)event
{
    NSIndexPath * indexPath = [self.tableView indexPathForRowAtPoint:[[[event touchesForView:button] anyObject] locationInView:self.tableView]];
    if (indexPath != nil)
    {
        [self.tableView.delegate tableView:self.tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
    }
}

- (UITableViewCell *)createSearchErrorCellInTableView:(UITableView *)tableView
{
    return nil;
}

- (UITableViewCell *)createRepositoryInfoCellInTableView:(UITableView *)tableView
{
    FavoriteTableViewCell *cell = (FavoriteTableViewCell *) [tableView dequeueReusableCellWithIdentifier:FavoriteTableCellIdentifier];
    if (cell == nil)
    {
		NSArray *nibItems = [[NSBundle mainBundle] loadNibNamed:@"FavoriteTableViewCell" owner:self options:nil];
		cell = [nibItems objectAtIndex:0];
		NSAssert(nibItems, @"Failed to load object from NIB");
        
        CGRect frame = cell.restrictedImage.frame;
        frame.origin.x = cell.frame.size.width - cell.restrictedImage.frame.size.width;
        cell.restrictedImage.frame = frame;
        
        [cell addSubview:cell.restrictedImage];
    }
    
    if ([[[AccountManager sharedManager] activeAccounts] count] < 2)
    {
        cell.serverName.hidden = YES;
        CGRect cellStatusFrame = cell.status.frame;
        cellStatusFrame.origin.y = yPositionOfStatusImageWithoutAccountName;
        cell.status.frame = cellStatusFrame;
    }
    else
    {
        cell.serverName.hidden = NO;
        CGRect cellStatusFrame = cell.status.frame;
        cellStatusFrame.origin.y = yPositionOfStatusImageWithAccountName;
        cell.status.frame = cellStatusFrame;
    }
    
    [self setCell:cell];
    
    // Highlight colours
    [cell.filename setHighlightedTextColor:[UIColor whiteColor]];
    [cell.details setHighlightedTextColor:[UIColor whiteColor]];
    
    RepositoryItem *child = [self anyRepositoryItem];
    NSString *filename = [child.metadata valueForKey:@"cmis:name"];
    if (!filename || ([filename length] == 0))
    {
        filename = child.title;
    }
    [cell.filename setText:filename];
    [cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
    [self setIsActivityInProgress:NO];
    
    AccountInfo *accountInfo = [[AccountManager sharedManager] accountInfoForUUID:self.accountUUID];
    cell.serverName.text = [accountInfo description];
    
    if ([child isFolder])
    {
        UIImage *img = [UIImage imageNamed:@"folder.png"];
        cell.imageView.image = img;
        cell.details.text = [[[NSString alloc] initWithFormat:@"%@", formatDocumentDate(child.lastModifiedDate)] autorelease]; // TODO: Externalize to a configurable property?        
    }
    else
    {
        // TODO: Externalize to a configurable property?
        cell.imageView.image = imageForFilename(child.title);
        
        if([[FDKeychainUserDefaults standardUserDefaults] boolForKey:kSyncPreference])
        {
            FavoriteDownloadManager * downloadManager = [FavoriteDownloadManager sharedManager];
            FavoritesUploadManager * uploadManager = [FavoritesUploadManager sharedManager];
            if ([downloadManager isManagedDownload:child.guid])
            {
                [self setIsActivityInProgress:YES];
                
                [downloadManager setProgressIndicator:cell.progressBar forObjectId:child.guid];
                [cell.progressBar setProgress:[downloadManager currentProgressForObjectId:child.guid]];
                
                if(self.syncStatus != SyncStatusLoading)
                {
                    self.syncStatus = SyncStatusWaiting;
                    [cell.details setText:NSLocalizedString(@"Waiting to sync...", @"")];
                }
            }
            
            if (self.activityType == SyncActivityTypeUpload && ([[uploadManager uploadsQueue] operationCount] > 0))
            {
                [self setIsActivityInProgress:YES];
                [self.uploadInfo.uploadRequest setUploadProgressDelegate:cell.progressBar];
                if(self.syncStatus != SyncStatusLoading)
                {
                    self.syncStatus = SyncStatusWaiting;
                    [cell.details setText:NSLocalizedString(@"Waiting to sync...", @"")];
                }
            }
        }
        
        [self updateCellDetails:cell];
    }
    
    [self updateFavoriteIndicator];
    [self updateSyncStatus:self.syncStatus forCell:cell];
    [cell.contentView bringSubviewToFront:cell.status];
    [cell.contentView bringSubviewToFront:cell.overlayView];
    
    return cell;
}

- (UITableViewCell *)createCellInTableView:(UITableView *)tableView
{
    [self setTableView:tableView];
    
    UITableViewCell *cell = [self createRepositoryInfoCellInTableView:tableView];
    return cell;
}

- (void)updateSyncStatus:(SyncStatus)status forCell:(FavoriteTableViewCell *)cell
{
    self.syncStatus = status;
    self.cell = cell;
    
    switch (status)
    {
        case SyncStatusFailed:
            [cell.status setImage:[UIImage imageNamed:@"sync-status-failed"]];
            break;

        case SyncStatusLoading:
            [cell.status setImage:[UIImage imageNamed:@"sync-status-loading"]];
            break;

        case SyncStatusOffline:
            [cell.status setImage:[UIImage imageNamed:@"sync-status-offline"]];
            break;

        case SyncStatusSuccessful:
            [cell.status setImage:[UIImage imageNamed:@"sync-status-success"]];
            break;

        case SyncStatusCancelled:
            [cell.status setImage:[UIImage imageNamed:@"sync-status-failed"]];
            break;

        case SyncStatusWaiting:
            [cell.status setImage:[UIImage imageNamed:@"sync-status-pending"]];
            break;

        case SyncStatusDisabled:
            [cell.status setImage:nil];
            break;

        default:
            break;
    }
}

- (void)updateFavoriteIndicator
{
    FavoriteTableViewCell *cell = (FavoriteTableViewCell *)self.cell;
    if (self.uploadInfo == nil)
    {
        CGRect rect = cell.details.frame;
        if (self.documentIsFavorite)
        {
            rect.origin.x = cell.favoriteIcon.frame.origin.x + 16;
            cell.details.frame = rect;

            [cell.overlayView setHidden:YES];
            [cell.favoriteIcon setImage:[UIImage imageNamed:@"favorite-indicator"]];
            [cell.favoriteIcon setHighlightedImage:[UIImage imageNamed:@"selected-favorite-indicator"]];
        }
        else
        {
            rect.origin.x = cell.favoriteIcon.frame.origin.x;
            cell.details.frame = rect;

            [cell.overlayView setHidden:NO];
            [cell.favoriteIcon setImage:nil];
            [cell.favoriteIcon setHighlightedImage:nil];
        }
    }
}

- (void)updateCellDetails:(UITableViewCell *)cell
{
    FavoriteTableViewCell * favoriteCell = (FavoriteTableViewCell *) cell;
    
    RepositoryItem *child = [self anyRepositoryItem];
    NSString * modificationDate = @"";
    
    if (self.activityType == SyncActivityTypeUpload)
    {
        FavoriteFileDownloadManager * fileManager = [FavoriteFileDownloadManager sharedInstance];
        NSError *dateerror;
        
        NSString * pathToSyncedFile = [fileManager pathToFileDirectory:[fileManager generatedNameForFile:child.title withObjectID:child.guid]];
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:pathToSyncedFile error:&dateerror];
        modificationDate = formatDocumentDateFromDate([fileAttributes objectForKey:NSFileModificationDate]);
    }
    else 
    {
        if ([child.lastModifiedDate isKindOfClass:[NSDate class]])
        {
            modificationDate = formatDocumentDateFromDate((NSDate*)child.lastModifiedDate);
        }
        else 
        {
            modificationDate = formatDocumentDate(child.lastModifiedDate);
        }
    }
    
    if(self.syncStatus != SyncStatusWaiting)
    {
        favoriteCell.details.text = [NSString stringWithFormat:@"%@ • %@", modificationDate,self.fileSize];
    }
    
    
    if (self.isActivityInProgress)
    {
        if (self.syncStatus != SyncStatusWaiting)
        {
            [favoriteCell.details setHidden:YES];
            [favoriteCell.favoriteIcon setHidden:YES];
            [favoriteCell.progressBar setHidden:NO];
        }
        [favoriteCell setAccessoryView:[self makeCancelPreviewDisclosureButton]];
    }
    else
    {
        [favoriteCell.progressBar setHidden:YES];
        [favoriteCell.details setHidden:NO];
        [favoriteCell.favoriteIcon setHidden:NO];
        
        if((self.syncStatus == SyncStatusFailed || self.syncStatus == SyncStatusCancelled) && self.isPreviewInProgress == NO)
        {
            [favoriteCell setAccessoryView:[self makeFailureDisclosureButton]];
        }
        else 
        {
            [favoriteCell setAccessoryView:[self makeDetailDisclosureButton]];
        }
    }
    
    NSString * fileKey = [[FavoriteFileDownloadManager sharedInstance] generatedNameForFile:child.title withObjectID:child.guid];
    
    BOOL isSyncEnabled = [[FavoriteManager sharedManager] isSyncEnabled];
    
    BOOL isRestricted = isSyncEnabled ? ([[AlfrescoMDMLite sharedInstance] isRestrictedSync:fileKey]) : ([[AlfrescoMDMLite sharedInstance] isRestrictedRepoItem:child]);
    
    BOOL isExpired = [[AlfrescoMDMLite sharedInstance] isSyncExpired:fileKey withAccountUUID:self.accountUUID];
    
    isExpired ? (favoriteCell.contentView.alpha = 0.5) : (favoriteCell.contentView.alpha = 1.0);
    
    if(isRestricted)
    {
        [favoriteCell.restrictedImage setImage:[UIImage imageNamed:@"restricted-file"]];
    }
    else
    {
        [favoriteCell.restrictedImage setImage:nil];
    }
    
}

@end

