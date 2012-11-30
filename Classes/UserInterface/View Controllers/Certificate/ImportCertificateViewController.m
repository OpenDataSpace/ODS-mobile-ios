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
            //Deleting old certificate and identities data from the keychain
            [[AccountManager sharedManager] deleteCertificatesForAccount:account];
            NSData *persistenceData = [[CertificateManager sharedManager] importIdentityData:certificateData withPasscode:passcode importStatus:&status];
            [account setIdentityKeys:[NSMutableArray arrayWithObject:persistenceData]];
        }
    } else {
        status = [[CertificateManager sharedManager] validateCertificate:certificateData];
        if (status == ImportCertificateStatusSucceeded)
        {
            //Deleting old certificate and identities data from the keychain
            [[AccountManager sharedManager] deleteCertificatesForAccount:account];
            NSData *persistenceData = [[CertificateManager sharedManager] importCertificateData:certificateData importStatus:&status];
            [account setCertificateKeys:[NSMutableArray arrayWithObject:persistenceData]];
        }
    }

    if (status == ImportCertificateStatusCancelled)
    {
        displayErrorMessageWithTitle(NSLocalizedString(@"certificate-import.error.authentication", @"Message for wrong passcode"),
                                     NSLocalizedString(@"certificate-import.error.title", @"Import Certificate error title"));
    }
    else if (status == ImportCertificateStatusFailed)
    {
        displayErrorMessageWithTitle(NSLocalizedString(@"certificate-import.error.format", @"Message for wrong certificate file"),
                                     NSLocalizedString(@"certificate-import.error.title", @"Import Certificate error title"));
    }
    else
    {
        //success
        [[AccountManager sharedManager] saveAccountInfo:account withNotification:NO];
        if ([self.delegate conformsToProtocol:@protocol(ImportCertificateDelegate) ])
        {
            [self.delegate importCertificateFinished];
        }
    }
    
    if ([[account identityKeys] count] > 0)
    {
        NSData *persistenceData = [[account identityKeys] objectAtIndex:0];
        NSDictionary *attributes = nil;
        
        FDCertificate *identity = [[CertificateManager sharedManager] identityForPersistenceData:persistenceData returnAttributes:&attributes];
        NSLog(@"Printing imported certificate");
        [self _printIdentity:[identity identityRef] attributes:attributes];
    }
    [self cleanUp];
}

- (void)cancelButtonAction:(id)sender
{
    if ([self.delegate conformsToProtocol:@protocol(ImportCertificateDelegate) ])
    {
        [self.delegate importCertificateCancelled];
    }
    [self cleanUp];
}

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

#pragma mark * Debugging certificate import
- (void)_printCertificate:(SecCertificateRef)certificate attributes:(NSDictionary *)attrs indent:(int)indent
// Prints a certificate for debugging purposes.  The indent parameter is necessary to
// allow different indents depending on whether the key is part of an identity or not.
{
    CFStringRef         summary;
    NSString *          label;
    NSData *            hash;
    
    assert(certificate != NULL);
    assert(attrs != nil);
    
    summary = SecCertificateCopySubjectSummary(certificate);
    assert(summary != NULL);
    
    label = [attrs objectForKey:(id)kSecAttrLabel];
    if (label != nil) {
        fprintf(stderr, "%*slabel   = '%s'\n", indent, "", [label UTF8String]);
    }
    fprintf(stderr, "%*ssummary = '%s'\n", indent, "", [(NSString *)summary UTF8String]);
    hash = [attrs objectForKey:(id)kSecAttrPublicKeyHash];
    if (hash != nil) {
        fprintf(stderr, "%*shash    = %s\n", indent, "", [[hash description] UTF8String]);
    }
    
    CFRelease(summary);
}

- (void)_printKey:(SecKeyRef)key attributes:(NSDictionary *)attrs attrName:(CFTypeRef)attrName flagValues:(const char *)flagValues
// Prints a flag within a key.
{
#pragma unused(key)
    id  flag;
    
    assert(key != NULL);
    assert(attrs != nil);
    assert(attrName != NULL);
    assert(flagValues != NULL);
    assert(strlen(flagValues) == 2);
    
    flag = [attrs objectForKey:(id)attrName];
    if (flag == nil) {
        fprintf(stderr, "-");
    } else if ([flag boolValue]) {
        fprintf(stderr, "%c", flagValues[0]);
    } else {
        fprintf(stderr, "%c", flagValues[1]);
    }
}

- (void)_printKey:(SecKeyRef)key attributes:(NSDictionary *)attrs indent:(int)indent
// Prints a key for debugging purposes.  The indent parameter is necessary to allow
// different indents depending on whether the key is part of an identity or not.
{
#pragma unused(key)
    id          label;
    CFTypeRef   keyClass;
    
    assert(key != NULL);
    assert(attrs != nil);
    
    label = [attrs objectForKey:(id)kSecAttrLabel];
    if (label != nil) {
        fprintf(stderr, "%*slabel     = '%s'\n", indent, "", [label UTF8String]);
    }
    label = [attrs objectForKey:(id)kSecAttrApplicationLabel];
    if (label != nil) {
        fprintf(stderr, "%*sapp label = %s\n", indent, "", [[label description] UTF8String]);
    }
    label = [attrs objectForKey:(id)kSecAttrApplicationTag];
    if (label != nil) {
        fprintf(stderr, "%*sapp tag   = %s\n", indent, "", [[label description] UTF8String]);
    }
    fprintf(stderr, "%*sflags     = ", indent, "");
    [self _printKey:key attributes:attrs attrName:kSecAttrCanEncrypt flagValues:"Ee"];
    [self _printKey:key attributes:attrs attrName:kSecAttrCanDecrypt flagValues:"Dd"];
    [self _printKey:key attributes:attrs attrName:kSecAttrCanDerive  flagValues:"Rr"];
    [self _printKey:key attributes:attrs attrName:kSecAttrCanSign    flagValues:"Ss"];
    [self _printKey:key attributes:attrs attrName:kSecAttrCanVerify  flagValues:"Vv"];
    [self _printKey:key attributes:attrs attrName:kSecAttrCanWrap    flagValues:"Ww"];
    [self _printKey:key attributes:attrs attrName:kSecAttrCanUnwrap  flagValues:"Uu"];
    fprintf(stderr, "\n");
    
    keyClass = (CFTypeRef) [attrs objectForKey:(id)kSecAttrKeyClass];
    if (keyClass != nil) {
        const char *    keyClassStr;
        
        // keyClass is a CFNumber whereas kSecAttrKeyClassPublic (and so on)
        // are CFStrings.  Gosh, that makes things hard <rdar://problem/6914637>.
        // So I compare their descriptions.  Yuck!
        
        if ( [[(id)keyClass description] isEqual:(id)kSecAttrKeyClassPublic] ) {
            keyClassStr = "kSecAttrKeyClassPublic";
        } else if ( [[(id)keyClass description] isEqual:(id)kSecAttrKeyClassPrivate] ) {
            keyClassStr = "kSecAttrKeyClassPrivate";
        } else if ( [[(id)keyClass description] isEqual:(id)kSecAttrKeyClassSymmetric] ) {
            keyClassStr = "kSecAttrKeyClassSymmetric";
        } else {
            keyClassStr = "?";
        }
        fprintf(stderr, "%*skey class = %s\n", indent, "", keyClassStr);
    }
}

- (void)_printIdentity:(SecIdentityRef)identity attributes:(NSDictionary *)attrs
// Prints an identity for debugging purposes.
{
    OSStatus            err;
    SecCertificateRef   certificate;
    SecKeyRef           key;
    
    assert(identity != NULL);
    assert(attrs != nil);
    
    err = SecIdentityCopyCertificate(identity, &certificate);
    assert(err == noErr);
    
    err = SecIdentityCopyPrivateKey(identity, &key);
    assert(err == noErr);
    
    fprintf(stderr, "    certificate\n");
    [self _printCertificate:certificate attributes:attrs indent:6];
    fprintf(stderr, "    key\n");
    [self _printKey:key attributes:attrs indent:6];
    
    CFRelease(key);
    CFRelease(certificate);
}



@end
