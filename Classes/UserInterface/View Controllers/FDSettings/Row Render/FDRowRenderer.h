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
//  FDRowRenderer.h
//
// Helper class, it is initialized with a settings array.
// It will generate the headers and groups needed to ccofigure a IFGenericTableViewController

#import <Foundation/Foundation.h>
@class FDSettingsPlistReader;
@protocol IFCellModel;

@interface FDRowRenderer : NSObject
{
    NSArray *_settings;
    NSString *_stringsTable;
}

// Used to store all the header strings generated from the settings array
@property (nonatomic, retain) NSMutableArray *headers;
// To store all the settings groups generated from the settings array
@property (nonatomic, retain) NSMutableArray *groups;

@property (nonatomic, retain) id<IFCellModel> model;

@property (nonatomic, assign) Class readOnlyCellClass;
@property (nonatomic, assign) BOOL readOnly;

/*
 Initialized a FDRowRenderer with an array of settings (NSDictionary), the model used will be the
 FDKeychainModel
 */
- (id)initWithSettings:(FDSettingsPlistReader *)settingsReader;
/*
 Initialized a FDRowRenderer with an array of settings, a stringsTable where we will look for the localized titles
 and a model
 */
- (id)initWithSettings:(NSArray *)settings stringsTable:(NSString *)stringsTable andModel:(id<IFCellModel>)model;

/*
 Clears the results. will be regenerated on the next call to headers or groups
 */
- (void)clearResults;
@end
