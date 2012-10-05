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
// TaskAttachmentsViewController 
//
#import "TaskAttachmentsViewController.h"
#import "RepositoryItem.h"
#import "Utility.h"
#import "DocumentPickerViewController.h"
#import "DocumentPickerSelection.h"

enum AttachmentSections {
    AttachmentSectionAdd = 0,
    AttachmentSectionAttachmentList,
    AttachmentNumberOfSections
};

@interface TaskAttachmentsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) UITableView *tableView;

@end

@implementation TaskAttachmentsViewController

@synthesize documentPickerViewController = _documentPickerViewController;
@synthesize attachments = _attachments;
@synthesize tableView = _tableView;

- (void)dealloc
{
    [_documentPickerViewController release];
    [_attachments release];
    [_tableView release];
    [super dealloc];
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"task.create.attachments", nil);
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"task.create.attachment.edit", nil)
                          style:UIBarButtonItemStyleDone target:self action:@selector(editButtonTapped)] autorelease];

    UITableView *tableView = [[UITableView alloc] initWithFrame:
            CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    tableView.delegate = self;
    tableView.dataSource = self;

    self.tableView = tableView;
    [self.view addSubview:tableView];

    [tableView release];
}

-(void)editButtonTapped
{
    [self.tableView setEditing:!self.tableView.editing animated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Reload data when navigation controller is popped to this one again.
    [self.tableView reloadData];
}

#pragma mark Table View delegate / datasource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case (AttachmentSectionAdd):
            return 1;
        case (AttachmentSectionAttachmentList):
            return self.attachments.count;
        default:
            NSLog(@"[Warning] Invalid section. Please check your code, you shouldn't be seeing this!");
            return 0;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return AttachmentNumberOfSections;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case (AttachmentSectionAdd):
            return [self createAddAttachmentCell];
        case (AttachmentSectionAttachmentList):
            return [self createAttachmentCellForRow:indexPath.row];
        default:
            NSLog(@"[Warning] Invalid section. Please check your code, you shouldn't be seeing this!");
            return nil;
    }
}

- (UITableViewCell *)createAddAttachmentCell
{
    static NSString *CellIdentifier = @"AttachmentCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    cell.textLabel.text = NSLocalizedString(@"task.create.attachment.select", nil);
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;

    return cell;
}

- (UITableViewCell *)createAttachmentCellForRow:(NSInteger)row
{
    static NSString *CellIdentifier = @"AttachmentCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    RepositoryItem *item = [self.attachments objectAtIndex:row];
    NSString *filename = [item.metadata valueForKey:@"cmis:name"];
    cell.textLabel.text =  ((!filename || [filename length] == 0) ? item.title : filename);
    cell.imageView.image = imageForFilename(item.title);
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.shouldIndentWhileEditing = NO;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == AttachmentSectionAdd)
    {
        [self.documentPickerViewController reopenAtLastLocationWithNavigationController:self.navigationController];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == AttachmentSectionAttachmentList;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [self.attachments removeObjectAtIndex:indexPath.row];
        [tableView reloadData];
    }
}

@end
