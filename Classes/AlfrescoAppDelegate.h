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
//  AlfrescoAppDelegate.h
//

//#import "Reachability.h"
#import "RootViewController.h"
#import "AboutViewController.h"
#import "MGSplitViewController.h"


@class IpadSupport;

//
// TODO: Load Late and lazily
// TODO: Rename this class
//

@interface AlfrescoAppDelegate : NSObject <UIApplicationDelegate, UIDocumentInteractionControllerDelegate, UIAlertViewDelegate> {
    
    NSArray *screenModes;

    UIWindow               *window;
	UINavigationController *navigationController;
	UITabBarController     *tabBarController;
	RootViewController     *sitesController;
    AboutViewController    *aboutViewController;
	UIDocumentInteractionController *docInteractionController;
	UITabBarItem *aboutTabBarItem;
    UINavigationController *activitiesNavController;
    ServiceDocumentRequest *serviceDocumentRequest;
    MBProgressHUD *HUD;
    NSString *userPrefHash;
    
@private
    IpadSupport *tabBarDelegate;
    MGSplitViewController *split;
    BOOL isIPad2Device;
    BOOL shouldPostReloadNotification;
    
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;
@property (nonatomic, retain) IBOutlet RootViewController *sitesController;
@property (nonatomic, retain) IBOutlet AboutViewController *aboutViewController;
@property (nonatomic, retain) UIDocumentInteractionController *docInterationController;
@property (nonatomic, retain) IBOutlet UITabBarItem *aboutTabBarItem;
@property (nonatomic, retain) IBOutlet UINavigationController *activitiesNavController;
@property (nonatomic, retain) ServiceDocumentRequest *serviceDocumentRequest;
@property (nonatomic, retain) MBProgressHUD *HUD;
@property (nonatomic, copy) NSString *userPrefHash;

void uncaughtExceptionHandler(NSException *exception);
- (BOOL)usingFlurryAnalytics;
- (void)resetUserPreferencesToDefault;

@end

