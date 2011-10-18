//
//  AlfrescoAppDelegate.h
//  Alfresco
//
//  Created by Michael Muller on 9/1/09.
//  Copyright Zia Consulting 2009. All rights reserved.
//

#import "RootViewController.h"
#import "AboutViewController.h"
#import "ExternalDisplayViewController.h"

@interface AlfrescoAppDelegate : NSObject <UIApplicationDelegate, UIDocumentInteractionControllerDelegate, UIAlertViewDelegate> {
    
    NSArray *screenModes;
    UIScreen *externalScreen;
    ExternalDisplayViewController *externalVC;

    UIWindow               *window;
    UIWindow               *externalWindow;
	UINavigationController *navigationController;
	UITabBarController     *tabBarController;
	RootViewController     *sitesController;
    AboutViewController    *aboutViewController;
	UIDocumentInteractionController *docInteractionController;
	UITabBarItem *aboutTabBarItem;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UIWindow *externalWindow;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;
@property (nonatomic, retain) IBOutlet RootViewController *sitesController;
@property (nonatomic, retain) IBOutlet AboutViewController *aboutViewController;
@property (nonatomic, retain) UIDocumentInteractionController *docInterationController;
@property (nonatomic, retain) IBOutlet UITabBarItem *aboutTabBarItem;

@property (nonatomic, retain) NSTimer *repeatingTimer;

void uncaughtExceptionHandler(NSException *exception);
- (BOOL)usingFlurryAnalytics;
- (void)resetUserPreferencesToDefault;
- (void) takeCapture:(NSTimer*)theTimer;

@end

