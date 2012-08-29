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
// DocumentPickerTableDelegate
//

#import <Foundation/Foundation.h>
#import "DocumentPickerViewController.h"

@class DocumentPickerViewController;
@class MBProgressHUD;


@protocol DocumentPickerTableDelegateFunctionality <NSObject>

@required

- (NSInteger)tableCount;
- (BOOL)isDataAvailable;
- (void)loadData;

- (void)customizeTableViewCell:(UITableViewCell *)tableViewCell forIndexPath:(NSIndexPath *)indexPath;

- (BOOL)isSelectionEnabled;
- (BOOL)isSelected:(NSIndexPath *)indexPath;
- (void)didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)didDeselectRowAtIndexPath:(NSIndexPath *)indexPath;

- (NSString *)titleForTable;

- (void)clearCachedData;

@optional
- (UITableViewCell *)createNewTableViewCell;

@end


@interface DocumentPickerTableDelegate : NSObject <UITableViewDelegate, UITableViewDataSource>

// Views
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) MBProgressHUD *progressHud;

// Delegate implementing the functionality that is required behind the covers by this class
@property (nonatomic, assign) id<DocumentPickerTableDelegateFunctionality> delegate;

// The document picker controller that uses this delegate
@property (nonatomic, assign) DocumentPickerViewController *documentPickerViewController;

// The DocumentPickerViewController will call this method every time the view is put on the screen for the user.
// This is the cue for the delegate to start (preferably asynchronously) loading the data.
//
// Do note that when going back and forth in the navigation controller through several instances
// of the DocumentPickerViewController, this method will be called each time again when the view is displayed.
// So it is wise to do any caching in the delegate and avoid reloading the data when it's not necessary.
- (void)loadDataForTableView:(UITableView *)tableView;

// Called by the DocumentPickerViewController after creating the table view for this delegate.
// Allows to do extra customization, eg. enable/disable selection, etc.
- (void)tableViewDidLoad:(UITableView *)tableView;

// Will be used as title for the navigation controller in which the DocumentPickerViewController is used.
// As this is often depending on the data, the delegate is responsible to generate a title.
- (NSString *)titleForTable;

// Utility methods for subclasses

- (void)showProgressHud;
- (void)hideProgressHud;
- (void)goOneLevelDeeperWithDocumentPicker:(DocumentPickerViewController *)documentPickerViewController;

@end
