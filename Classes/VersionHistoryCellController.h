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
 * Portions created by the Initial Developer are Copyright (C) 2011
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  VersionHistoryCellController.h
//

#import "IFMultilineCellController.h"
@class RepositoryItem;

typedef enum {
	VersionHistoryAccessoryTapped = 0,
    VersionHistoryRowSelection = 1
} VersionHistorySelectionType;

@interface VersionHistoryCellController : IFMultilineCellController {
    RepositoryItem *repositoryItem;
    VersionHistorySelectionType selectionType;
    
    UITableViewCellAccessoryType accesoryType;
    UITableViewCellSelectionStyle selectionStyle;
    UIView *accessoryView;
    NSInteger tag;
}

@property (nonatomic, retain) RepositoryItem *repositoryItem;
@property (nonatomic, assign) VersionHistorySelectionType selectionType;
@property (nonatomic, assign) UITableViewCellAccessoryType accesoryType;
@property (nonatomic, assign) UITableViewCellSelectionStyle selectionStyle;
@property (nonatomic, retain) UIView *accessoryView;
@property (nonatomic, assign) NSInteger tag;

-(id)initWithTitle:(NSString *)newTitle subtitle:(NSString *)newSubtitle;

@end



