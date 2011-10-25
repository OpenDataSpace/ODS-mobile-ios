//
//  ***** BEGIN LICENSE BLOCK *****
//  Version: MPL 1.1
//
//  The contents of this file are subject to the Mozilla Public License Version
//  1.1 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS" basis,
//  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
//  for the specific language governing rights and limitations under the
//  License.
//
//  The Original Code is the Alfresco Mobile App.
//  The Initial Developer of the Original Code is Zia Consulting, Inc.
//  Portions created by the Initial Developer are Copyright (C) 2011
//  the Initial Developer. All Rights Reserved.
//
//
//  ***** END LICENSE BLOCK *****
//
//
//  AlfrescoAppDelegate.m
//  

#import "AlfrescoAppDelegate.h"
#import "RootViewController.h"
#import "Theme.h"
#import "FixedBackgroundWithRotatingLogoView.h"
#import "DocumentViewController.h"
#import "SavedDocument.h"
#import "MBProgressHUD.h"
#import "FlurryAnalytics.h"
#import <QuartzCore/QuartzCore.h>

#define IS_IPAD ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

@interface AlfrescoAppDelegate (private)
- (NSString *)applicationDocumentsDirectory;
- (void)registerDefaultsFromSettingsBundle;
- (NSArray *) userPreferences;
@end

@implementation AlfrescoAppDelegate
@synthesize window;
@synthesize externalWindow;
@synthesize navigationController;
@synthesize tabBarController;
@synthesize sitesController;
@synthesize aboutViewController;
@synthesize docInterationController;
@synthesize aboutTabBarItem;
@synthesize repeatingTimer;

#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	[navigationController release];
	[tabBarController release];
	[window release];
    [externalWindow release];
	[sitesController release];
    [aboutViewController release];
	[docInterationController release];
	[aboutTabBarItem release];
	[repeatingTimer release];

    [externalVC release];
	[super dealloc];
}


- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    // Free up as much memory as possible by purging cached data objects that can be recreated
    // (or reloaded from disk) later.
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

#pragma mark -
#pragma mark Fatal error processing
void uncaughtExceptionHandler(NSException *exception) {
    [FlurryAnalytics logError:@"Uncaught Exception" message:@"Crash!" exception:exception];
}

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
	[self registerDefaultsFromSettingsBundle];
    
    NSString *flurryKey = NSLocalizedString(@"Flurry API Key", @"Key for Flurry API");
#ifdef OVERRIDE_FLURRY_KEY
    flurryKey = OVERRIDE_FLURRY_KEY;
#endif
    if (nil != flurryKey && [flurryKey length] > 0) {
        NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
        [FlurryAnalytics startSession:flurryKey];
    }

    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:YES];
	
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	[Theme setThemeForUINavigationBar:[navigationController navigationBar]];
	
    BOOL skipBackgroundView = NO;
#if defined (TARGET_ALFRESCO)
    skipBackgroundView = YES;
#endif
    
    
	UIView *bgView = nil;
    if ( !skipBackgroundView ) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
        if (IS_IPAD) {
            bgView = [[FixedBackgroundWithRotatingLogoView alloc] initWithBackgroundImage:[UIImage imageNamed:@"background-iPad.png"]
                                                                        rotatingLogoImage:[UIImage imageNamed:@"watermark-iPad.png"]];
        }
#endif
        
        if (bgView == nil) {
            bgView = [[[FixedBackgroundWithRotatingLogoView alloc] initWithBackgroundColor:[UIColor whiteColor]
                                                                         rotatingLogoImage:[UIImage imageNamed:@"watermark-iPhone.png"]] autorelease];
        }
        [window addSubview:bgView];
    }
    
	[aboutTabBarItem setImage:[UIImage imageNamed:@"tabAboutLogo.png"]];
	[window addSubview:[tabBarController view]];
    [window makeKeyAndVisible];
    
	NSURL *url = (NSURL *)[launchOptions valueForKey:UIApplicationLaunchOptionsURLKey];
	if ([url isFileURL] && [[[UIDevice currentDevice] systemVersion] hasPrefix:@"3.2"]) {
		[[self tabBarController] setSelectedIndex:2];
		[self application:[UIApplication sharedApplication] handleOpenURL:url];
	}
    
	externalWindow.hidden = YES;
    
    if ([[UIScreen screens] count] > 1) {
        NSLog(@"Found an external screen.");
        
        // Internal display is 0, external is 1.
        externalScreen = [[[UIScreen screens] objectAtIndex:1] retain];
        NSLog(@"External screen: %@", externalScreen);
        
        screenModes = [externalScreen.availableModes retain];
        NSLog(@"Available modes: %@", screenModes);
        
        // Allow user to choose from available screen-modes (pixel-sizes).
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"External Display Size", @"External Display Size (title)") 
                                                         message:NSLocalizedString(@"Choose a size for the external display.", @"Choose a size for the external display. (message)")
                                                        delegate:self 
                                               cancelButtonTitle:nil 
                                               otherButtonTitles:nil] autorelease];
        for (UIScreenMode *mode in screenModes) {
            CGSize modeScreenSize = mode.size;
            [alert addButtonWithTitle:[NSString stringWithFormat:[NSString stringWithFormat:@"%@ %@", @"%.0f x %.0f", NSLocalizedString(@"pixels", @"pixels")], 
                                       modeScreenSize.width, modeScreenSize.height]];
        }
        
        [alert show];
    }
    
    
    // Reset Settings if toggled
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"resetToDefault"]) 
    {
        NSLog(@"Reset Detected");
        [self resetUserPreferencesToDefault];
    }
    
	// tell the application framework that we'll accept whatever file type is being passed to us
	return YES;
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}

#pragma mark -
#pragma mark App Delegate - Document Support

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
	// TODO: lets be robust, make sure a file exists at the URL
	
	NSString *incomingFilePath = [url path];
	NSString *incomingFileName = [[incomingFilePath pathComponents] lastObject];
	NSString *saveToPath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:incomingFileName];
	NSURL *saveToURL = [NSURL fileURLWithPath:saveToPath];

	NSFileManager *fileManager = [NSFileManager defaultManager];
	BOOL fileExistsInFavorites = [fileManager fileExistsAtPath:saveToPath];
	if (fileExistsInFavorites) {
		[fileManager removeItemAtURL:saveToURL error:NULL];
		NSLog(@"Removed File '%@' From Favorites Folder", incomingFileName);
	}

	BOOL incomingFileMovedSuccessfully = [fileManager moveItemAtPath:[url path] toPath:[saveToURL path] error:NULL];
	if (incomingFileMovedSuccessfully) {
		url = saveToURL;
	}
	
	NSString *nibName = @"DocumentViewController";
	DocumentViewController *viewController = [[[DocumentViewController alloc] 
											   initWithNibName:nibName bundle:[NSBundle mainBundle]] autorelease];
	[viewController setFileName:incomingFileName];
	[viewController setFileData:[NSData dataWithContentsOfFile:[SavedDocument pathToSavedFile:incomingFileName]]];
	[viewController setHidesBottomBarWhenPushed:YES];
	
	[[self tabBarController] setSelectedIndex:2]; // TODO: parameterize -- selected Favorites tab
	
	UINavigationController *favoritesNavController = (UINavigationController *)[[self tabBarController] selectedViewController];
	[favoritesNavController popToRootViewControllerAnimated:NO];
	[favoritesNavController pushViewController:viewController animated:YES];

	return NO;
}

#pragma mark -
#pragma mark UIDocumentInteractionControllerDelegate Methods
#pragma mark -
#pragma mark Private methods

- (NSString *)applicationDocumentsDirectory
{
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (BOOL)usingFlurryAnalytics
{
    NSString *flurryKey = NSLocalizedString(@"Flurry API Key", @"Key for Flurry API");
#ifdef OVERRIDE_FLURRY_KEY
    flurryKey = OVERRIDE_FLURRY_KEY;
#endif
    return (nil != flurryKey && [flurryKey length] > 0);
}

// this works around the fact the settings return nil rather than the default if the user has never opened the preferences
// thank you "PCheese": http://stackoverflow.com/questions/510216/can-you-make-the-settings-in-settings-bundle-default-even-if-you-dont-open-the-s
- (void)registerDefaultsFromSettingsBundle {
    NSArray *preferences = [self userPreferences];
	
    NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
    for (NSDictionary *prefSpecification in preferences) {
        NSString *key = [prefSpecification objectForKey:@"Key"];
        if (key) {
            [defaultsToRegister setObject:[prefSpecification objectForKey:@"DefaultValue"] forKey:key];
        }
    }
	
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsToRegister];
	[[NSUserDefaults standardUserDefaults] synchronize];
    [defaultsToRegister release];
}

- (void)resetUserPreferencesToDefault
{
    NSLog(@"Resetting User Preferences to default");
    NSArray *preferences = [self userPreferences];
	
    for (NSDictionary *prefSpecification in preferences) {
        NSString *key = [prefSpecification objectForKey:@"Key"];
        if (key) {
            [[NSUserDefaults standardUserDefaults] setValue:[prefSpecification objectForKey:@"DefaultValue"] forKey:key];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray *) userPreferences {
    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
    if(!settingsBundle) {
        NSLog(@"Could not find Settings.bundle");
        return [NSArray array];
    }
	
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];
    return [settings objectForKey:@"PreferenceSpecifiers"];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    UIScreenMode *desiredMode = [screenModes objectAtIndex:buttonIndex];
    externalScreen.currentMode = desiredMode;
    externalWindow.screen = externalScreen;
    
    [screenModes release];
    [externalScreen release];
    
    CGRect rect = CGRectZero;
    rect.size = desiredMode.size;
    externalWindow.frame = rect;
    externalWindow.clipsToBounds = YES;
    
    externalWindow.hidden = NO;
    [externalWindow makeKeyAndVisible];
    
    externalVC = [[ExternalDisplayViewController alloc] initWithNibName:@"ExternalDisplayViewController" bundle:nil];
    CGRect frame = [externalScreen applicationFrame];
    switch(externalVC.interfaceOrientation) {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
            [externalVC.view setFrame:frame];
            break;
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            [externalVC.view setFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.height, frame.size.width)];
            break;
    }
    
    [externalWindow addSubview:externalVC.view];
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.25
                                                    target:self selector:@selector(takeCapture:)
                                                    userInfo:nil repeats:YES];
    self.repeatingTimer = timer;
}

- (void) takeCapture:(NSTimer*)theTimer{
    UIView *mainView = [window.subviews objectAtIndex:0];
    
    if (mainView) {
        // Create a graphics context with the target size
        // On iOS 4 and later, use UIGraphicsBeginImageContextWithOptions to take the scale into consideration
        // On iOS prior to 4, fall back to use UIGraphicsBeginImageContext
        CGSize imageSize = [[UIScreen mainScreen] bounds].size;
        if (NULL != UIGraphicsBeginImageContextWithOptions) {
            UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
        } else {
            UIGraphicsBeginImageContext(imageSize);
        }
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        // Iterate over every window from back to front
        for (UIWindow *win in [[UIApplication sharedApplication] windows]) 
        {
            if (![win respondsToSelector:@selector(screen)] || [win screen] == [UIScreen mainScreen])
            {
                // -renderInContext: renders in the coordinate space of the layer,
                // so we must first apply the layer's geometry to the graphics context
                CGContextSaveGState(context);
                // Center the context around the window's anchor point
                CGContextTranslateCTM(context, [win center].x, [win center].y);
                // Apply the window's transform about the anchor point
                CGContextConcatCTM(context, [win transform]);
                // Offset by the portion of the bounds left of and above the anchor point
                CGContextTranslateCTM(context,
                                      -[win bounds].size.width * [[win layer] anchorPoint].x,
                                      -[win bounds].size.height * [[win layer] anchorPoint].y);
                
                // Render the layer hierarchy to the current context
                [[win layer] renderInContext:context];
                
                // Restore the context
                CGContextRestoreGState(context);
            }
        }
        
        // Retrieve the screenshot image
        UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();

        [externalVC.imageView setImage:viewImage];        
    }
}


@end

