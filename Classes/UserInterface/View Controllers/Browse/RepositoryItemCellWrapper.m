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
//  RepositoryItemCellWrapper.m
//
#import "UIImageView+WebCache.h"
#import "RepositoryItemCellWrapper.h"
#import "RepositoryItem.h"
#import "UploadInfo.h"
#import "UploadProgressTableViewCell.h"
#import "RepositoryItemTableViewCell.h"
#import "FileUtils.h"
#import "Utility.h"
#import "AppProperties.h"
#import "PreviewManager.h"
#import "FavoriteManager.h"

@implementation RepositoryItemCellWrapper
@synthesize itemTitle = _itemTitle;
@synthesize repositoryItem = _repositoryItem;
@synthesize uploadInfo = _uploadInfo;
@synthesize isSearchError = _isSearchError;
@synthesize searchStatusCode = _searchStatusCode;
@synthesize tableView = _tableView;
@synthesize isDownloadingPreview = _isDownloadingPreview;
@synthesize cell = _cell;
@synthesize selectedAccountUUID = _selectedAccountUUID;
@synthesize tenantID = _tenantID;
@synthesize documentIsFavorite = _documentIsFavorite;

- (void)dealloc
{
    [_itemTitle release];
    [_repositoryItem release];
    [_uploadInfo release];
    [_tableView release];
    [_cell release];
    [_selectedAccountUUID release];
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
        [self.cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    else
    {
        [self.cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
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
    [self.cell setSelectionStyle:UITableViewCellSelectionStyleNone];
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
        mainText = NSLocalizedString(@"search.results.error", @"The search request failed");
        detailText = NSLocalizedString(@"search.results.error.detail", @"Problem whilst searching");
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
    return cell;
}

- (UITableViewCell *)createRepositoryInfoCellInTableView:(UITableView *)tableView
{
    RepositoryItemTableViewCell *cell = (RepositoryItemTableViewCell *) [tableView dequeueReusableCellWithIdentifier:RepositoryItemCellIdentifier];
    if (cell == nil)
    {
		NSArray *nibItems = [[NSBundle mainBundle] loadNibNamed:@"RepositoryItemTableViewCell" owner:self options:nil];
		cell = [nibItems objectAtIndex:0];
		NSAssert(nibItems, @"Failed to load object from NIB");
        
        CGRect frame = cell.restrictedImage.frame;
        frame.origin.x = cell.frame.size.width - cell.restrictedImage.frame.size.width;
        cell.restrictedImage.frame = frame;
        
        [cell addSubview:cell.restrictedImage];
    }
    
    [self setCell:cell];
    
    // Highlight colours
    [cell.filename setHighlightedTextColor:[UIColor whiteColor]];
    [cell.details setHighlightedTextColor:[UIColor whiteColor]];
    
    RepositoryItem *child = [self anyRepositoryItem];
    FavoriteManager *favoriteManager = [FavoriteManager sharedManager];
    [self setDocumentIsFavorite:([favoriteManager isNodeFavorite:child.guid accountUUID:self.selectedAccountUUID tenantID:self.tenantID])];
    
    NSString *filename = [child.metadata valueForKey:@"cmis:name"];
    if (!filename || ([filename length] == 0))
    {
        filename = child.title;
    }
    [cell.filename setText:filename];
    [self setIsDownloadingPreview:NO];
    
    if ([child isFolder])
    {
        UIImage *img = [UIImage imageNamed:@"folder.png"];
        cell.imageView.image = img;
        //cell.image.image = img;
        cell.details.text = [[[NSString alloc] initWithFormat:@"%@", formatDocumentDate(child.lastModifiedDate)] autorelease]; // TODO: Externalize to a configurable property?        
        [self updateFavoriteIndicator:NO forCell:cell];
    }
    else
    {
        NSString *contentStreamLengthStr = [child contentStreamLengthString];
        
        cell.details.text = [[[NSString alloc] initWithFormat:@"%@ • %@", formatDocumentDate(child.lastModifiedDate), 
                              [FileUtils stringForLongFileSize:[contentStreamLengthStr longLongValue]]] autorelease]; // TODO: Externalize to a configurable property?
        cell.imageView.image = imageForFilename(child.title);
        //[cell.image setImageWithURL:[child thumbnailURL] placeholderImage:imageForFilename(child.title)];
        PreviewManager *manager = [PreviewManager sharedManager];
        if ([manager isManagedPreview:child.guid])
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
            [manager setDelegate:(id<PreviewManagerDelegate>)delegate];
            [manager setProgressIndicator:cell.progressBar];
            [cell.progressBar setProgress:manager.currentProgress];
            [cell.details setHidden:YES];
            [cell.progressBar setHidden:NO];
        }
        [self updateFavoriteIndicator:self.documentIsFavorite forCell:cell];
    }
    
    BOOL isRestricted = [[AlfrescoMDMLite sharedInstance] isRestrictedRepoItem:child];
    
    cell.restrictedImage.image = isRestricted ? [UIImage imageNamed:@"restricted-file"] : nil;

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


- (void)updateFavoriteIndicator:(BOOL)isFavorite forCell:(UITableViewCell *)forCell
{
    if ([forCell isKindOfClass:[RepositoryItemTableViewCell class]])
    {
        self.documentIsFavorite = isFavorite;
        RepositoryItemTableViewCell *cell = (RepositoryItemTableViewCell *)forCell;
        
        CGRect rect = cell.details.frame;
        if (isFavorite)
        {
            rect.origin.x = cell.favIcon.frame.origin.x + 16;
            cell.details.frame = rect;
            [cell.favIcon setImage:[UIImage imageNamed:@"favorite-indicator"]];
            [cell.favIcon setHighlightedImage:[UIImage imageNamed:@"selected-favorite-indicator"]];
        }
        else
        {
            rect.origin.x = cell.favIcon.frame.origin.x;
            cell.details.frame = rect;
            [cell.favIcon setImage:nil];
            [cell.favIcon setHighlightedImage:nil];
        }
    }
}

@end
