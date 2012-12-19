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
//  AccountCertificatesViewController.h
//
// Displays information about the identity that is currently linked to the account
// When no identity is linked, a button is provided to start the import process

#import "IFGenericTableViewController.h"
#import "ImportCertificateViewController.h"
@class AccountInfo;

@interface AccountCertificatesViewController : IFGenericTableViewController <ImportCertificateDelegate, UIAlertViewDelegate>
// The isNew property determines if a notification is triggered when a successful import occurs
// A notification when the account is new is not desired since it will make the incomplete account appear in the
// Manage Accounts list
@property (nonatomic, assign) BOOL isNew;

/*
 DI: The accountInfo is used to determine the accountUUID that the imported is going to be linked to and,
 in the case there is a linked identity to the account, display the identity/certificate information.
 */
- (id)initWithAccountInfo:(AccountInfo *)accountInfo;

@end
