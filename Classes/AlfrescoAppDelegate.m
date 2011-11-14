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
//  AlfrescoAppDelegate.m
//

#import <QuartzCore/QuartzCore.h>

#import "AlfrescoAppDelegate.h"
#import "RootViewController.h"
#import "Theme.h"
#import "FixedBackgroundWithRotatingLogoView.h"
#import "DocumentViewController.h"
#import "SavedDocument.h"
#import "MBProgressHUD.h"
#import "ThemeProperties.h"
#import "DetailNavigationController.h"
#import "IpadSupport.h"
#import "PlaceholderViewController.h"
#import "FlurryAnalytics.h"
#import "TVOutManager.h"
#import "FileDownloadManager.h"
#import "DownloadMetadata.h"
#import "UIDeviceHardware.h"
#import "ASIHTTPRequest+Utils.h"
#import "ASIDownloadCache.h"
#import "Constants.h"
#import "Utility.h"
#import "NSString+MD5.h"
#import "AppProperties.h"
#import "SitesManagerService.h"

#define IS_IPAD ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

@interface AlfrescoAppDelegate (private)
- (NSString *)applicationDocumentsDirectory;
- (void)registerDefaultsFromSettingsBundle;
- (void)sendDidRecieveMemoryWarning:(UIViewController *) controller;
- (NSArray *)userPreferences;
- (void)rearrangeTabs;

- (void)startHUD;
- (void)stopHUD;
- (void)startServiceDocumentRequest;
- (void)detectReset;
- (NSString *)hashForConnectionUserPref;
@end

@implementation AlfrescoAppDelegate
@synthesize window;
@synthesize navigationController;
@synthesize tabBarController;
@synthesize sitesController;
@synthesize aboutViewController;
@synthesize docInterationController;
@synthesize aboutTabBarItem;
@synthesize activitiesNavController;
@synthesize serviceDocumentRequest;
@synthesize HUD;
@synthesize userPrefHash;

#pragma mark -
#pragma mark Memory management

- (void)dealloc {
    [window release];
	[navigationController release];
	[tabBarController release];
	[sitesController release];
    [aboutViewController release];
	[docInterationController release];
	[aboutTabBarItem release];
    [activitiesNavController release];
    [serviceDocumentRequest release];
    [HUD release];
    [userPrefHash release];
    
    [tabBarDelegate release];
    [split release];

	[super dealloc];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    NSLog(@"applicationWillEnterForeground");
    // Usually we want to recreate everything that was freed from memory on the
    // applicationWillResignActive: or applicationDidEnterBackground: but we only
    // release objects that could be recreated lazy (viewDidLoad)
    
    // we reload the userDefault in case the user changed something
    if(![[NSUserDefaults standardUserDefaults] synchronize]) {
        NSLog(@"There was an error saving/updating the userDefaults");
    }
    
    [self detectReset];
    if([userPrefHash isEqualToString:[self hashForConnectionUserPref]]) {
        //Preferences were not modified when the app was in the background
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];
    }
    [ASIHTTPRequest setDefaultCacheIfEnabled];
    [self rearrangeTabs];

    if ( !isIPad2Device )
        [[TVOutManager sharedInstance] startTVOut];
}

- (void) applicationDidEnterBackground:(UIApplication *)application {
    // Simulate a memory warning in our view controllers so they are responsible
    // to free up the memory
    [self sendDidRecieveMemoryWarning:tabBarController];
    
    if(split) {
        [self sendDidRecieveMemoryWarning:split];
    }
    
    self.userPrefHash = [self hashForConnectionUserPref];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
}

- (void) sendDidRecieveMemoryWarning:(UIViewController *) controller {
    [controller didReceiveMemoryWarning];
    
    if([controller respondsToSelector:@selector(viewControllers)]) {
        for(UIViewController *subController in [controller performSelector:@selector(viewControllers)]) {
            [self sendDidRecieveMemoryWarning:subController];
        }
    }
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    // Free up as much memory as possible by purging cached data objects that can be recreated
    // (or reloaded from disk) later.
    
}

/* Since iOS 4 this is rarely called */
- (void)applicationWillTerminate:(UIApplication *)application {
    NSLog(@"applicationWillTerminate");
    //We will try to clean the session download cache
    //Since we cannot rely on this method walways getting called
    //there's no guarantee it gets cleared until the user starts the app again
    //which it gets clearead automatically by ASIHTTPRequest
    [[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    if ( !isIPad2Device )
        [[TVOutManager sharedInstance] stopTVOut];
    
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];

    //ViewControllers should listen to this notification so it can cancel active
    //network operations
    
}

#pragma mark -
#pragma mark Fatal error processing
void uncaughtExceptionHandler(NSException *exception) {
    [FlurryAnalytics logError:@"Uncaught Exception" message:@"Crash!" exception:exception];
}


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    UIDeviceHardware *device = [[UIDeviceHardware alloc] init];
    isIPad2Device = [[device platform] hasPrefix:@"iPad2"];
    
    [device release];
    
	[self registerDefaultsFromSettingsBundle];
    self.userPrefHash = [self hashForConnectionUserPref];
    
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
	
    BOOL skipBackgroundView = [ThemeProperties skipBackgroundView];
    
	UIView *bgView = nil;
    if ( !skipBackgroundView ) {
        bgView = [ThemeProperties backgroundLogoView];
        [window addSubview:bgView];
    }
    
	[aboutTabBarItem setImage:[UIImage imageNamed:@"tabAboutLogo.png"]];
    
    if(IS_IPAD) {        
        PlaceholderViewController *viewController = [[[PlaceholderViewController alloc] init] autorelease];
        DetailNavigationController *detail = [[[DetailNavigationController alloc]initWithRootViewController:viewController] autorelease]; // a detail view will come here
        UINavigationController *nav = [[[UINavigationController alloc] initWithRootViewController:tabBarController] autorelease];
        nav.navigationBarHidden = YES;
        
        [Theme setThemeForUINavigationController:detail];
        split = [[MGSplitViewController alloc] init];
        split.delegate = detail;
        split.viewControllers = [NSArray arrayWithObjects: nav,detail, nil];
        [IpadSupport registerGlobalDetail:detail];
        //tabBarController.delegate = tabBarDelegate;        
        [window addSubview:[split view]];
    } else {
        [window addSubview:[tabBarController view]];
    }
    
    int defaultTabIndex = [[AppProperties propertyForKey:kDefaultTabbarSelection] intValue];
    [tabBarController setSelectedIndex:defaultTabIndex];
    
    [self rearrangeTabs];
    
    [window makeKeyAndVisible];
    
	NSURL *url = (NSURL *)[launchOptions valueForKey:UIApplicationLaunchOptionsURLKey];
	if ([url isFileURL] && [[[UIDevice currentDevice] systemVersion] hasPrefix:@"3.2"]) {
		[[self tabBarController] setSelectedIndex:2];
		[self application:[UIApplication sharedApplication] handleOpenURL:url];
	}
    
    if ( !isIPad2Device )
        [[TVOutManager sharedInstance] startTVOut];
    
    [self detectReset];
    [ASIHTTPRequest setDefaultCacheIfEnabled];
//    [self startServiceDocumentRequest];
	// tell the application framework that we'll accept whatever file type is being passed to us
	return YES;
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"applicationDidBecomeActive");
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
    
    if([fileManager fileExistsAtPath:[SavedDocument pathToTempFile:incomingFileName]]) {
        NSURL *tempURL = [NSURL fileURLWithPath:[SavedDocument pathToTempFile:incomingFileName]];
        [fileManager removeItemAtURL:tempURL error:NULL];
    }

//	BOOL incomingFileMovedSuccessfully = [fileManager moveItemAtURL:url toURL:saveToURL error:NULL];
	BOOL incomingFileMovedSuccessfully = [fileManager moveItemAtPath:[url path] toPath:[saveToURL path] error:NULL];
	if (incomingFileMovedSuccessfully) {
		url = saveToURL;
	}
/*
	if (docInterationController == nil) {
		[self setDocInterationController:[UIDocumentInteractionController interactionControllerWithURL:url]];
		[[self docInterationController] setDelegate:self];
	}
	else {
		[[self docInterationController] setURL:url];
	}
	[[self docInterationController] presentPreviewAnimated:YES];
*/

	
	NSString *nibName = @"DocumentViewController";
	DocumentViewController *viewController = [[[DocumentViewController alloc] 
											   initWithNibName:nibName bundle:[NSBundle mainBundle]] autorelease];
    
    NSDictionary *downloadInfo = [[FileDownloadManager sharedInstance] downloadInfoForFilename:incomingFileName];
    NSString *filename = incomingFileName;
    
    if(downloadInfo) {
        DownloadMetadata *fileMetadata = [[DownloadMetadata alloc] initWithDownloadInfo:downloadInfo];
        
        if(fileMetadata.key) {
            filename = fileMetadata.key;
        }
        [viewController setFileMetadata:fileMetadata];
        [fileMetadata release];
    }
    
    [viewController setFileName:filename];
	[viewController setFileData:[NSData dataWithContentsOfFile:[SavedDocument pathToSavedFile:incomingFileName]]];
	[viewController setHidesBottomBarWhenPushed:YES];
	
	[[self tabBarController] setSelectedIndex:3]; // TODO: parameterize -- selected Favorites tab
	
	UINavigationController *favoritesNavController = (UINavigationController *)[[self tabBarController] selectedViewController];
	[favoritesNavController popToRootViewControllerAnimated:NO];
    
    [IpadSupport clearDetailController];
    [IpadSupport pushDetailController:viewController withNavigation:favoritesNavController andSender:viewController];

	return NO;
}

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

- (void) rearrangeTabs {
    //For the cases we don't show a "show activities" setting for the user we want to control the defaut value for showing activities
    //For the cases we do show it, we want to set the kBAllowHideActivities to "NO"
    BOOL defaultShowValue = [[AppProperties propertyForKey:kBAllowHideActivities] boolValue];
    BOOL userSettingShowValue = [[NSUserDefaults standardUserDefaults] boolForKey:@"showActivitiesTab"];
                             
    BOOL hideActivitiesTab = ( !defaultShowValue && !userSettingShowValue);
                              
    if(hideActivitiesTab) {
        NSMutableArray *tabBarControllers = [NSMutableArray arrayWithArray:[tabBarController viewControllers]];
        [tabBarControllers removeObject:activitiesNavController];
        
        [tabBarController setViewControllers:tabBarControllers animated:NO];
    } else if(![tabBarController.viewControllers containsObject:activitiesNavController]) {
        int defaultTabIndex = [[AppProperties propertyForKey:kDefaultTabbarSelection] intValue];
        
        NSMutableArray *tabBarControllers = [NSMutableArray arrayWithArray:[tabBarController viewControllers]];
        [tabBarControllers insertObject:activitiesNavController atIndex:0];
        [tabBarController setViewControllers:tabBarControllers animated:NO];
        [tabBarController setSelectedIndex:defaultTabIndex];
    }
}

- (NSString *)hashForConnectionUserPref {
    NSString *protocol = userPrefProtocol();
    NSString *username = userPrefUsername();
    NSString *password = userPrefPassword();
    NSString *hostname = userPrefHostname();
    NSString *port = [[NSUserDefaults standardUserDefaults] stringForKey:@"port"];
    BOOL showCompanyHome = userPrefShowCompanyHome();
    BOOL showHiddenFiles = userPrefShowHiddenFiles();
    BOOL showFavoritesSites = [[NSUserDefaults standardUserDefaults] boolForKey:@"showFavoritesSites"];
    port = port == nil? @"": port;
    NSString *serviceDoc = serviceDocumentURIString();
    
    NSString *connectionStringPref = [NSString stringWithFormat:@"%@://%@:%@@%@:%@/%@/%d/%d/%d",
                                      protocol, username, password, hostname, port, serviceDoc, showCompanyHome, showHiddenFiles, 
                                      showFavoritesSites];
    return [connectionStringPref MD5];
}

- (void)detectReset {
    // Reset Settings if toggled
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"resetToDefault"]) 
    {
        NSLog(@"Reset Detected");
        [self resetUserPreferencesToDefault];
        //Returns to the placeholder controller for ipad
        [IpadSupport clearDetailController];
    }
}

- (void)startServiceDocumentRequest {
    [self startHUD];
    ServiceDocumentRequest *request = [ServiceDocumentRequest httpGETRequest]; 
    [request setDelegate:self];
    [request setDidFinishSelector:@selector(serviceDocumentRequestFinished:)];
    [request setDidFailSelector:@selector(serviceDocumentRequestFailed:)];
    [self setServiceDocumentRequest:request];
    [request startSynchronous];
}

- (void)serviceDocumentRequestFinished:(ServiceDocumentRequest *)sender
{
    [self stopHUD];
    self.serviceDocumentRequest = nil;
    
    if(shouldPostReloadNotification) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationRepositoryShouldReload object:nil];
        shouldPostReloadNotification = NO;
    }
}

- (void)serviceDocumentRequestFailed:(ServiceDocumentRequest *)sender
{
	NSLog(@"ServiceDocument Request Failure \n\tErrorDescription: %@ \n\tErrorFailureReason:%@ \n\tErrorObject:%@", 
          [[sender error] description], [[sender error] localizedFailureReason],[sender error]);
    
	[self stopHUD];
    self.serviceDocumentRequest = nil;
    
    // TODO Make sure the string bundles are updated for the different targets
    NSString *failureMessage = [NSString stringWithFormat:NSLocalizedString(@"serviceDocumentRequestFailureMessage", @"Failed to connect to the repository"),
                                [sender url]];
	
    UIAlertView *sdFailureAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"serviceDocumentRequestFailureTitle", @"Error")
															  message:failureMessage
															 delegate:nil 
													cancelButtonTitle:NSLocalizedString(@"Continue", nil)
													otherButtonTitles:nil] autorelease];
	[sdFailureAlert show];
    [sender cancel];
}

#pragma mark -
#pragma mark MBProgressHUD Helper Methods
- (void)startHUD
{
	if (HUD) {
		return;
	}

    if(split) {
        [self setHUD:[MBProgressHUD showHUDAddedTo:split.view animated:YES]];
    } else {
        [self setHUD:[MBProgressHUD showHUDAddedTo:tabBarController.view animated:YES]];
    }
    
    [self.HUD setRemoveFromSuperViewOnHide:YES];
    [self.HUD setTaskInProgress:YES];
    [self.HUD setMode:MBProgressHUDModeIndeterminate];
    [self.HUD show:YES];
}

- (void)stopHUD
{
	if (HUD) {
		[HUD setTaskInProgress:NO];
		[HUD hide:YES];
		[HUD removeFromSuperview];
		[self setHUD:nil];
	}
}

#pragma mark -
#pragma Global notifications
//This will only be called if the user preferences related to the repository connection changed.
- (void)defaultsChanged:(NSNotification *)notification {
    //we remove us as an observer to avoid trying to update twice
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];
    shouldPostReloadNotification = YES;
    [[SitesManagerService sharedInstance] invalidateResults];
    [self startServiceDocumentRequest];
}

@end

