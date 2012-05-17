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
//  PasswordPromptViewController.h
//
// Handles the user input for a password for a given account.
// When creating with an account, the dialog will show basic account information
// and an input for a password.
// A delegate will be called in the event of a save or a cancel from the user.

#import "IFGenericTableViewController.h"
@class AccountInfo;
@protocol PasswordPromptDelegate;

@interface PasswordPromptViewController : IFGenericTableViewController
{
    UIBarButtonItem *_saveButton;
}

@property (nonatomic, retain) AccountInfo *accountInfo;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, assign) id<PasswordPromptDelegate> delegate;

- (id)initWithAccountInfo:(AccountInfo *)accountInfo;
@end

@protocol PasswordPromptDelegate <NSObject>

- (void)passwordPrompt:(PasswordPromptViewController *)passwordPrompt savedWithPassword:(NSString *)password;
- (void)passwordPromptWasCancelled:(PasswordPromptViewController *)passwordPrompt;

@end
