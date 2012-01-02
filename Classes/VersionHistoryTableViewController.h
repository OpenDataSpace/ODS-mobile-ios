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
//  VersionHistoryTableViewController.h
//

#import "IFGenericTableViewController.h"
#import "ASIHTTPRequest.h"
#import "DownloadProgressBar.h"

@class MBProgressHUD;
@class CMISTypeDefinitionHTTPRequest;

@interface VersionHistoryTableViewController : IFGenericTableViewController  <DownloadProgressBarDelegate, ASIHTTPRequestDelegate> {
    NSArray *versionHistory;
    CMISTypeDefinitionHTTPRequest *metadataRequest;
    MBProgressHUD *HUD;
    
    DownloadProgressBar *downloadProgressBar;
    RepositoryItem *latestVersion;
    NSString *selectedAccountUUID;
    NSString *tenantID;
}
@property (nonatomic, retain) NSArray *versionHistory;
@property (nonatomic, retain) CMISTypeDefinitionHTTPRequest *metadataRequest;
@property (nonatomic, retain) MBProgressHUD *HUD;
@property (nonatomic, retain) DownloadProgressBar *downloadProgressBar;
@property (nonatomic, retain) RepositoryItem *latestVersion;
@property (nonatomic, retain) NSString *selectedAccountUUID;
@property (nonatomic, retain) NSString *tenantID;

- (id)initWithStyle:(UITableViewStyle)style versionHistory:(NSArray *)initialVersionHistory accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID;

@end
