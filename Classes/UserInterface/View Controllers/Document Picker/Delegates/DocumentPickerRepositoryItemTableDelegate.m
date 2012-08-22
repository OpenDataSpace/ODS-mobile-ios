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
#import "DocumentPickerRepositoryItemTableDelegate.h"
#import "RepositoryItem.h"
#import "MBProgressHUD.h"
#import "Utility.h"
#import "DocumentPickerViewController.h"
#import "FolderItemsHTTPRequest.h"
#import "LinkRelationService.h"
#import "RepositoryItemTableViewCell.h"
#import "FileUtils.h"

#define DOCUMENT_LIBRARY_TITLE @"documentLibrary"

@interface DocumentPickerRepositoryItemTableDelegate () <ASIHTTPRequestDelegate>

// View
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) MBProgressHUD *progressHud;

// Data
@property (nonatomic, retain) NSArray *items;

@end


@implementation DocumentPickerRepositoryItemTableDelegate

@synthesize repositoryItem = _repositoryItem;
@synthesize documentPickerViewController = _documentPickerViewController;
@synthesize tableView = _tableView;
@synthesize progressHud = _progressHud;
@synthesize accountUuid = _accountUuid;
@synthesize tenantId = _tenantId;
@synthesize items = _items;


#pragma mark Init and dealloc


- (void)dealloc
{
    [_repositoryItem release];
    [_tableView release];
    [_progressHud release];
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
        _repositoryItem = [site retain];
        _accountUuid = [accountUuid copy];
        _tenantId = [tenantId copy];
    }

    return self;
}

#pragma mark Data loading

- (void)loadDataForTableView:(UITableView *)tableView
{
    if (self.items == nil)
    {
        // Show progress HUD
        self.tableView = tableView;
        self.progressHud = createAndShowProgressHUDForView(self.documentPickerViewController.view);

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
        FolderItemsHTTPRequest *request = [[FolderItemsHTTPRequest alloc] initWithURL:getChildrenURL accountUUID:self.accountUuid];
        [request setTenantID:self.tenantId];
        [request setDelegate:self];
        [request startAsynchronous];
        [request release];
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

#pragma mark Table view datasource and delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.items.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kDefaultTableCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RepositoryItemTableViewCell * cell = (RepositoryItemTableViewCell *) [tableView dequeueReusableCellWithIdentifier:RepositoryItemCellIdentifier];
    if (cell == nil)
    {
        NSArray *nibItems = [[NSBundle mainBundle] loadNibNamed:@"RepositoryItemTableViewCell" owner:self options:nil];
        cell = [nibItems objectAtIndex:0];
        NSAssert(nibItems, @"Failed to load object from NIB");
    }

    RepositoryItem *item = [self.items objectAtIndex:indexPath.row];

    NSString *filename = [item.metadata valueForKey:@"cmis:name"];
    [cell.filename setText:( (!filename || [filename length] == 0) ? item.title : filename)];

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
                        [FileUtils stringForLongFileSize:((long)[contentStreamLengthStr longLongValue])]] autorelease];
        cell.imageView.image = imageForFilename(item.title);
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // If it's a folder, we need to go one level down. Else, we just mark the document as selected
    RepositoryItem *selectedItem = [self.items objectAtIndex:indexPath.row];
    if ([selectedItem isFolder])
    {
        DocumentPickerViewController *newDocumentPickerViewController = [DocumentPickerViewController
                documentPickerForRepositoryItem:selectedItem accountUuid:self.accountUuid tenantId:self.tenantId];
        [self.documentPickerViewController.navigationController pushViewController:newDocumentPickerViewController animated:YES];
    }
    else
    {
        // TODO: selection
    }
}

- (NSString *)titleForTable
{
    return self.repositoryItem.title;
}

@end
