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
//  AlfrescoAppDelegate.h
//

//#import "Reachability.h"
#import "RootViewController.h"
#import "AboutViewController.h"
#import "MGSplitViewController.h"
#import "NSURL+HTTPURLUtils.h"
#import "Utility.h"
#import "PostProgressBar.h"

@class IpadSupport;

//
// TODO: Load Late and lazily
// TODO: Rename this class
//

@interface AlfrescoAppDelegate : NSObject <UIApplicationDelegate, UIDocumentInteractionControllerDelegate, UIAlertViewDelegate, UIAlertViewDelegate, PostProgressBarDelegate> {
    
    NSArray *screenModes;

    UIWindow               *window;
	UINavigationController *navigationController;
	UITabBarController     *tabBarController;
	RootViewController     *sitesController;
    AboutViewController    *aboutViewController;
	UIDocumentInteractionController *docInteractionController;
	UITabBarItem *aboutTabBarItem;
    UINavigationController *activitiesNavController;
    UINavigationController *moreNavController;
    PostProgressBar *postProgressBar;

    
@private
    IpadSupport *tabBarDelegate;
    MGSplitViewController *split;
    BOOL isIPad2Device;
    BOOL shouldPostReloadNotification;
    NSString *updatedFileName;
    NSString *userPreferencesHash;
    UIViewController *mainViewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;
@property (nonatomic, retain) IBOutlet RootViewController *sitesController;
@property (nonatomic, retain) IBOutlet AboutViewController *aboutViewController;
@property (nonatomic, retain) UIDocumentInteractionController *docInterationController;
@property (nonatomic, retain) IBOutlet UITabBarItem *aboutTabBarItem;
@property (nonatomic, retain) IBOutlet UINavigationController *activitiesNavController;
@property (nonatomic, retain) IBOutlet UINavigationController *moreNavController;
@property (nonatomic, retain) PostProgressBar *postProgressBar;
@property (nonatomic, retain) NSString *userPreferencesHash;
@property (nonatomic, retain) UIViewController *mainViewController;

void uncaughtExceptionHandler(NSException *exception);
- (BOOL)usingFlurryAnalytics;
- (void)resetUserPreferencesToDefault;
- (id)defaultPreferenceForKey:(NSString *)key;

@end

