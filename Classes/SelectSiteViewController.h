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
//  SelectSiteViewController.h
//

#import "IFGenericTableViewController.h"
#import "SitesManagerService.h"
#import "MultiAccountBrowseManager.h"
@class SelectSiteViewController;
@class RepositoryItem;
@class MBProgressHUD;
@class TableViewNode;

@protocol SelectSiteDelegate <NSObject>

-(void)selectSite:(SelectSiteViewController *)selectSite finishedWithItem:(TableViewNode *)item;
-(void)selectSiteDidCancel:(SelectSiteViewController *)selectSite;

@end

@interface SelectSiteViewController : UITableViewController <MultiAccountBrowseListener> {
    TableViewNode *selectedNode;
    TableViewNode *expandingNode;
    NSMutableArray *allItems;
    id<SelectSiteDelegate> delegate;
    MBProgressHUD *HUD;
    NSString *selectedAccountUUID;
    BOOL cancelled;
}

@property (nonatomic, retain) TableViewNode *selectedNode;
@property (nonatomic, retain) TableViewNode *expandingNode;
@property (nonatomic, retain) NSMutableArray *allItems;
@property (nonatomic, assign) id<SelectSiteDelegate> delegate;

@property (nonatomic, readwrite, retain) MBProgressHUD *HUD;
@property (nonatomic, copy) NSString *selectedAccountUUID;

+(SelectSiteViewController *)selectSiteViewController;

@end
