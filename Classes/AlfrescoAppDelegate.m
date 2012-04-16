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
//  AlfrescoAppDelegate.m
//

#import <QuartzCore/QuartzCore.h>

#import "AlfrescoAppDelegate.h"
#import "RootViewController.h"
#import "Theme.h"
#import "FixedBackgroundWithRotatingLogoView.h"
#import "DocumentViewController.h"
#import "SavedDocument.h"
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
#import "Utility.h"
#import "NSString+MD5.h"
#import "AppProperties.h"
#import "AlfrescoAppDelegate+UITabBarControllerDelegate.h"
#import "AccountManager.h"
#import "AlfrescoAppDelegate+DefaultAccounts.h"
#import "CMISServiceManager.h"
#import "NSData+Base64.h"
#import "QOPartnerApplicationAnnotationKeys.h"
#import "CMISMediaTypes.h"
#import "AlfrescoUtils.h"
#import "SplashScreenViewController.h"
#import "NSNotificationCenter+CustomNotification.h"
#import "AppUrlManager.h"
#import "NSUserDefaults+DefaultPreferences.h"
#import "HomeScreenViewController.h"

#define IS_IPAD ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

static NSInteger kAlertResetAccountTag = 0;
static NSArray *unsupportedDevices;

@interface AlfrescoAppDelegate (private)
- (void)registerDefaultsFromSettingsBundle;
- (void)sendDidRecieveMemoryWarning:(UIViewController *) controller;
- (void)rearrangeTabs;
- (BOOL)isFirstLaunchOfThisAppVersion;

- (void)detectReset;
- (void)migrateApp;
- (void)migrateMetadataFile;
- (NSString *)hashForUserPreferences;
- (BOOL)isTVOutUnsupported;
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
@synthesize moreNavController;
@synthesize splitViewController;
@synthesize userPreferencesHash;
@synthesize showedSplash;

#pragma mark -
#pragma mark Memory management

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [window release];
	[navigationController release];
	[tabBarController release];
	[sitesController release];
    [aboutViewController release];
	[docInterationController release];
	[aboutTabBarItem release];
    [activitiesNavController release];
    [moreNavController release];
    
    [tabBarDelegate release];
    [splitViewController release];
    [userPreferencesHash release];

	[super dealloc];
}

+ (void)initialize
{
    // We use a whitelist rather than a blacklist to include the devices that do not support native TV mirroring since it is more likely
    // that new devices support native TV out mirroring
    unsupportedDevices = [[NSArray arrayWithObjects:@"iPhone1,1",@"iPhone1,2",@"iPhone2,1",@"iPhone3,1",@"iPhone3,3"
                                   @"iPod1,1",@"iPod2,1",@"iPod3,1",@"iPod4,1",@"iPad1,1",@"i386",@"x86_64", nil] retain];
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
    // We give another chance to the homescreen to appear because the user could have turned on the "Show Homescreen on next start" setting
    [self presentHomeScreenController];

    [ASIHTTPRequest setDefaultCacheIfEnabled];
    [self rearrangeTabs];

    //If native TV out is unsupported we want to use TVOutManager 
    if ( [self isTVOutUnsupported] && [[UIScreen screens] count] > 1)
    {
        [[TVOutManager sharedInstance] setImplementation:kTVOutImplementationCADisplayLink];
        [[TVOutManager sharedInstance] startTVOut];
    }
    else if([self isTVOutUnsupported])
    {
        [[TVOutManager sharedInstance] setImplementation:kTVOutImplementationCADisplayLink];
    }
        
}

- (void) applicationDidEnterBackground:(UIApplication *)application {
    // Simulate a memory warning in our view controllers so they are responsible
    // to free up the memory
    [self sendDidRecieveMemoryWarning:tabBarController];
    
    if(splitViewController) {
        [self sendDidRecieveMemoryWarning:splitViewController];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsChanged:) 
                                                 name:NSUserDefaultsDidChangeNotification object:nil];
}

- (void)sendDidRecieveMemoryWarning:(UIViewController *) controller {
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
    // Disabling the TVOutManager before the app goes into the background.
    // We should not call the method for the devices that support native TV out mirroring
    if ( [self isTVOutUnsupported])
    {
        [[TVOutManager sharedInstance] stopTVOut];
    }
    
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];

    //ViewControllers should listen to this notification so it can cancel active
    //network operations
    
}

#pragma mark -
#pragma mark Fatal error processing
void uncaughtExceptionHandler(NSException *exception) {
    BOOL sendDiagnosticData = [[NSUserDefaults standardUserDefaults] boolForKey:@"sendDiagnosticData"];
    if(sendDiagnosticData)
    {
        [FlurryAnalytics logError:@"Uncaught Exception" message:@"Crash!" exception:exception];
    }
}


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions 
{
    [[self tabBarController] setDelegate:self];
    [self migrateApp];
    
	[self registerDefaultsFromSettingsBundle];
    
    NSString *flurryKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FlurryAPIKey"];
    BOOL sendDiagnosticData = [[NSUserDefaults standardUserDefaults] boolForKey:@"sendDiagnosticData"];
    if (nil != flurryKey && [flurryKey length] > 0 && sendDiagnosticData) 
    {
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
    
    UIViewController *mainViewController;
    if (IS_IPAD)
    {
        MGSplitViewController *split = [[MGSplitViewController alloc] init];
        [self setSplitViewController:split];
        
        PlaceholderViewController *viewController = [[[PlaceholderViewController alloc] init] autorelease];
        DetailNavigationController *detail = [[[DetailNavigationController alloc]initWithRootViewController:viewController] autorelease]; // a detail view will come here
        UINavigationController *nav = [[[UINavigationController alloc] initWithRootViewController:tabBarController] autorelease];
        nav.navigationBarHidden = YES;
        
        [Theme setThemeForUINavigationController:detail];
        
        split.delegate = detail;
        split.viewControllers = [NSArray arrayWithObjects: nav,detail, nil];
        
        [split release];
        [IpadSupport registerGlobalDetail:detail];
        
        mainViewController = self.splitViewController;
        [window addSubview:[mainViewController view]];
    }
    else
    {
        mainViewController = tabBarController;
    }
    
    [window addSubview:[mainViewController view]];
    
    int defaultTabIndex = [[AppProperties propertyForKey:kDefaultTabbarSelection] intValue];
    [tabBarController setSelectedIndex:defaultTabIndex];
    
    [self rearrangeTabs];

#if defined (TARGET_ALFRESCO)
    if (YES == [self isFirstLaunchOfThisAppVersion])
    {
        SplashScreenViewController *splashScreen = [[[SplashScreenViewController alloc] init] autorelease];
        [splashScreen setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
        [mainViewController presentModalViewController:splashScreen animated:YES];
        [self setShowedSplash:YES];
    }
    else
    {
        // We present the homescreen from here since we don't need to worry of the orientation, in the iPad the orientation for the homescreen is wrong
        // at the start of the app that's why we have to present it after the views appear (PlaceholderViewController)
        if(!IS_IPAD)
        {
            [self presentHomeScreenController];
        }
    }
#endif

    [window makeKeyAndVisible];
    
	NSURL *url = (NSURL *)[launchOptions valueForKey:UIApplicationLaunchOptionsURLKey];
	if ([url isFileURL] && [[[UIDevice currentDevice] systemVersion] hasPrefix:@"3.2"]) {
		[[self tabBarController] setSelectedIndex:2];
		[self application:[UIApplication sharedApplication] handleOpenURL:url];
	}
    
    //If native TV out is unsupported we want to use TVOutManager 
    //We don't need to start the TVOutManager when there's only one screen
    if ( [self isTVOutUnsupported] && [[UIScreen screens] count] > 1)
    {
        [[TVOutManager sharedInstance] setImplementation:kTVOutImplementationCADisplayLink];
        [[TVOutManager sharedInstance] startTVOut];
    }
    else if([self isTVOutUnsupported])
    {
        // But we need to initialize the sharedInstance.
        // When we call the sharedInstance for the first time, the TVOutManager starts to listen to the
        // Screen notifications (screen connect/disconnect mode change) and will activate the TVOutManager
        // when a screen connects and stop it when it disconnects
        [[TVOutManager sharedInstance] setImplementation:kTVOutImplementationCADisplayLink];
    }
    
    [self detectReset];
    [ASIHTTPRequest setDefaultCacheIfEnabled];
    
    [[CMISServiceManager sharedManager] loadAllServiceDocuments];
    [self setUserPreferencesHash:[self userPreferencesHash]];
    
	return YES;
}

static NSString * const kMultiAccountSetup = @"MultiAccountSetup";

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"applicationDidBecomeActive");
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL multiAccountSetup = [userDefaults boolForKey:kMultiAccountSetup];
    if (!multiAccountSetup && [self setupDefaultAccounts]) 
    {
        [userDefaults setBool:YES forKey:kMultiAccountSetup];
    }
}

#pragma mark -
#pragma mark App Delegate - Document Support

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [[AppUrlManager sharedManager] handleUrl:url annotation:annotation];
}

#pragma mark -
#pragma mark Private methods

- (BOOL)usingFlurryAnalytics
{
    NSString *flurryKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FlurryAPIKey"];
    return (nil != flurryKey && [flurryKey length] > 0);
}

// this works around the fact the settings return nil rather than the default if the user has never opened the preferences
// thank you "PCheese": http://stackoverflow.com/questions/510216/can-you-make-the-settings-in-settings-bundle-default-even-if-you-dont-open-the-s
- (void)registerDefaultsFromSettingsBundle {
    NSArray *preferences = [[NSUserDefaults standardUserDefaults] defaultPreferences];
	
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
    NSArray *preferences = [[NSUserDefaults standardUserDefaults] defaultPreferences];
	
    for (NSDictionary *prefSpecification in preferences) {
        NSString *key = [prefSpecification objectForKey:@"Key"];
        if (key) {
            [[NSUserDefaults standardUserDefaults] setValue:[prefSpecification objectForKey:@"DefaultValue"] forKey:key];
        }
    }

    [[AccountManager sharedManager] saveAccounts:[NSMutableArray array]];
    
    if ([self setupDefaultAccounts]) 
    {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kMultiAccountSetup];
        
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
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

// If the user dismissed the homescreen at least once we don't show it again
// The user may select in the settings to show the HomeScreenAgain
- (BOOL)shouldPresentHomeScreen
{
    // The homescreen.show property should be set to YES if we want to show the homescreen
    BOOL showHomescreenAppProperty = [[AppProperties propertyForKey:kHomescreenShow] boolValue];
    NSNumber *showHomescreenPref = [[NSUserDefaults standardUserDefaults] objectForKey:@"ShowHomescreen"];
    // If there's nothing in the key it means we haven't showed the homescreen and we need to initialize the property
    if(showHomescreenPref == nil)
    {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ShowHomescreen"];
        showHomescreenPref = [NSNumber numberWithBool:YES];
    }
    
    return showHomescreenAppProperty && [showHomescreenPref boolValue];
}

- (void)presentHomeScreenController
{
    if([self shouldPresentHomeScreen])
    {
        HomeScreenViewController *homeScreen = nil;
        UIViewController *presentingController = nil;
        if(IS_IPAD)
        {
            homeScreen = [[HomeScreenViewController alloc] initWithNibName:@"HomeScreenViewController~iPad" bundle:nil];
            presentingController = self.splitViewController;
        }
        else
        {
            homeScreen = [[HomeScreenViewController alloc] initWithNibName:@"HomeScreenViewController" bundle:nil];
            presentingController = self.tabBarController;
        }
        
        [homeScreen setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
        [homeScreen setModalPresentationStyle:UIModalPresentationFullScreen];
        [presentingController presentModalViewController:homeScreen animated:YES];
        [homeScreen release];
        
    }
}

- (void)dismissHomeScreenController
{
    if(IS_IPAD)
    {
        [self.splitViewController dismissModalViewControllerAnimated:YES];
    }
    else
    {
        [self.tabBarController dismissModalViewControllerAnimated:YES];
    }
}

- (BOOL)isFirstLaunchOfThisAppVersion
{
    // Return whether this is the first time this particular version of the app has been launched
    BOOL isFirstLaunch = NO;
    NSString *bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    NSString *appFirstStartOfVersionKey = [NSString stringWithFormat:@"first_launch_%@", bundleVersion];
    NSNumber *alreadyStartedOnVersion = [[NSUserDefaults standardUserDefaults] objectForKey:appFirstStartOfVersionKey];
    if (!alreadyStartedOnVersion || [alreadyStartedOnVersion boolValue] == NO)
    {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:appFirstStartOfVersionKey];
        isFirstLaunch = YES;
    }
    return isFirstLaunch;
}

- (void)detectReset {
    // Reset Settings if toggled
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"resetToDefault"]) 
    {
        NSLog(@"Reset Detected - Asking user for confirmation");
        UIAlertView *resetConfirmation = [[UIAlertView alloc] initWithTitle:@"App Reset Confirmation" 
            message:@"Are you sure you want to reset the application? This will remove all data, reset the app settings, will remove all accounts and cannot be undone" 
                                                                   delegate:self cancelButtonTitle:NSLocalizedString(@"No", @"No") otherButtonTitles: NSLocalizedString(@"Yes", @"Yes"), nil];
        [resetConfirmation setTag:kAlertResetAccountTag];
        [resetConfirmation show];
        [resetConfirmation release];
    }
}

- (BOOL)isTVOutUnsupported
{
    UIDeviceHardware *device = [[UIDeviceHardware alloc] init];
    BOOL unsupported = [unsupportedDevices containsObject:[device platform]];
    
    [device release];
    
    return unsupported;
}

#pragma mark - 
#pragma mark Alert Confirmation
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex 
{
    if (alertView.tag == kAlertResetAccountTag)
    {
        if (buttonIndex == 1) 
        {
            [self resetUserPreferencesToDefault];
        
            //Returns to the placeholder controller for ipad
            [IpadSupport clearDetailController];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"reset"];
            [[NSNotificationCenter defaultCenter] postAccountListUpdatedNotification:userInfo];
        } 
        else 
        {
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"resetToDefault"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}

#pragma mark -
#pragma mark Global notifications
//This will only be called if the user preferences related to the repository connection changed.
- (void)defaultsChanged:(NSNotification *)notification 
{
    //we remove us as an observer to avoid trying to update twice
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];
    
    if(![userPreferencesHash isEqualToString:[self hashForUserPreferences]])
    {
        [self setUserPreferencesHash:[self userPreferencesHash]];
        [[NSNotificationCenter defaultCenter] postUserPreferencesChangedNotification];
    }
}

- (NSString *)hashForUserPreferences {
    BOOL showCompanyHome = userPrefShowCompanyHome();
    BOOL showHiddenFiles = userPrefShowHiddenFiles();
    BOOL useLocalComments = [[NSUserDefaults standardUserDefaults] boolForKey:@"useLocalComments"];
    
    NSString *connectionStringPref = [NSString stringWithFormat:@"%d/%d/%d",
                                      showCompanyHome, showHiddenFiles, useLocalComments];
    return [connectionStringPref MD5];
}

#pragma mark -
#pragma mark Misc Migration
- (void)migrateApp {
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"migration.DownloadMetadata"])
        [self migrateMetadataFile];
}

/**
 * Look for the old download metadata file. If it exists, we move it to the new path and delete the "config" folder.
 */
- (void)migrateMetadataFile {
    NSString *oldPath = [[FileDownloadManager sharedInstance] oldMetadataPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if([fileManager fileExistsAtPath:oldPath isDirectory:NO]) {
        NSError *error = nil;
        NSString *newPath = [[FileDownloadManager sharedInstance] metadataPath];
        [fileManager moveItemAtPath:oldPath toPath:newPath error:&error];
        
        if(error) {
            NSLog(@"Cannot move the configuration file from the old location to the new");
        }
    }
    
    NSString *oldConfigDir = [oldPath stringByDeletingLastPathComponent];
    BOOL isDirectory;
    
    if([fileManager fileExistsAtPath:oldConfigDir isDirectory:&isDirectory] && isDirectory) {
        NSError *error = nil;
        [fileManager removeItemAtPath:oldConfigDir error:&error];
        
        if(error) {
            NSLog(@"Error deleting the old config folder");
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"migration.DownloadMetadata"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end

