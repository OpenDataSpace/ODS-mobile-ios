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
//  AwaitingVerificationViewController.h
//
// Presents a view to the user with a description of the current status of the account
// (Awaiting for verification) in the settings mode it provides actions for the account:
// Resend email, Refresh (status), Delete Account

#import "IFGenericTableViewController.h"
#import "TTTAttributedLabel.h"
#import "ASIHTTPRequest.h"
@class NewCloudAccountHTTPRequest;
@class AccountStatusHTTPRequest;

@interface AwaitingVerificationViewController : IFGenericTableViewController <TTTAttributedLabelDelegate, UIAlertViewDelegate, ASIHTTPRequestDelegate>

// Determines the ViewControllers' mode
// this property is set by the object that creates this controller, Default is Browse mode
@property (nonatomic, assign) BOOL isSettings;
// Holds a reference to the resendEmail request
@property (nonatomic, retain) NewCloudAccountHTTPRequest *resendEmailRequest;
// Holds a reference to the accountStatus (Refresh) request
@property (nonatomic, retain) AccountStatusHTTPRequest *accountStatusRequest;
// Account selected set by the object that creates this controller
@property (nonatomic, copy) NSString *selectedAccountUUID;

@end
