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
@protocol DocumentPickerTableDelegate;
@class RepositoryInfo;


@interface DocumentPickerViewController : UIViewController

// Creates the default document picker, starts by showing an account selection
+ (DocumentPickerViewController *)documentPicker;

// Creates a document picker, which shows the repositories for a given account
+ (DocumentPickerViewController *)documentPickerForAccount:(AccountInfo *)accountInfo;

// Creates a document picker, which shows the sites for a given repository.
+ (DocumentPickerViewController *)documentPickerForRepository:(RepositoryInfo *)repositoryInfo;

@end
