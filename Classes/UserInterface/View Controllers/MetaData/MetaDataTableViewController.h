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
//  MetaDataTableViewController.h
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "IFGenericTableViewController.h"
#import "TaggingHttpRequest.h"
#import "RepositoryItem.h"
#import "DownloadProgressBar.h"
@class FolderItemsHTTPRequest;
@class MBProgressHUD;

@interface MetaDataTableViewController : IFGenericTableViewController <ASIHTTPRequestDelegate, DownloadProgressBarDelegate>
{
    NSString *cmisObjectId;
    NSDictionary *metadata;
	NSDictionary *propertyInfo;
    NSURL *describedByURL;
    NSArray *tagsArray;
    TaggingHttpRequest *taggingRequest;
    RepositoryItem *cmisObject;
    NSString *errorMessage;
    DownloadMetadata *downloadMetadata;
    
    DownloadProgressBar *downloadProgressBar;
    FolderItemsHTTPRequest *versionHistoryRequest;
    BOOL isVersionHistory;
    MBProgressHUD *HUD;
    NSString *selectedAccountUUID;
    NSString *tenantID;
    float longitude;
    float latitude;
    BOOL hasLongitude;
    BOOL hasLatitude;
}
@property BOOL hasLongitude;
@property BOOL hasLatitude;
@property float longitude;
@property float latitude;

@property (nonatomic, retain) NSString *cmisObjectId;
@property (nonatomic, retain) NSDictionary *metadata;
@property (nonatomic, retain) NSDictionary *propertyInfo;
@property (nonatomic, retain) NSURL *describedByURL;
@property (nonatomic, retain) NSArray *tagsArray;
@property (nonatomic, retain) NSURL *cmisThumbnailURL;
@property (nonatomic, retain) TaggingHttpRequest *taggingRequest;
@property (nonatomic, retain) RepositoryItem *cmisObject;
@property (nonatomic, retain) NSString *errorMessage;
@property (nonatomic, retain) DownloadMetadata *downloadMetadata;
@property (nonatomic, retain) DownloadProgressBar *downloadProgressBar;
@property (nonatomic, retain) FolderItemsHTTPRequest *versionHistoryRequest;
@property (nonatomic, assign) BOOL isVersionHistory;
@property (nonatomic, retain) MBProgressHUD *HUD;
@property (nonatomic, retain) NSString *selectedAccountUUID;
@property (nonatomic, retain) NSString *tenantID;

- (id)initWithStyle:(UITableViewStyle)style cmisObject:(RepositoryItem *)cmisObj accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID;
- (void)viewVersionHistoryButtonClicked;
- (void)viewImageLocation;
@end
