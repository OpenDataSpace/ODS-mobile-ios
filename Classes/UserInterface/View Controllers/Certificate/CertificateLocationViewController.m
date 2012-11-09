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
//  CertificateLocationViewController.m
//
//

#import "CertificateLocationViewController.h"
#import "TableCellViewController.h"
#import "SelectDocumentController.h"
#import "CertificateDocumentFilter.h"
#import "NetworkCertificateViewController.h"

@interface CertificateLocationViewController ()
@property (nonatomic, copy) NSString *accountUUID;
@property (nonatomic, retain) SavedDocumentPickerController *documentPicker;

@end

@implementation CertificateLocationViewController
@synthesize importDelegate = _importDelegate;
//Private properties
@synthesize accountUUID = _accountUUID;
@synthesize documentPicker = _documentPicker;

- (void)dealloc
{
    [_accountUUID release];
    [_documentPicker release];
    [super dealloc];
}

- (id)initWithAccountUUID:(NSString *)accountUUID
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self)
    {
        _accountUUID = [accountUUID copy];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setTitle:NSLocalizedString(@"certificate-location.title", @"Title for the CertificateLocationViewController")];
}

- (void)constructTableGroups
{
    NSMutableArray *headers = [NSMutableArray array];
    NSMutableArray *groups = [NSMutableArray array];
    
    [headers addObject:@""];
    
    NSMutableArray *choicesGroup = [NSMutableArray array];
    TableCellViewController *localCertificateCell = [[[TableCellViewController alloc] initWithAction:@selector(localFileAction:) onTarget:self] autorelease];
    [localCertificateCell.textLabel setText:NSLocalizedString(@"certificate-location.local-cell.label", @"Label for the cell to add a new certificate located in the Documents folder")];
    [localCertificateCell setSelectionStyle:UITableViewCellSelectionStyleBlue];
    [localCertificateCell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    [localCertificateCell setCellHeight:44.0f];
    [localCertificateCell setBackgroundColor:[UIColor whiteColor]];
    [localCertificateCell.textLabel setFont:[UIFont boldSystemFontOfSize:17.0f]];
    [choicesGroup addObject:localCertificateCell];
    
    TableCellViewController *networkCertificateCell = [[[TableCellViewController alloc] initWithAction:@selector(byNetworkAction:) onTarget:self] autorelease];
    [networkCertificateCell.textLabel setText:NSLocalizedString(@"certificate-location.network-cell.label", @"Label for the cell to add a new certificate located in the Network")];
    [networkCertificateCell setSelectionStyle:UITableViewCellSelectionStyleBlue];
    [networkCertificateCell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    [networkCertificateCell setCellHeight:44.0f];
    [networkCertificateCell setBackgroundColor:[UIColor whiteColor]];
    [networkCertificateCell.textLabel setFont:[UIFont boldSystemFontOfSize:17.0f]];
    [choicesGroup addObject:networkCertificateCell];
    
    [groups addObject:choicesGroup];
    tableHeaders = [headers retain];
    tableGroups = [groups retain];
}

- (void)localFileAction:(id)sender
{
    SelectDocumentController *documentPicker = [[[SelectDocumentController alloc] initWithStyle:UITableViewStylePlain] autorelease];
    [documentPicker setMultiSelection:NO];
    [documentPicker setNoDocumentsFooterTitle:NSLocalizedString(@"certificate-location.noDocumentsFooterTitle", @"Title for the no documents available footer")];
    [documentPicker setDelegate:self];
    
    CertificateDocumentFilter *filter = [[[CertificateDocumentFilter alloc] init] autorelease];
    [documentPicker setDocumentFilter:filter];
    
    [self.navigationController pushViewController:documentPicker animated:YES];
}

- (void)byNetworkAction:(id)sender
{
    NetworkCertificateViewController *networkCertificate = [[[NetworkCertificateViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
    [networkCertificate setTarget:self];
    [networkCertificate setAction:@selector(networkCertificateFinished:)];
    [self.navigationController pushViewController:networkCertificate animated:YES];
 
}

#pragma mark - SavedDocumentPickerControllerDelegate methods
- (void)savedDocumentPicker:(SavedDocumentPickerController *)picker didPickDocuments:(NSArray *)documentURLs
{
    NSLog(@"Documents: %@", documentURLs);
    //[self.navigationController popViewControllerAnimated:NO];
    [self networkCertificateFinished:[documentURLs objectAtIndex:0]];
}

- (void)savedDocumentPickerDidCancel:(SavedDocumentPickerController *)picker
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)networkCertificateFinished:(NSString *)path
{
    [self.navigationController popViewControllerAnimated:NO];
    ImportCertificateViewController *importCertificate = [[[ImportCertificateViewController alloc] initWithCertificatePath:path andAccountUUID:self.accountUUID] autorelease];
    [importCertificate setDelegate:self.importDelegate];
    [self.navigationController pushViewController:importCertificate animated:YES];
}


@end
