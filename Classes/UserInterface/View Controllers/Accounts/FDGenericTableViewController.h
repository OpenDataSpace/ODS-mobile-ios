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
//  FDGenericTableViewController.h
//
// A configurable GenericTableViewController. It decouples datasource, the row rendering and the actions into different delegate objects.
// We can effectively reuse delegates for differente controllers, for example the Accounts view in the Browse Tab uses the same datasource, row rendering than the Accounts in the More Tab but the action when you tap the account is different.
// By default it uses a configuration plist, read by the FDGenericTableViewPlistReader object, and loded into the properties of the FDGenericTableViewController
// Created initially to replace the AccountsControllers but can be easily extended to support a wider array of TableViewControllers with a plist configuration

#import "IFGenericTableViewController.h"
@class FDGenericTableViewPlistReader;
@class FDGenericTableViewController;

/*
 Datasource protocol used by the datasource delegate.
 It delegates the retrieval of the data used by the view controller.
 */
@protocol FDDatasourceProtocol <NSObject>
// Retrieves the datasource in the form of a NSDictionary, and used by the rowRenderDelegate and the actionsDelegate
- (NSDictionary *)datasource;
@optional
// Lets the FDGenericTableViewController subscribe for a datasource change so it can now when to refresh the TableView rows
- (void)delegate:(id)delegate forDatasourceChangeWithSelector:(SEL)action;
@end

/*
 Row Render protocol used by the rowRender delegate.
 It delegates the creation of the rows and returns the groups, footers and headers for the GenericTableView
 The cell controller must handle the user interaction like a row tap or an accessory button tap.
 */
@protocol FDRowRenderProtocol <NSObject>
- (BOOL)allowsSelection;
- (NSArray *)tableGroupsWithDatasource:(NSDictionary *)datasource;
- (NSArray *)tableHeadersWithDatasource:(NSDictionary *)datasource;
- (NSArray *)tableFootersWithDatasource:(NSDictionary *)datasource;
@end

/*
 Action protocol used by the actions delegate.
 It delegates user actions like a tap to the right button
 */
@protocol FDTableViewActionsProtocol <NSObject>
@optional
- (void)rowWasSelectedAtIndexPath:(NSIndexPath *)indexPath withDatasource:(NSDictionary *)datasource andController:(FDGenericTableViewController *)controller;
- (void)rightButtonActionWithDatasource:(NSDictionary *)datasource;
- (void)commitEditingForIndexPath:(NSIndexPath *)indexPath withDatasource:(NSDictionary *)datasource;
// Called in the event of a datasource change.
// Will also be called when we first retrieve the datasource
- (void)datasourceChanged:(NSDictionary *)datasource inController:(FDGenericTableViewController *)controller notification:(NSNotification *)notification;
@end

@protocol FDTargetActionProtocol <NSObject>
- (void)setAction:(SEL)action;
- (void)setTarget:(id)target;
@end

@interface FDGenericTableViewController : IFGenericTableViewController
@property (nonatomic, retain) FDGenericTableViewPlistReader *settingsReader;
@property (nonatomic, retain) UIBarButtonItem *rightButton;
@property (nonatomic, assign) UITableViewCellEditingStyle editingStyle;
@property (nonatomic, assign) UITableViewStyle tableStyle;
@property (nonatomic, retain) NSDictionary *datasource;
@property (nonatomic, copy) NSString *selectedAccountUUID;

/*
 We retain the delegates since the FDGenericTableViewController is responsible for the delegates
 */
@property (nonatomic, retain) id<FDDatasourceProtocol> datasourceDelegate;
@property (nonatomic, retain) id<FDRowRenderProtocol> rowRenderDelegate;
@property (nonatomic, retain) id<FDTableViewActionsProtocol> actionsDelegate;

// Helper method to initialize a generic table view with a plist
+ (FDGenericTableViewController *)genericTableViewWithPlistPath:(NSString *)plistPath;
@end
