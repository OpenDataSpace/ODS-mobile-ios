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
// DocumentPickerTableDelegate
//

#define CELL_IDENTIFIER @"DocumentPickerCell"

#import "DocumentPickerTableDelegate.h"
#import "Utility.h"
#import "DocumentPickerViewController.h"
#import "DocumentPickerSelection.h"
#import "MBProgressHUD.h"

@implementation DocumentPickerTableDelegate

@synthesize progressHud = _HUD;
@synthesize documentPickerViewController = _documentPickerViewController;
@synthesize tableView = _tableView;
@synthesize delegate = _delegate;


#pragma mark Init & Dealloc

- (void)dealloc
{
    [_HUD release];
    [_tableView release];
    [super dealloc];
}

#pragma mark Data loading

- (void)loadDataForTableView:(UITableView *)tableView
{
    if (![self.delegate isDataAvailable])
    {
        // On the main thread, display the HUD
        self.tableView = tableView;
        self.progressHud = createAndShowProgressHUDForView(self.documentPickerViewController.view);

        [self.delegate loadData];
    }
}

#pragma mark Table view data source and delegate methods

- (void)tableViewDidLoad:(UITableView *)tableView
{
    if ([self.delegate isSelectionEnabled])
    {
        [tableView setEditing:YES];
        [tableView setAllowsMultipleSelectionDuringEditing:YES];

        if (self.documentPickerViewController.selection.isMultiSelectionEnabled)
        {
            [tableView setAllowsMultipleSelection:YES];
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.delegate.tableCount;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kDefaultTableCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = CELL_IDENTIFIER;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(createNewTableViewCell)])
        {
            cell = self.delegate.createNewTableViewCell;
        }
        else
        {
            cell = [self createNewTableViewCell];
        }
    }

    [self.delegate customizeTableViewCell:cell forIndexPath:indexPath];

    // http://stackoverflow.com/questions/2501386/uitableviewcell-setselected-but-selection-not-shown
    if ([self.delegate isSelectionEnabled] && [self.delegate isSelected:indexPath])
    {
        [[self tableView] selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }

    return cell;
}

- (UITableViewCell *)createNewTableViewCell
{
    return [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CELL_IDENTIFIER] autorelease];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // If single-select, clear anything that was selected before
    if (!self.documentPickerViewController.selection.isMultiSelectionEnabled
            && [self tableView:self.tableView canEditRowAtIndexPath:indexPath])
    {
        // Rempve from model
        [self.documentPickerViewController.selection clearAll];

        // Deselect if the tableView is still the same
        NSIndexPath *previousIndexPath = [self.tableView indexPathForSelectedRow];
        if (previousIndexPath)
        {
            [self.tableView deselectRowAtIndexPath:previousIndexPath animated:YES];
        }
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate didSelectRowAtIndexPath:indexPath];
    [self.documentPickerViewController selectionDidUpdate];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate didDeselectRowAtIndexPath:indexPath];
    [self.documentPickerViewController selectionDidUpdate];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.delegate isSelectionEnabled];
}

- (NSString *)titleForTable
{
    return [self.delegate titleForTable];
}


#pragma mark Utility methods

- (void)hideProgressHud
{
    stopProgressHUD(self.progressHud);
}

- (void)goOneLevelDeeperWithDocumentPicker:(DocumentPickerViewController *)documentPickerViewController
{
    documentPickerViewController.selection = self.documentPickerViewController.selection; // copying setting for selection, and already selected items
    [self.documentPickerViewController.navigationController pushViewController:documentPickerViewController animated:YES];
}

@end
