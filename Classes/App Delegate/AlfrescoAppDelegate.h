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
#import "NSURL+HTTPURLUtils.h"
#import "Utility.h"

@class IpadSupport;

//
// TODO: Load Late and lazily
// TODO: Rename this class
//

@interface AlfrescoAppDelegate : NSObject <
    UIAlertViewDelegate,
    UIApplicationDelegate,
    UIDocumentInteractionControllerDelegate>
{
    
    NSArray *screenModes;

	UITabBarController     *tabBarController;
	RootViewController     *sitesController;
	UIDocumentInteractionController *docInteractionController;
    UINavigationController *activitiesNavController;
    UINavigationController *tasksNavController;
    UINavigationController *moreNavController;
    UINavigationController *documentsNavController;
    
@private
    IpadSupport *tabBarDelegate;
    NSString *userPreferencesHash;
    UIViewController *mainViewController;
    UISplitViewController *splitViewController;
    BOOL showedSplash;
    BOOL flurrySessionStarted;
    BOOL isFirstLaunch;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;
@property (nonatomic, retain) IBOutlet RootViewController *sitesController;
@property (nonatomic, retain) UIDocumentInteractionController *docInterationController;
@property (nonatomic, retain) IBOutlet UINavigationController *activitiesNavController;
@property (nonatomic, retain) IBOutlet UINavigationController *tasksNavController;
@property (nonatomic, retain) IBOutlet UINavigationController *moreNavController;
@property (nonatomic, retain) IBOutlet UINavigationController *documentsNavController;
@property (nonatomic, retain) IBOutlet UINavigationController *favoritesNavController;
@property (nonatomic, retain) UISplitViewController *splitViewController;
@property (nonatomic, retain) NSString *userPreferencesHash;
@property (nonatomic, retain) UIViewController *mainViewController;
@property (nonatomic, assign) BOOL showedSplash;
@property (nonatomic, assign) BOOL suppressHomeScreen;
@property (nonatomic, copy) void (^openURLBlock)();

void uncaughtExceptionHandler(NSException *exception);
- (BOOL)usingFlurryAnalytics;
- (void)resetUserPreferencesToDefault;
- (BOOL)shouldPresentHomeScreen;
- (void)presentHomeScreenController;
- (void)forcePresentHomeScreenController;
- (void)dismissModalViewController;
- (BOOL)shouldPresentSplashScreen;
- (void)presentSplashScreenController;
- (void)presentModalViewController:(UIViewController *)viewController animated:(BOOL)animated;

@end

