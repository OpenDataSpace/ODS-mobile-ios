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
//  ImportCertificateViewController.m
//
//

#import "ImportCertificateViewController.h"
#import "IFTemporaryModel.h"
#import "IFTextCellController.h"
#import "Utility.h"
#import "CertificateManager.h"
#import "AccountManager.h"
#import "FDCertificate.h"
#import "FileUtils.h"

NSString * const kImportCertificatePasscodeKey = @"passcode";
NSString * const kImportCertificatePKCS12Type = @"application/x-pkcs12";


@interface ImportCertificateViewController ()
@property (nonatomic, copy) NSString *certificatePath;
@property (nonatomic, copy) NSString *accountUUID;
@property (nonatomic, assign, readonly) BOOL isPKCS12;

@end

@implementation ImportCertificateViewController
@synthesize type = _type;
@synthesize delegate = _delegate;
//Private properties
@synthesize certificatePath = _certificatePath;
@synthesize accountUUID = _accountUUID;

- (void)dealloc
{
    [_type release];
    [_certificatePath release];
    [_accountUUID release];
    [super dealloc];
}

- (id)initWithCertificatePath:(NSString *)path andAccountUUID:(NSString *)accountUUID
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self)
    {
        _certificatePath = [path copy];
        _accountUUID = [accountUUID copy];
        _type = kImportCertificatePKCS12Type;
    }
    return self;
}

- (BOOL)isPKCS12
{
    return [self.type isEqual:kImportCertificatePKCS12Type];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //The certificate filename
    [self setTitle:[self.certificatePath lastPathComponent]];
    UIBarButtonItem *importButton = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"certificate-import.button.import", @"Import button label") style:UIBarButtonItemStyleDone target:self action:@selector(importButtonAction:)] autorelease];
    styleButtonAsDefaultAction(importButton);
    [self.navigationItem setRightBarButtonItem:importButton];
    
    UIBarButtonItem *cancelButton = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"closeButtonText", @"Cancel Button Text") style:UIBarButtonItemStyleDone target:self action:@selector(cancelButtonAction:)] autorelease];
    styleButtonAsDestructiveAction(cancelButton);
    [self.navigationItem setLeftBarButtonItem:cancelButton];
}

- (void)constructTableGroups
{
    if (!self.model)
    {
        [self setModel:[[[IFTemporaryModel alloc] init] autorelease]];
    }
    
    IFTextCellController *passcodeCell = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"certificate-import.fields.passcode", @"Passcode field label")
                                                                       andPlaceholder:NSLocalizedString(@"accountdetails.placeholder.optional", @"optional")
                                                                                atKey:kImportCertificatePasscodeKey
                                                                              inModel:self.model] autorelease];
    [passcodeCell setReturnKeyType:UIReturnKeyDone];
    [passcodeCell setSecureTextEntry:YES];
    
    
    NSMutableArray *headers =[NSMutableArray arrayWithObject:
                              NSLocalizedString(@"certificate-import.tableHeader", @"Table header for the Import Certificate View")];
    NSMutableArray *groups = [NSMutableArray arrayWithObject:[NSMutableArray arrayWithObject:passcodeCell]];
    NSMutableArray *footers =[NSMutableArray arrayWithObject:
                              NSLocalizedString(@"certificate-import.tableFooter", @"Table footer for the Import Certificate View")];
    tableHeaders = [headers retain];
    tableGroups = [groups retain];
    tableFooters = [footers retain];
}

- (void)importButtonAction:(id)sender
{    
    NSLog(@"Importing certificate file: %@", self.certificatePath);
    ImportCertificateStatus  status;
    NSData *certificateData = [NSData dataWithContentsOfFile:self.certificatePath];
    AccountInfo *account = [[AccountManager sharedManager] accountInfoForUUID:self.accountUUID];
    
    if (self.isPKCS12) {
        NSString *passcode = [self.model objectForKey:kImportCertificatePasscodeKey];
        status = [[CertificateManager sharedManager] validatePKCS12:certificateData withPasscode:passcode];
        
        if (status == ImportCertificateStatusSucceeded)
        {
            // The CertificateManager does the actual save of the pkcs12 data and passcode into the keychain
            [[CertificateManager sharedManager] saveIdentityData:certificateData withPasscode:passcode forAccountUUID:self.accountUUID];
        }
    } else {
        // Only PKCS12 files are supported
        status = ImportCertificateStatusFailed;
    }

    // Cancelled means that the passcode validation failed
    if (status == ImportCertificateStatusCancelled)
    {
        displayErrorMessageWithTitle(NSLocalizedString(@"certificate-import.error.authentication", @"Message for wrong passcode"),
                                     NSLocalizedString(@"certificate-import.error.title", @"Import Certificate error title"));
    }
    // Failed means any other error, usually incorrect encryption / wrong data
    else if (status == ImportCertificateStatusFailed)
    {
        displayErrorMessageWithTitle(NSLocalizedString(@"certificate-import.error.format", @"Message for wrong certificate file"),
                                     NSLocalizedString(@"certificate-import.error.title", @"Import Certificate error title"));
    }
    else
    {
        // Delegating the success
        if ([self.delegate conformsToProtocol:@protocol(ImportCertificateDelegate) ])
        {
            [self.delegate importCertificateFinished];
        }
    }
    
    FDCertificate *certificateWrapper = [account certificateWrapper];
    if (certificateWrapper)
    {
        NSLog(@"Imported certificate summary: %@", certificateWrapper.summary);
    }
    [self cleanUp];
}

- (void)cancelButtonAction:(id)sender
{
    // The cancel is delegated
    if ([self.delegate conformsToProtocol:@protocol(ImportCertificateDelegate) ])
    {
        [self.delegate importCertificateCancelled];
    }
    [self cleanUp];
}

/*
 Cleans up temporal certificate files. 
 Only files in the temporal folder are deletes, since we might be working with a file
 from the downloads folder
*/
- (void)cleanUp
{
    if ([self.certificatePath isEqualToString:[FileUtils
                                               pathToTempFile:[self.certificatePath lastPathComponent]]])
    {
        //Delete the certificate if it was downloaded from the network
        [[NSFileManager defaultManager] removeItemAtPath:self.certificatePath error:nil];
    }
}

#pragma mark - IFCellControllerFirstResponder

- (void)lastResponderIsDone: (NSObject<IFCellController> *)cellController
{
	[super lastResponderIsDone:cellController];
    [self importButtonAction:cellController];
}

@end
