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
//  ManageCertificatesViewController.m
//
//

#import "ManageCertificatesViewController.h"
#import "TableCellViewController.h"
#import "CertificateLocationViewController.h"

@interface ManageCertificatesViewController ()
@property (nonatomic, copy) NSString *accountUUID;
@property (nonatomic, retain) NSMutableArray *certificates;
@property (nonatomic, retain) UIBarButtonItem *reorderButton;
@property (nonatomic, retain) UIBarButtonItem *saveButton;

@end

@implementation ManageCertificatesViewController
@synthesize accountUUID = _accountUUID;
@synthesize certificates = _certificates;
@synthesize reorderButton = _reorderButton;
@synthesize saveButton = _saveButton;

- (void)dealloc
{
    [_accountUUID release];
    [_certificates release];
    [_reorderButton release];
    [_saveButton release];
    [super dealloc];
}

- (id)initWithAccountUUID:(NSString *)accountUUID
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self)
    {
        _accountUUID = [accountUUID copy];
        
        //Temporal certificate dummy data
        _certificates = [[NSMutableArray arrayWithObjects:@"Certificate 1", @"Certificate 2", @"Certificate 3", nil] retain];
        
        _reorderButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(enableReorderMode)];
        _saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(disableReorderMode)];
    }
    return self;
}

/*
 Adds the navigation bar right button to allow the certificate reordering
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationItem setRightBarButtonItem:self.reorderButton];
}

- (void)enableReorderMode
{
    [self.navigationItem setRightBarButtonItem:self.saveButton animated:YES];
    [self.tableView setEditing:YES animated:YES];
}

- (void)disableReorderMode
{
    [self.navigationItem setRightBarButtonItem:self.reorderButton animated:YES];
    [self.tableView setEditing:NO animated:YES];
    //TODO: Persist the change in the order of the certificates
}

- (void)constructTableGroups
{
    NSMutableArray *headers = [NSMutableArray array];
    NSMutableArray *groups = [NSMutableArray array];
    
    [headers addObject:NSLocalizedString(@"certificate-manage.header.title", @"Certificate Manage - Title for the table main group's header")];
    
    NSMutableArray *certificatesGroup = [NSMutableArray array];
    for (NSString *certificateName in self.certificates)
    {
        TableCellViewController *certificateCell = [[[TableCellViewController alloc] initWithAction:NULL onTarget:nil] autorelease];
        [certificateCell.textLabel setText:certificateName];
        [certificateCell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [certificateCell setCellHeight:44.0f];
        [certificateCell setBackgroundColor:[UIColor whiteColor]];
        [certificateCell.textLabel setFont:[UIFont boldSystemFontOfSize:17.0f]];
        [certificatesGroup addObject:certificateCell];
    }
    
    TableCellViewController *addCertificateCell = [[[TableCellViewController alloc] initWithAction:@selector(addCertificateAction:) onTarget:self] autorelease];
    [addCertificateCell.textLabel setText:NSLocalizedString(@"certificate-manage.add-cell.label", @"Certificate Manage - Label for the add certificate cell's label")];
    [addCertificateCell setSelectionStyle:UITableViewCellSelectionStyleBlue];
    [addCertificateCell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    [addCertificateCell setCellHeight:44.0f];
    [addCertificateCell setBackgroundColor:[UIColor whiteColor]];
    [addCertificateCell.textLabel setFont:[UIFont boldSystemFontOfSize:17.0f]];
    [certificatesGroup addObject:addCertificateCell];
    
    [groups addObject:certificatesGroup];
    tableHeaders = [headers retain];
    tableGroups = [groups retain];
}

/*
 Support for the reordering of the certificates
 The operations do not persist the certificates until the user taps on the save button
 */
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger rows = [self tableView:tableView numberOfRowsInSection:indexPath.section];
    
    //The "Add new certificate" cell (at the end of the section) cannot be moved
    return indexPath.row != (rows - 1);
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    NSMutableArray *certificatesGroup = [tableGroups objectAtIndex:0];
    [self.certificates exchangeObjectAtIndex:sourceIndexPath.row withObjectAtIndex:destinationIndexPath.row];
    [certificatesGroup exchangeObjectAtIndex:sourceIndexPath.row withObjectAtIndex:destinationIndexPath.row];
}

/*
 Support for deleting certificates.
 The operations do not persist the certificates until the user taps on the save button
 */
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger rows = [self tableView:tableView numberOfRowsInSection:indexPath.section];
    
    //The "Add new certificate" cell (at the end of the section) cannot be removed
    return indexPath.row != (rows - 1);
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEditing])
    {
        return UITableViewCellEditingStyleNone;
    }

    return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *certificatesGroup = [tableGroups objectAtIndex:0];
    [self.certificates removeObjectAtIndex:indexPath.row];
    [certificatesGroup removeObjectAtIndex:indexPath.row];
}

- (void)addCertificateAction:(id)sender
{
    CertificateLocationViewController *locationController = [[[CertificateLocationViewController alloc] initWithAccountUUID:self.accountUUID] autorelease];
    [self.navigationController pushViewController:locationController animated:YES];
}

@end
