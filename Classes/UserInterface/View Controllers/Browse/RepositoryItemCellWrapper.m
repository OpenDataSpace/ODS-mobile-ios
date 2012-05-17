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

#import "RepositoryItemCellWrapper.h"
#import "RepositoryItem.h"
#import "UploadInfo.h"
#import "UploadProgressTableViewCell.h"
#import "RepositoryItemTableViewCell.h"
#import "FileUtils.h"
#import "Utility.h"
#import "AppProperties.h"

@implementation RepositoryItemCellWrapper
@synthesize itemTitle = _itemTitle;
@synthesize repositoryItem = _repositoryItem;
@synthesize uploadInfo = _uploadInfo;
@synthesize isSearchError = _isSearchError;
@synthesize searchStatusCode = _searchStatusCode;
@synthesize tableView = _tableView;

- (void)dealloc
{
    [_itemTitle release];
    [_repositoryItem release];
    [_uploadInfo release];
    [super dealloc];
}

- (id)initWithUploadInfo:(UploadInfo *)uploadInfo
{
    self = [super init];
    if(self)
    {
        [self setUploadInfo:uploadInfo];
    }
    return self;
}

- (id)initWithRepositoryItem:(RepositoryItem *)repositoryItem
{
    self = [super init];
    if(self)
    {
        [self setRepositoryItem:repositoryItem];
    }
    return self;    
}

- (RepositoryItem *)anyRepositoryItem
{
    if(self.repositoryItem)
    {
        return self.repositoryItem;
    }
    else if(self.uploadInfo.repositoryItem) 
    {
        return self.uploadInfo.repositoryItem;
    }
    
    return nil;
}

- (UITableViewCell *)createUploadCellInTableView:(UITableView *)tableView
{
    UploadProgressTableViewCell *uploadCell = [tableView dequeueReusableCellWithIdentifier:@"UploadProgressTableViewCell"];
    if(!uploadCell)
    {
        uploadCell = [[[UploadProgressTableViewCell alloc] initWithIdentifier:@"UploadProgressTableViewCell"] autorelease];
    }
    [uploadCell setUploadInfo:self.uploadInfo];
    return uploadCell;
}

- (UIButton *)makeDetailDisclosureButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeInfoDark];
    [button addTarget:self action:@selector(accessoryButtonTapped:withEvent:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void) accessoryButtonTapped: (UIControl *) button withEvent: (UIEvent *) event
{
    NSIndexPath * indexPath = [self.tableView indexPathForRowAtPoint:[[[event touchesForView:button] anyObject] locationInView:self.tableView]];
    if ( indexPath == nil )
        return;
    
    [self.tableView.delegate tableView:self.tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
}

- (UITableViewCell *)createSearchErrorCellInTableView:(UITableView *)tableView
{
    RepositoryItemTableViewCell *cell = (RepositoryItemTableViewCell *) [tableView dequeueReusableCellWithIdentifier:RepositoryItemCellIdentifier];
    if (cell == nil) {
		NSArray *nibItems = [[NSBundle mainBundle] loadNibNamed:@"RepositoryItemTableViewCell" owner:self options:nil];
		cell = [nibItems objectAtIndex:0];
		NSAssert(nibItems, @"Failed to load object from NIB");
    }
    
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
    
    [[cell imageView] setImage:nil];
    return cell;
}

- (UITableViewCell *)createRepositoryInfoCellInTableView:(UITableView *)tableView
{
    RepositoryItemTableViewCell *cell = (RepositoryItemTableViewCell *) [tableView dequeueReusableCellWithIdentifier:RepositoryItemCellIdentifier];
    if (cell == nil) {
		NSArray *nibItems = [[NSBundle mainBundle] loadNibNamed:@"RepositoryItemTableViewCell" owner:self options:nil];
		cell = [nibItems objectAtIndex:0];
		NSAssert(nibItems, @"Failed to load object from NIB");
    }
    
    // Highlight colours
    [cell.filename setHighlightedTextColor:[UIColor whiteColor]];
    [cell.details setHighlightedTextColor:[UIColor whiteColor]];
    
    RepositoryItem *child = self.repositoryItem;
    NSString *filename = [child.metadata valueForKey:@"cmis:name"];
    if (!filename || ([filename length] == 0)) filename = child.title;
    [cell.filename setText:filename];
    [cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
    
    if ([child isFolder]) {
        
        UIImage * img = [UIImage imageNamed:@"folder.png"];
        cell.imageView.image  = img;
        cell.details.text = [[[NSString alloc] initWithFormat:@"%@", formatDocumentDate(child.lastModifiedDate)] autorelease]; // TODO: Externalize to a configurable property?        
    }
    else {
        NSString *contentStreamLengthStr = [child contentStreamLengthString];
        cell.details.text = [[[NSString alloc] initWithFormat:@"%@ | %@", formatDocumentDate(child.lastModifiedDate), 
                              [FileUtils stringForLongFileSize:[contentStreamLengthStr longLongValue]]] autorelease]; // TODO: Externalize to a configurable property?
        cell.imageView.image = imageForFilename(child.title);
    }
    
    BOOL showMetadataDisclosure = [[AppProperties propertyForKey:kBShowMetadataDisclosure] boolValue];
    if(showMetadataDisclosure) {
        [cell setAccessoryView:[self makeDetailDisclosureButton]];
    }

    return cell;
}

- (UITableViewCell *)createCellInTableView:(UITableView *)tableView
{
    [self setTableView:tableView];
    if(self.uploadInfo)
    {
        return [self createUploadCellInTableView:tableView];
    }
    else if(self.repositoryItem)
    {
        return [self createRepositoryInfoCellInTableView:tableView];
    }
    else 
    {
        return [self createSearchErrorCellInTableView:tableView];
    }
}

@end
