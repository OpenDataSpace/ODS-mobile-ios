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
@synthesize delegate;

- (void)viewDidLoad {
    [super viewDidLoad];
	[self setTitle:NSLocalizedString(@"select-document", @"SelectDocument View Title")];
    
    if(!IS_IPAD)
    {
        [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(performCancel:)] autorelease]];
    } else {
        [self.navigationItem setRightBarButtonItem:nil];
    }
}

#pragma mark -
#pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSURL *fileURL = [(FolderTableViewDataSource *)[tableView dataSource] cellDataObjectForIndexPath:indexPath];
    self.selectedFile = fileURL;
    [self dismissModalViewControllerAnimated:YES];
    
    if(self.delegate) {
        [self.delegate savedDocumentPicker:(SavedDocumentPickerController *) self.navigationController didPickDocument:[fileURL absoluteString]];
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

@end
