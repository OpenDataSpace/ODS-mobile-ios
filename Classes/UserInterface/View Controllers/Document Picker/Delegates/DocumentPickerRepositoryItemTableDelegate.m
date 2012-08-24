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

#define DOCUMENT_LIBRARY_TITLE @"documentLibrary"

@interface DocumentPickerRepositoryItemTableDelegate () <ASIHTTPRequestDelegate>

@property (nonatomic, retain) NSArray *items;

@end


@implementation DocumentPickerRepositoryItemTableDelegate

@synthesize accountUuid = _accountUuid;
@synthesize tenantId = _tenantId;
@synthesize items = _items;


#pragma mark Init and dealloc


- (void)dealloc
{
    [_repositoryItem release];
    [_accountUuid release];
    [_tenantId release];
    [_items release];
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

- (void)requestFinished:(ASIHTTPRequest *)request
{
    FolderItemsHTTPRequest *folderItemsHTTPRequest = (FolderItemsHTTPRequest *)request;

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
    NSLog(@"FolderItemsHTTPRequest failed : %@", request.error.localizedDescription);
    stopProgressHUD(self.progressHud);
}


- (UITableViewCell *)createNewTableViewCell
{
    NSArray *nibItems = [[NSBundle mainBundle] loadNibNamed:@"RepositoryItemTableViewCell" owner:self options:nil];
    UITableViewCell *cell = [nibItems objectAtIndex:0];
    NSAssert(nibItems, @"Failed to load object from NIB");
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
    }
    else
    {
        NSString *contentStreamLengthStr = [item.metadata objectForKey:@"cmis:contentStreamLength"];
        cell.details.text = [[[NSString alloc] initWithFormat:@"%@ | %@", formatDocumentDate(item.lastModifiedDate),
                                                              [FileUtils stringForLongFileSize:((long) [contentStreamLengthStr longLongValue])]] autorelease];
        cell.imageView.image = imageForFilename(item.title);
        cell.accessoryType = UITableViewCellAccessoryNone;
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
            newDocumentPickerViewController.selection = self.documentPickerViewController.selection; // copying setting for selection, and already selected items
            [self.documentPickerViewController.navigationController pushViewController:newDocumentPickerViewController animated:YES];
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


@end
