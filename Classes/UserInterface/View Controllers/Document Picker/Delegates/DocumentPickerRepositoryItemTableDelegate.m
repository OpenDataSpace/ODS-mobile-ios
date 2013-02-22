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
// DocumentPickerNodeTableDelegate
//
#import "RepositoryItem.h"
#import "Utility.h"
#import "DocumentPickerViewController.h"
#import "FolderItemsHTTPRequest.h"
#import "LinkRelationService.h"
#import "RepositoryItemTableViewCell.h"
#import "FileUtils.h"
#import "DocumentPickerSelection.h"
#import "DocumentPickerTableDelegate.h"
#import "DocumentPickerRepositoryItemTableDelegate.h"
#import "CMISSearchHTTPRequest.h"
#import "AlfrescoMDMLite.h"

#define DOCUMENT_LIBRARY_TITLE @"documentLibrary"

@interface DocumentPickerRepositoryItemTableDelegate () <ASIHTTPRequestDelegate>

@property (nonatomic, retain) NSArray *items;

// Searching
@property BOOL searching;
@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) NSArray *originalItems;

@end


@implementation DocumentPickerRepositoryItemTableDelegate

@synthesize repositoryItem = _repositoryItem;
@synthesize accountUuid = _accountUuid;
@synthesize tenantId = _tenantId;
@synthesize items = _items;
@synthesize searching = _searching;
@synthesize searchBar = _searchBar;
@synthesize originalItems = _originalItems;


#pragma mark Init and dealloc


- (void)dealloc
{
    [_repositoryItem release];
    [_accountUuid release];
    [_tenantId release];
    [_items release];
    [_searchBar release];
    [_originalItems release];
    [super dealloc];
}

- (id)initWitRepositoryItem:(RepositoryItem *)site accountUuid:(NSString *)accountUuid tenantId:(NSString *)tenantId
{
    self = [super init];
    if (self)
    {
        [super setDelegate:self];
        _repositoryItem = [site retain];
        _accountUuid = [accountUuid copy];
        _tenantId = [tenantId copy];
    }

    return self;
}

#pragma mark Data Document Picker delegate methods

- (NSInteger)tableCount
{
    return self.items.count;
}

- (BOOL)isDataAvailable
{
    return self.items != nil;
}

- (void)loadData
{
    // Fire off async request
    FolderItemsHTTPRequest *request = nil;
    if (self.repositoryItem.node != nil) // We're at the top level
    {
        request = [[FolderItemsHTTPRequest alloc] initWithNode:self.repositoryItem.node withAccountUUID:self.accountUuid];
    }
    else // We're at a folder
    {
        NSDictionary *optionalArguments = [[LinkRelationService shared] defaultOptionalArgumentsForFolderChildrenCollection];
        NSURL *getChildrenURL = [[LinkRelationService shared] getChildrenURLForCMISFolder:self.repositoryItem withOptionalArguments:optionalArguments];
        request = [[FolderItemsHTTPRequest alloc] initWithURL:getChildrenURL accountUUID:self.accountUuid];
    }

    [request setTenantID:self.tenantId];
    [request setDelegate:self];
    [request startAsynchronous];
    [request release];
}

- (UITableViewCell *)createNewTableViewCell
{
    NSArray *nibItems = [[NSBundle mainBundle] loadNibNamed:@"RepositoryItemTableViewCell" owner:self options:nil];
    RepositoryItemTableViewCell *cell = [nibItems objectAtIndex:0];
    NSAssert(nibItems, @"Failed to load object from NIB");
    
    CGRect frame = cell.restrictedImage.frame;
    frame.origin.x = self.tableView.frame.size.width - cell.restrictedImage.frame.size.width;
    cell.restrictedImage.frame = frame;
    [cell addSubview:cell.restrictedImage];
    
    return cell;
}

- (void)customizeTableViewCell:(UITableViewCell *)tableViewCell forIndexPath:(NSIndexPath *)indexPath
{
    RepositoryItem *item = [self.items objectAtIndex:indexPath.row];
    
    RepositoryItemTableViewCell *cell = (RepositoryItemTableViewCell *)tableViewCell;
    NSString *filename = [item.metadata valueForKey:@"cmis:name"];
    [cell.filename setText:((!filename || [filename length] == 0) ? item.title : filename)];

    if ([item isFolder])
    {
        cell.imageView.image = [UIImage imageNamed:@"folder.png"];
        cell.details.text = [[[NSString alloc] initWithFormat:@"%@", formatDocumentDate(item.lastModifiedDate)] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.restrictedImage.image = nil;
    }
    else
    {
        NSString *contentStreamLengthStr = [item.metadata objectForKey:@"cmis:contentStreamLength"];
        cell.details.text = [[[NSString alloc] initWithFormat:@"%@ • %@", formatDocumentDate(item.lastModifiedDate),
                                                              [FileUtils stringForLongFileSize:((long) [contentStreamLengthStr longLongValue])]] autorelease];
        cell.imageView.image = imageForFilename(item.title);
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        BOOL isRestricted = [[AlfrescoMDMLite sharedInstance] isRestrictedRepoItem:item];
        cell.restrictedImage.image = isRestricted ? [UIImage imageNamed:@"restricted-file"] : nil;
    }
}

- (BOOL)isSelectionEnabled
{
    return self.documentPickerViewController.selection.isFolderSelectionEnabled
        || self.documentPickerViewController.selection.isDocumentSelectionEnabled;
}

- (BOOL)isSelected:(NSIndexPath *)indexPath
{
    RepositoryItem *item = [self.items objectAtIndex:indexPath.row];
    return  ([item isFolder] && [self.documentPickerViewController.selection containsFolder:item])
                || [self.documentPickerViewController.selection containsDocument:item];
}

- (void)didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // If it's a folder, we need to go one level down. Else, we just mark the document as selected
    RepositoryItem *selectedItem = [self.items objectAtIndex:indexPath.row];
    if ([selectedItem isFolder])
    {
        if (self.documentPickerViewController.selection.isFolderSelectionEnabled)
        {
            [self.documentPickerViewController.selection addFolder:selectedItem];
        }
        else
        {
            DocumentPickerViewController *newDocumentPickerViewController = [DocumentPickerViewController
                    documentPickerForRepositoryItem:selectedItem accountUuid:self.accountUuid tenantId:self.tenantId];
            [self goOneLevelDeeperWithDocumentPicker:newDocumentPickerViewController];
        }
    }
    else
    {
        if (self.documentPickerViewController.selection.isDocumentSelectionEnabled)
        {
            [self.documentPickerViewController.selection addDocument:selectedItem];
        }
    }
}

- (void)didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RepositoryItem *item = [self.items objectAtIndex:indexPath.row];
    if ([item isFolder])
    {
        if (self.documentPickerViewController.selection.isFolderSelectionEnabled)
        {
            [self.documentPickerViewController.selection removeFolder:item];
        }
    }
    else
    {
        if (self.documentPickerViewController.selection.isDocumentSelectionEnabled)
        {
            [self.documentPickerViewController.selection removeDocument:item];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    RepositoryItem *item = [self.items objectAtIndex:indexPath.row];
    if ([item isFolder])
    {
        return self.documentPickerViewController.selection.isFolderSelectionEnabled;
    }
    else
    {
        return self.documentPickerViewController.selection.isDocumentSelectionEnabled;
    }
}

- (NSString *)titleForTable
{
    return self.repositoryItem.title;
}

- (void)clearCachedData
{
    self.items = nil;
}

#pragma mark UISearchBar delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    NSString *searchText = [searchBar.text trimWhiteSpace];
    if (searchText.length > 0)
    {
        self.searchBar = searchBar;

        // Show progress HUD on view
        [self showProgressHud];
        [self searchingInProgress];

        // Fire off request
        CMISSearchHTTPRequest *request = [[[CMISSearchHTTPRequest alloc] initWithSearchPattern:searchText
                                                                                folderObjectId:self.repositoryItem.guid
                                                                                   accountUUID:self.accountUuid
                                                                                      tenantID:self.tenantId] autorelease];
        request.delegate = self;
        [request startAsynchronous];
    }
}

//- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
//{
//    [self showProgressHud];
//
//    [self searchingFinished];
//    self.items = self.originalItems;
//    self.originalItems = nil;
//    [self.tableView reloadData];
//
//    [self hideProgressHud];
//}

#pragma mark ASIHttpRequest delegate

- (void)requestFinished:(ASIHTTPRequest *)request
{
    if (self.searching)
    {
        [self handleSearchRequest:request];
    }
    else
    {
        [self handleFolderItemsRequest:request];

    }
}

- (void)handleSearchRequest:(ASIHTTPRequest *)request
{
    self.originalItems = self.items; // We're storing the previous results, so we don't have to fetch them again when the search is cancelled
    self.items = ((CMISSearchHTTPRequest *)request).results;

    [self searchingFinished];

    [self.tableView reloadData];
    [self hideProgressHud];
}

- (void)handleFolderItemsRequest:(ASIHTTPRequest *)request
{
    FolderItemsHTTPRequest *folderItemsHTTPRequest = (FolderItemsHTTPRequest *) request;

    // The top-level content of a site has potentially multiple folders like documentLibrary, wiki, dataList, etc.
    // This means that if we see such results coming back, we need to do an extra fetch for the actual documents
    RepositoryItem *documentLibrary = nil;
    if (self.repositoryItem.node != nil) // If nil, we know for sure it's not a top-level folder
    {
        for (RepositoryItem *repositoryItem in folderItemsHTTPRequest.children)
        {
            if ([repositoryItem.title caseInsensitiveCompare:DOCUMENT_LIBRARY_TITLE] == NSOrderedSame)
            {
                documentLibrary = repositoryItem;
                break;
            }
        }
    }

    if (documentLibrary != nil)
    {
        NSDictionary *optionalArguments = [[LinkRelationService shared] defaultOptionalArgumentsForFolderChildrenCollection];
        NSURL *getChildrenURL = [[LinkRelationService shared] getChildrenURLForCMISFolder:documentLibrary withOptionalArguments:optionalArguments];
        FolderItemsHTTPRequest *newRequest = [[FolderItemsHTTPRequest alloc] initWithURL:getChildrenURL accountUUID:self.accountUuid];
        [newRequest setTenantID:self.tenantId];
        [newRequest setDelegate:self];
        [newRequest startAsynchronous];
        [newRequest release];
    }
    else
    {
        self.items = folderItemsHTTPRequest.children;
        [self.tableView reloadData];
        stopProgressHUD(self.progressHud);
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    if (self.searching)
    {
        AlfrescoLogDebug(@"CMISSearchHttpRequest failed : %@", request.error.localizedDescription);
    }
    else
    {
        AlfrescoLogDebug(@"FolderItemsHTTPRequest failed : %@", request.error.localizedDescription);
    }
    [self searchingFinished];
    stopProgressHUD(self.progressHud);
}

- (void)searchingInProgress
{
    self.tableView.userInteractionEnabled = NO;
    self.tableView.scrollEnabled = NO;
    self.searching = YES;
    self.searchBar.resignFirstResponder;
    self.searchBar.userInteractionEnabled = NO;
}

- (void)searchingFinished
{
    self.tableView.userInteractionEnabled = YES;
    self.tableView.scrollEnabled = YES;
    self.searching = NO;
    self.searchBar.resignFirstResponder;
    self.searchBar.userInteractionEnabled = YES;
    self.searchBar = nil;
}


@end
