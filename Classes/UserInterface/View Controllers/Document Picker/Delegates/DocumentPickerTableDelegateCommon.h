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
// DocumentPickerTableDelegateCommon 
//
#import <Foundation/Foundation.h>
#import "DocumentPickerTableDelegate.h"

@class DocumentPickerViewController;
@class MBProgressHUD;


@protocol DocumentPickerTableDelegateFunctionality <NSObject>

@required

- (NSInteger)tableCount;
- (BOOL)isDataAvailable;
- (void)loadData;

- (void)customizeTableViewCell:(UITableViewCell *)tableViewCell forIndexPath:(NSIndexPath *)indexPath;

- (BOOL)isSelected:(NSIndexPath *)indexPath;
- (void)didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)didDeselectRowAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)isSelectionEnabled;

- (NSString *)titleForTable;

@optional
- (UITableViewCell *)createNewTableViewCell;

@end


@interface DocumentPickerTableDelegateCommon : NSObject <DocumentPickerTableDelegate>

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) MBProgressHUD *progressHud;

@property (nonatomic, assign) id<DocumentPickerTableDelegateFunctionality> delegate;

// Utility methods

- (void)hideProgressHud;
- (void)goOneLevelDeeperWithDocumentPicker:(DocumentPickerViewController *)documentPickerViewController;

@end
