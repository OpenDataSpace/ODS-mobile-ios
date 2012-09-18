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
#import "FileUtils.h"
#import "Utility.h"
#import "AppProperties.h"
//#import "PreviewManager.h"
#import "FavoriteDownloadManager.h"
#import "FavoritesUploadManager.h"
#import "PreviewManager.h"
#import "FavoritesDownloadManagerDelegate.h"
#import "AccountManager.h"
#import "FavoriteFileDownloadManager.h"

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
@synthesize document = _document;
@synthesize activityType = _activityType;

@synthesize accountUUID = _accountUUID;
@synthesize tenantID = _tenantID;

- (void)dealloc
{
    [_itemTitle release];
    [_repositoryItem release];
    [_uploadInfo release];
    [_cell release];
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
        self.syncStatus = SyncDisabled;
        self.document = IsFavorite;
        self.activityType = None;
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

-(void) setIsActivityInProgress:(BOOL)isActivityInProgress
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
    //[cell.favoriteButton addTarget:self.tableView.delegate action:@selector(favoriteButtonPressed:withEvent:) forControlEvents:UIControlEventTouchUpInside];
    
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
        NSString * modificationDate = @"";
        
       if(self.activityType == Upload)
        {
            FavoriteFileDownloadManager * fileManager = [FavoriteFileDownloadManager sharedInstance];
            NSError *dateerror;
            
            NSString * pathToSyncedFile = [fileManager pathToFileDirectory:[fileManager generatedNameForFile:child.title withObjectID:child.guid]];
            NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:pathToSyncedFile error:&dateerror];
            modificationDate = formatDocumentDateFromDate([fileAttributes objectForKey:NSFileModificationDate]);
        }
       else 
        {
            if([child.lastModifiedDate isKindOfClass:[NSDate class]])
            {
                modificationDate = formatDocumentDateFromDate((NSDate*)child.lastModifiedDate);
            }
            else 
            {
                modificationDate = formatDocumentDate(child.lastModifiedDate);
            }
        }
        
        cell.details.text = [NSString stringWithFormat:@"%@ | %@", modificationDate,self.fileSize];
        
        
        // TODO: Externalize to a configurable property?
        cell.imageView.image = imageForFilename(child.title);
        
        if([[FDKeychainUserDefaults standardUserDefaults] boolForKey:kSyncPreference])
        {
            FavoriteDownloadManager * downloadManager = [FavoriteDownloadManager sharedManager];
            if ([downloadManager isManagedDownload:child.guid])
            {
                [self setIsActivityInProgress:YES];
                
                [downloadManager setProgressIndicator:cell.progressBar forObjectId:child.guid];
                [cell.progressBar setProgress:[downloadManager currentProgressForObjectId:child.guid]];
                self.syncStatus = SyncLoading;
                [cell.details setText:NSLocalizedString(@"Waiting to sync...", @"")];
            }
            
            if (self.activityType == Upload)
            {
                [self setIsActivityInProgress:YES];
                self.syncStatus = SyncLoading;
                [cell.details setText:NSLocalizedString(@"Waiting to sync...", @"")];
            }
        }
    }
    
    self.cell = cell;
    [self favoriteOrUnfavoriteDocument];
    [self updateSyncStatus:self.syncStatus forCell:cell];
    [cell.contentView bringSubviewToFront:cell.status];
    
    
    return cell;
}

- (UITableViewCell *)createCellInTableView:(UITableView *)tableView
{
    [self setTableView:tableView];
    
    UITableViewCell *cell = nil;
    
    cell = [self createRepositoryInfoCellInTableView:tableView];
    return cell;
}

- (void)updateSyncStatus:(SyncStatus)status forCell:(FavoriteTableViewCell*)cell
{
    self.syncStatus = status;
    self.cell = cell;
    
    switch (status)
    {
        case SyncFailed:
        {
            [cell.status setImage:[UIImage imageNamed:@"sync-status-failed"]];
            break;
        }
        case SyncLoading:
        {
            [cell.status setImage:[UIImage imageNamed:@"sync-status-loading"]];
            break;
        }
        case SyncOffline:
        {
            [cell.status setImage:[UIImage imageNamed:@"sync-status-offline"]];
            break;
        }
        case SyncSuccessful:
        {
            [cell.status setImage:[UIImage imageNamed:@"sync-status-success"]];
            break;
        }
        case SyncCancelled:
        {
            [cell.status setImage:[UIImage imageNamed:@"sync-status-failed"]];
            
            break;
        }
        case SyncWaiting:
        {
            [cell.status setImage:[UIImage imageNamed:@"sync-status-pending"]];
            break;
        }
        case SyncDisabled:
        {
            [cell.status setImage:nil];
            break;
        }
        default:
            break;
    }
    
    
}

- (void)favoriteOrUnfavoriteDocument
{
    FavoriteTableViewCell * favCell = (FavoriteTableViewCell *)self.cell;
    if(self.uploadInfo == nil)
    {
        switch (self.document)
        {
            case IsFavorite:
            {
                [self.cell setBackgroundColor:[UIColor whiteColor]];
                
                CGRect rect = favCell.details.frame;
                rect.origin.x = favCell.favoriteIcon.frame.origin.x + 16;
                favCell.details.frame = rect;
                
                UIImage * favImage = nil;
                if([favCell isSelected])
                {
                   favImage = [UIImage imageNamed:@"selected-favorite-indicator"];
                }
                else
                {
                    favImage = [UIImage imageNamed:@"favorite-indicator"];
                }
                [[favCell favoriteIcon] setImage:favImage];
                break;
            }
            case IsNotFavorite:
            {
                [self.cell setBackgroundColor:[UIColor colorWithRed:245/255.0 green:245/255.0 blue:245/255.0 alpha:1.0]];
                
                CGRect rect = favCell.details.frame;
                rect.origin.x = favCell.favoriteIcon.frame.origin.x;
                favCell.details.frame = rect;
                
                [[favCell favoriteIcon] setImage:nil]; 
                break;
            }
            default:
                break;
        }
    }
}

-(void) changeFavoriteIcon:(BOOL) selected forCell:(UITableViewCell *) tcell
{
    FavoriteTableViewCell * favCell = (FavoriteTableViewCell *)tcell;
    
    if(selected)
    {
        [[favCell favoriteIcon] setImage:[UIImage imageNamed:@"selected-favorite-indicator"]];
    }
    else
    {
        [[favCell favoriteIcon] setImage:[UIImage imageNamed:@"favorite-indicator"]];
    }
}

-(void) updateCellDetails:(UITableViewCell *) cell
{
    FavoriteTableViewCell * favoriteCell = (FavoriteTableViewCell *) cell;
    
    if([self.repositoryItem.lastModifiedDate isKindOfClass:[NSDate class]])
    {
        favoriteCell.details.text = [NSString stringWithFormat:@"%@ | %@", formatDocumentDateFromDate((NSDate*)self.repositoryItem.lastModifiedDate),self.fileSize];
    }
    else
    {
        favoriteCell.details.text = [NSString stringWithFormat:@"%@ | %@", formatDocumentDate(self.repositoryItem.lastModifiedDate),self.fileSize];
    }
    
    if((self.syncStatus == SyncFailed || self.syncStatus == SyncCancelled) && self.isPreviewInProgress == NO)
    {
        [favoriteCell setAccessoryView:[self makeFailureDisclosureButton]];
    }
}

@end

