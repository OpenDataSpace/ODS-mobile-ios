//
//  FavoriteTableCellWrapper.m
//  FreshDocs
//
//  Created by Mohamad Saeedi on 13/08/2012.
//  Copyright (c) 2012 . All rights reserved.
//

#import "FavoriteTableCellWrapper.h"
#import "RepositoryItem.h"
#import "UploadInfo.h"
#import "UploadProgressTableViewCell.h"
#import "FavoriteTableViewCell.h"
#import "FavoriteFileUtils.h"
#import "Utility.h"
#import "AppProperties.h"
//#import "PreviewManager.h"
#import "FavoriteDownloadManager.h"
#import "PreviewManager.h"
#import "FavoritesDownloadManagerDelegate.h"
#import "AccountManager.h"

@implementation FavoriteTableCellWrapper

@synthesize itemTitle = _itemTitle;
@synthesize repositoryItem = _repositoryItem;
@synthesize uploadInfo = _uploadInfo;
@synthesize isSearchError = _isSearchError;
@synthesize searchStatusCode = _searchStatusCode;
@synthesize tableView = _tableView;
@synthesize isDownloadingPreview = _isDownloadingPreview;
@synthesize cell = _cell;
@synthesize fileSize = _fileSize;
@synthesize syncStatus = _syncStatus;
@synthesize document = _document;

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

- (void)setIsDownloadingPreview:(BOOL)isDownloadingPreview
{
    _isDownloadingPreview = isDownloadingPreview;
    
    if (isDownloadingPreview)
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
    /*
    RepositoryItemTableViewCell *cell = (RepositoryItemTableViewCell *) [tableView dequeueReusableCellWithIdentifier:RepositoryItemCellIdentifier];
    if (cell == nil)
    {
		NSArray *nibItems = [[NSBundle mainBundle] loadNibNamed:@"RepositoryItemTableViewCell" owner:self options:nil];
		cell = [nibItems objectAtIndex:0];
		NSAssert(nibItems, @"Failed to load object from NIB");
    }
    
    [self setCell:cell];
    
    NSString *mainText = nil;
    NSString *detailText = nil;
    
    // Check if we got too many results
    if (self.searchStatusCode == 500) 
    {
        mainText = NSLocalizedString(@"Too many search results", @"Server Error");
        detailText = NSLocalizedString(@"refineSearchTermsMessage", @"refineSearchTermsMessage");
    }
    else 
    {
        mainText = NSLocalizedString(@"noSearchResultsMessage", @"No Results Found");
        detailText = NSLocalizedString(@"tryDifferentSearchMessage", @"Please try a different search");
    }
    
    [[cell filename] setText:mainText];
    [[cell details] setText:detailText];
    [cell setAccessoryType:UITableViewCellAccessoryNone];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [cell setAccessoryView:nil];
    
    [[cell imageView] setImage:nil];
     */
    
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
    [self setIsDownloadingPreview:NO];
    [cell.favoriteButton addTarget:self.tableView.delegate action:@selector(favoriteButtonPressed:withEvent:) forControlEvents:UIControlEventTouchUpInside];
    
    cell.serverName.text = [[[AccountManager sharedManager] accountInfoForUUID:self.accountUUID] description];
    
    if ([child isFolder])
    {
        UIImage *img = [UIImage imageNamed:@"folder.png"];
        cell.imageView.image = img;
        cell.details.text = [[[NSString alloc] initWithFormat:@"%@", formatDocumentDate(child.lastModifiedDate)] autorelease]; // TODO: Externalize to a configurable property?        
    }
    else
    {
       
        if([child.lastModifiedDate isKindOfClass:[NSDate class]])
        {
            cell.details.text = [[NSString alloc] initWithFormat:@"%@ | %@", formatDocumentDateFromDate((NSDate*)child.lastModifiedDate),self.fileSize];
        }
        else {
            cell.details.text = [[NSString alloc] initWithFormat:@"%@ | %@", formatDocumentDate(child.lastModifiedDate),self.fileSize];
        }
        
         // TODO: Externalize to a configurable property?
        cell.imageView.image = imageForFilename(child.title);
        
        if([[FDKeychainUserDefaults standardUserDefaults] boolForKey:kSyncPreference])
        {
            FavoriteDownloadManager *manager = [FavoriteDownloadManager sharedManager];
            if ([manager isManagedDownload:child.guid])
            {
                [self setIsDownloadingPreview:YES];
                id delegate = nil;
                if([self.tableView.delegate respondsToSelector:@selector(previewDelegate)])
                {
                    delegate = [self.tableView.delegate performSelector:@selector(previewDelegate)];
                }
                else 
                {
                    delegate = self.tableView.delegate;
                }
                
                [manager setProgressIndicator:cell.progressBar forObjectId:child.guid];
                [cell.progressBar setProgress:[manager currentProgressForObjectId:child.guid]];
                [cell.details setHidden:YES];
                [cell.progressBar setHidden:NO];
            }
        }
        
    }
    
    [self favoriteOrUnfavoriteDocument:cell];
    [self updateSyncStatus:self.syncStatus For:cell];
    [cell.contentView bringSubviewToFront:cell.status];
    
    return cell;
}

- (UITableViewCell *)createCellInTableView:(UITableView *)tableView
{
    [self setTableView:tableView];
    
    UITableViewCell *cell = nil;
    
    if (self.uploadInfo && self.uploadInfo.uploadStatus != UploadInfoStatusUploaded)
    {
        cell = [self createUploadCellInTableView:tableView];
    }
    else if ([self anyRepositoryItem])
    {
        cell = [self createRepositoryInfoCellInTableView:tableView];
    }
    else 
    {
        cell = [self createSearchErrorCellInTableView:tableView];
    }
    
    return cell;
}

- (void) updateSyncStatus:(SyncStatus)status For:(FavoriteTableViewCell*)cell
{
    self.syncStatus = status;
    
    switch (status) {
        case SyncFailed:
        {
            [cell.status setImage:[UIImage imageNamed:@"cross-mark.jpg"]];
            break;
        }
        case SyncLoading:
        {
            [cell.status setImage:[UIImage imageNamed:@"loading.jpg"]];
            break;
        }
        case SyncOffline:
        {
            [cell.status setImage:[UIImage imageNamed:@"offline.jpg"]];
            break;
        }
        case SyncSuccessful:
        {
            [cell.status setImage:[UIImage imageNamed:@"check-mark.jpg"]];
            break;
        }
        case SyncCancelled:
        {
            [cell.status setImage:[UIImage imageNamed:@"cross-mark.jpg"]];
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

- (void) favoriteOrUnfavoriteDocument:(FavoriteTableViewCell*)cell
{
    switch (self.document) {
        case IsFavorite:
        {
            [cell setBackgroundColor:[UIColor whiteColor]];
            [cell.favoriteButton setImage:[UIImage imageNamed:@"favorite.jpg"] forState:UIControlStateNormal];          
            break;
        }
        case IsNotFavorite:
        {
            [cell setBackgroundColor:[UIColor colorWithRed:245/255.0 green:245/255.0 blue:245/255.0 alpha:1.0]];
            [cell.favoriteButton setImage:[UIImage imageNamed:@"unfavorite-icon.jpg"] forState:UIControlStateNormal]; 
            break;
        }
        default:
            break;
    }
}

@end

