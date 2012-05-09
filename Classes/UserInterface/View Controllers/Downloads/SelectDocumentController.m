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
//  SelectDocumentController.m
//

#import "SelectDocumentController.h"
#import "FolderTableViewDataSource.h"

@implementation SelectDocumentController
@synthesize multiSelection = _multiSelection;
@synthesize delegate = _delegate;

- (void)viewDidLoad 
{
    [super viewDidLoad];
	[self setTitle:NSLocalizedString(@"select-document", @"SelectDocument View Title")];
    
    [self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(performCancel:)] autorelease]];
    if(self.multiSelection)
    {
        [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(performDone:)] autorelease]];
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
    }
    
    [self.tableView setAllowsMultipleSelectionDuringEditing:self.multiSelection];
    [self.tableView setEditing:YES];
    //[(FolderTableViewDataSource *)self.dataSource setMultiSelection:self.multiSelection];
}

#pragma mark -
#pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FolderTableViewDataSource *datasource = (FolderTableViewDataSource *)[tableView dataSource];
    if(!self.multiSelection)
    {
        NSURL *fileURL = [datasource cellDataObjectForIndexPath:indexPath];
        self.selectedFile = fileURL;
        [self dismissModalViewControllerAnimated:YES];
        
        if(self.delegate && [self.delegate respondsToSelector:@selector(savedDocumentPicker:didPickDocument:)]) {
            [self.delegate savedDocumentPicker:(SavedDocumentPickerController *) self.navigationController didPickDocument:[fileURL absoluteString]];
        }
    }
    else 
    {
        NSInteger selectedCount = [[tableView indexPathsForSelectedRows] count];
        [self.navigationItem.rightBarButtonItem setEnabled:(selectedCount != 0)];
    }
}

#pragma mark -
#pragma mark Handling Cancel
- (void) performCancel: (id) sender {
    if(self.delegate && [self.delegate respondsToSelector:@selector(savedDocumentPickerDidCancel:)]) {
        [self.delegate savedDocumentPickerDidCancel: (SavedDocumentPickerController *)self.navigationController];
    }
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void) performDone: (id) sender {
    if(self.delegate && [self.delegate respondsToSelector:@selector(savedDocumentPicker:didPickDocuments:)]) {
        FolderTableViewDataSource *datasource = (FolderTableViewDataSource *)[self dataSource];
        [self.delegate savedDocumentPicker:(SavedDocumentPickerController *)self.navigationController didPickDocuments:[datasource selectedDocumentsURLs]];
    }
    
    [self dismissModalViewControllerAnimated:YES];
}

@end
