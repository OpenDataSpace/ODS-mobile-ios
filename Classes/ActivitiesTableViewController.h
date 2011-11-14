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
//  ActivitiesTableViewController.h
//

#import "IFGenericTableViewController.h"
#import "ASIHTTPRequest.h"
#import "MBProgressHUD.h"
#import "DownloadProgressBar.h"
#import "AsynchonousDownload.h"

@class ServiceDocumentRequest;
@class ActivitiesHttpRequest;
@class ObjectByIdRequest;
@class CMISTypeDefinitionDownload;

@interface ActivitiesTableViewController : IFGenericTableViewController <ASIHTTPRequestDelegate, MBProgressHUDDelegate, DownloadProgressBarDelegate, AsynchronousDownloadDelegate> {
    @private
    MBProgressHUD *HUD;
    ActivitiesHttpRequest *activitiesRequest;
    ServiceDocumentRequest *serviceDocumentRequest;
    ObjectByIdRequest *objectByIdRequest;
    
    CMISTypeDefinitionDownload *metadataRequest;
    DownloadProgressBar *downloadProgressBar;
}

@property (nonatomic, retain) MBProgressHUD *HUD;
@property (nonatomic, retain) ActivitiesHttpRequest *activitiesRequest;
@property (nonatomic, retain) ServiceDocumentRequest *serviceDocumentRequest;
@property (nonatomic, retain) ObjectByIdRequest *objectByIdRequest;
@property (nonatomic, retain) CMISTypeDefinitionDownload *metadataRequest;
@property (nonatomic, retain) DownloadProgressBar *downloadProgressBar;

@end
