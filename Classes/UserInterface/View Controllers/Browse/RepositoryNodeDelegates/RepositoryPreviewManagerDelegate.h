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
//  RepositoryPreviewManagerDelegate.h
//
// Delegate for the previewManager when browsing a repository
// It is reposible of updating the UITableViewCells to reflect the current progress of a document preview load,
// pushing the actual preview of a document into a navigation stack or into the detail view in the iPad
// It will also handle cancelled or failed downloads gracefully.

#import <Foundation/Foundation.h>
#import "PreviewManager.h"

@interface RepositoryPreviewManagerDelegate : NSObject <PreviewManagerDelegate>

@property (nonatomic, retain) NSMutableArray *repositoryItems;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (nonatomic, copy) NSString *selectedAccountUUID;
@property (nonatomic, copy) NSString *tenantID;


- (NSIndexPath *)indexPathForNodeWithGuid:(NSString *)itemGuid;
@end
