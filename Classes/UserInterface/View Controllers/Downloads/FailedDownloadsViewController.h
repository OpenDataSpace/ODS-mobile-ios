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
 *
 * ***** END LICENSE BLOCK ***** */
//
//  FailedDownloadsViewController.h
//

#import <UIKit/UIKit.h>
@class DownloadInfo;

@interface FailedDownloadsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIPopoverControllerDelegate>

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) NSMutableArray *failedDownloads;
@property (nonatomic, retain) UIPopoverController *popover;
@property (nonatomic, retain) DownloadInfo *downloadToDismiss;

@end
