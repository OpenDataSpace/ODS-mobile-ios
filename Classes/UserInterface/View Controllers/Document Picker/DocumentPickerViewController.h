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
// AccountSelectionViewController 
//
#import <Foundation/Foundation.h>

@class AccountInfo;
@class RepositoryInfo;
@class RepositoryItem;
@class DocumentPickerSelection;


@interface DocumentPickerViewController : UIViewController

// Allows to configure which types can be selected. Also contains the results of the picking.
@property (nonatomic, retain) DocumentPickerSelection *selection;

// Creates the default document picker, starts by showing an account selection
+ (DocumentPickerViewController *)documentPicker;

// Creates the default document picker, starts by showing an account selection
// The 'optimize' parameter allows to specify if you want magic or not.
// Meaning: if set to YES, and you have only one active account at the moment,
// account selection will be skipped and you will see straight away the repositories.
+ (DocumentPickerViewController *)documentPickerWithOptimization:(BOOL)optimize;

// Creates a document picker, which shows the repositories for a given account
// Won't show the repositories in case the account is non-multi tenant.
+ (DocumentPickerViewController *)documentPickerForAccount:(AccountInfo *)account;

// Creates a document picker, which shows the repositories for a given account
// The 'optimize' parameter allows to specify if you want magic or not.
// Meaning: if set to YES, and the account is not multi tenant, you won't see the repository selection.
+ (DocumentPickerViewController *)documentPickerForAccount:(AccountInfo *)account optimize:(BOOL)optimize;

// Creates a document picker, which shows the sites for a given repository.
+ (DocumentPickerViewController *)documentPickerForRepository:(RepositoryInfo *)repositoryInfo;

// Creates a document picker, which shows the content of a given node (site or folder).
+ (DocumentPickerViewController *)documentPickerForRepositoryItem:(RepositoryItem *)repositoryItem accountUuid:(NSString *)accountUuid tenantId:(NSString *)tenantId;

// Delegates can call this if they changed something in the selection.
// The document picker count labels will be adjusted according the current selection.
- (void)selectionDidUpdate;

@end
