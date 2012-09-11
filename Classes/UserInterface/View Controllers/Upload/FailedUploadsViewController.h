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
//  FailedUploadsViewController.h
//
// Displays a list of provided failed uploads. 
// It displays the name of the file, the folder where it was uploading and the error description
// It also provides a Clear and Dismiss button, both buttons dismiss the controller (presented as a modalViewController)
// but the Clear button will clear the failed uploads from the Upload Manager, clearing the badge, ghost cells and upload failed panel
// in the case that no other upload failed after this controller has been initialized

#import <UIKit/UIKit.h>

typedef enum
{
    UploadsAndDownloads,
    OnlyUploads,
    OnlyDownloads,
    
} ViewType;

@interface FailedUploadsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) NSArray *failedUploadsAndDownloads;
@property (nonatomic, retain) UIButton *clearButton;
@property (nonatomic, assign) ViewType viewType;
/*
 Initializes the controller with an array of failed uploads
 */
- (id)initWithFailedUploads:(NSArray *)failedUploadsAndDownloads;

@end
