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
//  AccountViewController.h
//

#import <UIKit/UIKit.h>
#import "IFGenericTableViewController.h"
@class AccountInfo;
@class AccountViewController;
@class IFTextCellController;

@protocol AccountViewControllerDelegate <NSObject>
- (void)accountControllerDidFinishSaving:(AccountViewController *)accountViewController;
- (void)accountControllerDidCancel:(AccountViewController *)accountViewController;
@end

@interface AccountViewController : IFGenericTableViewController <AccountViewControllerDelegate, UIAlertViewDelegate> {
    BOOL isEdit;
    BOOL isNew;
    AccountInfo *accountInfo;
    
    //Only used for edits
    id<AccountViewControllerDelegate> delegate;
    BOOL userChangedPort;
    BOOL shouldSetResponder;
    
    IFTextCellController *usernameCell;
    UIBarButtonItem *saveButton;
}

@property (nonatomic, assign) BOOL isEdit;
@property (nonatomic, assign) BOOL isNew;
@property (nonatomic, retain) AccountInfo *accountInfo;
@property (nonatomic, assign) id<AccountViewControllerDelegate> delegate;
@property (nonatomic, retain) IFTextCellController *usernameCell;
@property (nonatomic, retain) UIBarButtonItem *saveButton;

@end

// Account field keys
extern NSString * const kAccountDescriptionKey;
extern NSString * const kAccountHostnameKey;
extern NSString * const kAccountPortKey;
extern NSString * const kAccountProtocolKey;
extern NSString * const kAccountBoolProtocolKey;
extern NSString * const kAccountMultitenantKey;
extern NSString * const kAccountMultitenantStringKey;
extern NSString * const kAccountUsernameKey;
extern NSString * const kAccountPasswordKey;
extern NSString * const kAccountConfirmPasswordKey;
extern NSString * const kAccountVendorKey;
extern NSString * const kAccountServiceDocKey;
extern NSString * const kAccountFirstNameKey;
extern NSString * const kAccountLastNameKey;
