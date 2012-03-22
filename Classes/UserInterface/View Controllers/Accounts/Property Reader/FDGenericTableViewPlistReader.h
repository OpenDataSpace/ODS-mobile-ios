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
//  FDGenericTableViewPlistReader.h
//
// Plist reader of the configuration of a FDGenericTableViewController
// It can create default instances of objects out of a name class in the configurations
// and provides other helper methods to retrieve the configuration, such as creating UIBarButtonItems

#import <Foundation/Foundation.h>
#import "FDGenericTableViewController.h"

@interface FDGenericTableViewPlistReader : NSObject
// The plist is stored in this in-memory dictionary
@property (nonatomic, retain) NSDictionary *plistDictionary;
// The title as specified in the "FDControllerTitle" key
@property (nonatomic, readonly) NSString *title;
/*  The right bar button configured as specified in the "FDRightBarButton" dictionary
    Dictionary schema:
    Key: "FDBarButtonType" - Specifies the kind of UIBarButtonItem like "System", "Title", "Image". 
                        Currently only "System" type is supported
    Key: "FDBarButtonSystemItem" - Specifies the kind of System Button Item that we should create, based in the UIBarButtonSystemItem enumeration
            Currently only "Add" (UIBarButtonSystemItemAdd) is supported
    There has to be a rowRenderDelegate configured that is able handle the rightButtonActionWithDatasource: selector so the right bar button is visible, otherwise the right bar button will not be visible in the navigation bar
    A new object is created per each call to the method.
*/
@property (nonatomic, readonly) UIBarButtonItem *rightBarButton;

/*
 The Editing style for the TableView specified in the "FDTableViewEditingStyle" key
 The permitted values are: "None", "Insert", "Delete"
 */
@property (nonatomic, readonly) UITableViewCellEditingStyle editingStyle;
/*
 The Row Height for the TableView controller in the "FDRowHeight" key
 The value should be a decimal number larger than 0
 */
@property (nonatomic, readonly) CGFloat rowHeight;
/*
    The delegate object that will handle the datasource part of the FDGenericTableViewController. The class name should be specified in the "FDDatasourceDelegate" key.
    A new object is created per each call to the method.
 */
@property (nonatomic, readonly) id<FDDatasourceProtocol> datasourceDelegate;
/*
 The delegate object that will handle the Row Rendering part of the FDGenericTableViewController. The class name should be specified in the "FDRowRenderDelegate" key.
 A new object is created per each call to the method.
 */
@property (nonatomic, readonly) id<FDRowRenderProtocol> rowRenderDelegate;
/*
 The delegate object that will handle the actions the FDGenericTableViewController for example the user tapping
 the right button item. The class name should be specified in the "FDActionsDelegate" key.
 It has to implement the rightButtonActionWithDatasource: and in conjunction with the rightBarButton configuration the button is shown
 A new object is created per each call to the method.
 */
@property (nonatomic, readonly) id<FDTableViewActionsProtocol> actionsDelegate;

- (id)initWithPlistPath:(NSString *)plistPath;
@end
