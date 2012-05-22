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
#import "FileUtils.h"
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
#import "FileProtectionManager.h"
#import "MigrationManager.h"
#import "SessionKeychainManager.h"
#import "AppUrlManager.h"
#import "NSUserDefaults+DefaultPreferences.h"
#import "HomeScreenViewController.h"

#define IS_IPAD ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

/*
 Set to YES if the migration if we want to test migration and NO to have the standard behaviour for migration
 */
#define DEBUG_MIGRATION NO

static NSInteger kAlertResetAccountTag = 0;
static NSArray *unsupportedDevices;

@interface AlfrescoAppDelegate (private)
/*
 Util methods to stop and start flurry and to determine if
 we are using Flurry
 */
- (BOOL)usingFlurryAnalytics;
- (void)startFlurrySession;
- (void)stopFlurrySession;
- (void)registerDefaultsFromSettingsBundle;
- (void)sendDidRecieveMemoryWarning:(UIViewController *) controller;
- (BOOL)isFirstLaunchOfThisAppVersion;
- (void)updateAppVersion;

- (BOOL)detectReset;
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
@synthesize mainViewController;
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
    [mainViewController release];

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
    if(![[FDKeychainUserDefaults standardUserDefaults] synchronize]) {
        NSLog(@"There was an error saving/updating the userDefaults");
    }
    
    
    if(![self detectReset])
    {
        // We give another chance to the homescreen to appear
        [self presentHomeScreenController];
    }

    [ASIHTTPRequest setDefaultCacheIfEnabled];

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
    
    BOOL forgetSessionOnBackground = [[FDKeychainUserDefaults standardUserDefaults] boolForKey:@"sessionForgetWhenInactive"];
    if(forgetSessionOnBackground)
    {
        [[SessionKeychainManager sharedManager] clearSession];
    }
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
void uncaughtExceptionHandler(NSException *exception) 
{
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
    [[SessionKeychainManager sharedManager] clearSession];
    [self registerDefaultsFromSettingsBundle];
    [[self tabBarController] setDelegate:self];
    [self migrateApp];
    
    if ([self usingFlurryAnalytics]) 
    {
        [self startFlurrySession];
    }

    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:YES];
	
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	[Theme setThemeForUINavigationBar:[navigationController navigationBar]];
    
	[aboutTabBarItem setImage:[UIImage imageNamed:@"tabAboutLogo.png"]];
    
    mainViewController = nil;
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
        self.mainViewController = split;
    }
    else
    {
        [window addSubview:[tabBarController view]];
        self.mainViewController = tabBarController;
    }
    
    [window addSubview:[mainViewController view]];
    
    int defaultTabIndex = [[AppProperties propertyForKey:kDefaultTabbarSelection] intValue];
    [tabBarController setSelectedIndex:defaultTabIndex];

#if defined (TARGET_ALFRESCO)
    /**
     * We present the iPhone splash/home screen from here since we don't need to worry of the orientation.
     * For the iPad the orientation for the homescreen is wrong on launch, so we do all this in PlaceholderViewController.
     */
    if (!IS_IPAD)
    {
        if (YES == [self shouldPresentSplashScreen])
        {
            [self presentSplashScreenController];
        }
        else
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
    [[CMISServiceManager sharedManager] loadAllServiceDocumentsWithCredentials];
    [self setUserPreferencesHash:[self hashForUserPreferences]];
    // Call to forze the initialize of the FileProtectionManager needed to 
    // register the current data protection setting
    [FileProtectionManager initialize];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsChanged:) 
                                                 name:kKeychainUserDefaultsDidChangeNotification object:nil];
	return YES;
}

static NSString * const kMultiAccountSetup = @"MultiAccountSetup";

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"applicationDidBecomeActive");
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    FDKeychainUserDefaults *userDefaults = [FDKeychainUserDefaults standardUserDefaults];
    BOOL multiAccountSetup = [userDefaults boolForKey:kMultiAccountSetup];
    if (!multiAccountSetup && [self setupDefaultAccounts]) 
    {
        [userDefaults setBool:YES forKey:kMultiAccountSetup];
        [userDefaults synchronize];
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
    BOOL sendDiagnosticData = [[FDKeychainUserDefaults standardUserDefaults] boolForKey:@"sendDiagnosticData"];
    NSString *flurryKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FlurryAPIKey"];
    return ( (nil != flurryKey && [flurryKey length] > 0) && sendDiagnosticData ) ;
}

- (void)startFlurrySession
{
    [FlurryAnalytics setDebugLogEnabled:NO];
    
    // Starting the flurry session and enabling all session reporting that may had been disabled by the 
    // stopFlurrySession util method
    NSString *flurryKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FlurryAPIKey"];
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    if(!flurrySessionStarted)
    {
        [FlurryAnalytics startSession:flurryKey];
        flurrySessionStarted = YES;
    }
    
    [FlurryAnalytics setEventLoggingEnabled:YES];
    [FlurryAnalytics setSessionReportsOnCloseEnabled:YES];
    [FlurryAnalytics setSessionReportsOnPauseEnabled:YES];
}

- (void)stopFlurrySession
{
    if(flurrySessionStarted)
    {
        // Stopping the error reporting by removing the exception handler and disabling all 
        // session reporting
        NSSetUncaughtExceptionHandler(nil);
        [FlurryAnalytics setEventLoggingEnabled:NO];
        [FlurryAnalytics setSessionReportsOnCloseEnabled:NO];
        [FlurryAnalytics setSessionReportsOnPauseEnabled:NO];
    }
}

- (void)registerDefaultsFromSettingsBundle 
{
    if(![[NSUserDefaults standardUserDefaults] objectForKey:@"FirstRun"])
    {
        // This is the first run, we need to remove all the "past" user defaults and init them again
        [self resetUserPreferencesToDefault];
        [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"FirstRun"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)resetUserPreferencesToDefault
{
    NSLog(@"Resetting User Preferences to default");
    NSArray *preferences = [[FDKeychainUserDefaults standardUserDefaults] defaultPreferences];
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    [[FDKeychainUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
	
    for (NSDictionary *prefSpecification in preferences) {
        NSString *key = [prefSpecification objectForKey:@"Key"];
        if (key) {
            [[FDKeychainUserDefaults standardUserDefaults] setObject:[prefSpecification objectForKey:@"DefaultValue"] forKey:key];
        }
    }

    [[AccountManager sharedManager] saveAccounts:[NSMutableArray array]];
    [[NSNotificationCenter defaultCenter] postAccountListUpdatedNotification:nil];
    
    if ([self setupDefaultAccounts]) 
    {
        [[FDKeychainUserDefaults standardUserDefaults] setBool:YES forKey:kMultiAccountSetup];
        
    }
    [[FDKeychainUserDefaults standardUserDefaults] synchronize];
    [[SessionKeychainManager sharedManager] clearSession];
}

- (id)defaultPreferenceForKey:(NSString *)key
{
    NSArray *preferences = [self userPreferences];
    for (NSDictionary *prefSpecification in preferences) {
        NSString *prefKey = [prefSpecification objectForKey:@"Key"];
        if (nil != prefKey && [prefKey isEqualToString:key]) {
            return [prefSpecification objectForKey:@"DefaultValue"];
        }
    }
    return nil;
}


- (NSArray *) userPreferences {
    NSString *rootPlist = [[NSBundle mainBundle] pathForResource:@"Root" ofType:@"plist"];
    if(!rootPlist) {
        NSLog(@"Could not find Settings.bundle");
        return [NSArray array];
    }
	
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:rootPlist];
    return [settings objectForKey:@"PreferenceSpecifiers"];
}

// Rules: show the homescreen on each app launch if the user has no accounts, or if the preference is YES.
// The preference will be reset each time the screen is shown.
- (BOOL)shouldPresentHomeScreen
{
    // The homescreen.show property should be set to YES if we want to show the homescreen at all
    BOOL showHomescreenAppProperty = [[AppProperties propertyForKey:kHomescreenShow] boolValue];

    // We'll override the preference if the user has no accounts configured
    BOOL hasNoAccounts = ([[[AccountManager sharedManager] allAccounts] count] == 0);
    
    NSNumber *showHomescreenPref = [[FDKeychainUserDefaults standardUserDefaults] objectForKey:@"ShowHomescreen"];
    // If there's nothing in the key it means we haven't showed the homescreen and we need to initialize the property
    if (showHomescreenPref == nil)
    {
        [[FDKeychainUserDefaults standardUserDefaults] setBool:YES forKey:@"ShowHomescreen"];
        [[FDKeychainUserDefaults standardUserDefaults] synchronize];
        showHomescreenPref = [NSNumber numberWithBool:YES];
    }
    
    return showHomescreenAppProperty && ([showHomescreenPref boolValue] || hasNoAccounts);
}

- (void)presentHomeScreenController
{
    if ([self shouldPresentHomeScreen])
    {
        [self forcePresentHomeScreenController];
    }
}

- (void)forcePresentHomeScreenController
{
    HomeScreenViewController *homeScreen = nil;
    if (IS_IPAD)
    {
        homeScreen = [[HomeScreenViewController alloc] initWithNibName:@"HomeScreenViewController~iPad" bundle:nil];
    }
    else
    {
        homeScreen = [[HomeScreenViewController alloc] initWithNibName:@"HomeScreenViewController" bundle:nil];
    }

    [IpadSupport presentFullScreenModalViewController:homeScreen];
    [homeScreen release];
}

- (void)dismissModalViewController
{
    if (IS_IPAD)
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

    NSNumber *alreadyStartedOnVersion = [[FDKeychainUserDefaults standardUserDefaults] objectForKey:appFirstStartOfVersionKey];
    if ((!alreadyStartedOnVersion || [alreadyStartedOnVersion boolValue] == NO) || DEBUG_MIGRATION)
    {
        // Let's remove all the old values
        FDKeychainUserDefaults *userDefaults = [FDKeychainUserDefaults standardUserDefaults];
        NSSet *keys = [[userDefaults dictionaryRepresentation] keysOfEntriesPassingTest:^BOOL(NSString *key, id obj, BOOL *stop)
        {
            return ([key hasPrefix:@"first_launch_"]);
        }];

        for (NSString *key in keys)
        {
            [userDefaults removeObjectForKey:key];
        }
        
        [userDefaults setBool:YES forKey:appFirstStartOfVersionKey];
        [userDefaults synchronize];
        isFirstLaunch = YES;
    }
    return isFirstLaunch;
}


- (void)updateAppVersion
{
    if([self isFirstLaunchOfThisAppVersion])
    {
        NSString *bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
        NSString *appFirstStartOfVersionKey = [NSString stringWithFormat:@"first_launch_%@", bundleVersion];
        [[FDKeychainUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:appFirstStartOfVersionKey];
        [[FDKeychainUserDefaults standardUserDefaults] synchronize];
    }
}

- (BOOL)shouldPresentSplashScreen
{
    return [self isFirstLaunchOfThisAppVersion];
}

- (void)presentSplashScreenController
{
    SplashScreenViewController *splashScreen;
    if (IS_IPAD)
    {
        splashScreen = [[SplashScreenViewController alloc] initWithNibName:@"SplashScreenViewController~iPad" bundle:nil];
    }
    else
    {
        splashScreen = [[SplashScreenViewController alloc] initWithNibName:@"SplashScreenViewController" bundle:nil];
    }

    [IpadSupport presentFullScreenModalViewController:splashScreen];
    [splashScreen release];

    [self setShowedSplash:YES];
}

- (BOOL)detectReset {
    // Reset Settings if toggled
    if ([[FDKeychainUserDefaults standardUserDefaults] boolForKey:@"resetToDefault"]) 
    {
        NSLog(@"Reset Detected - Asking user for confirmation");
        UIAlertView *resetConfirmation = [[UIAlertView alloc] initWithTitle:@"App Reset Confirmation" 
            message:@"Are you sure you want to reset the application? This will remove all data, reset the app settings, will remove all accounts and cannot be undone" 
                                                                   delegate:self cancelButtonTitle:NSLocalizedString(@"No", @"No") otherButtonTitles: NSLocalizedString(@"Yes", @"Yes"), nil];
        [resetConfirmation setTag:kAlertResetAccountTag];
        [resetConfirmation show];
        [resetConfirmation release];
        return YES;
    }
    return NO;
}

- (BOOL)isTVOutUnsupported
{
    UIDeviceHardware *device = [[UIDeviceHardware alloc] init];
    BOOL unsupported = [unsupportedDevices containsObject:[device platform]];
    
    [device release];
    
    return unsupported;
}

- (void)presentModalViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self.mainViewController presentModalViewController:viewController animated:animated];
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
            [self presentHomeScreenController];
        
            //Returns to the placeholder controller for ipad
            [IpadSupport clearDetailController];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"reset"];
            [[NSNotificationCenter defaultCenter] postAccountListUpdatedNotification:userInfo];
        } 
        else 
        {
            [[FDKeychainUserDefaults standardUserDefaults] setBool:NO forKey:@"resetToDefault"];
            [[FDKeychainUserDefaults standardUserDefaults] synchronize];
        }
    }
}

#pragma mark -
#pragma mark Global notifications
//This will only be called if the user preferences related to the repository connection changed.
- (void)defaultsChanged:(NSNotification *)notification {
    NSString *currentHash = [self hashForUserPreferences];
    if(![userPreferencesHash isEqualToString:currentHash])
    
    if(![userPreferencesHash isEqualToString:[self hashForUserPreferences]])
    {
        [self setUserPreferencesHash:currentHash];
        [[NSNotificationCenter defaultCenter] postUserPreferencesChangedNotification];
    }
    
    //Resetting the flurry configuration in case the user changed the send diagnostic data setting
    if ([self usingFlurryAnalytics]) 
    {
        [self startFlurrySession];
    }
    else 
    {
        [self stopFlurrySession];
    }
}

- (NSString *)hashForUserPreferences {
    BOOL showCompanyHome = userPrefShowCompanyHome();
    BOOL showHiddenFiles = userPrefShowHiddenFiles();
    BOOL useLocalComments = [[FDKeychainUserDefaults standardUserDefaults] boolForKey:@"useLocalComments"];
    
    NSString *connectionStringPref = [NSString stringWithFormat:@"%d/%d/%d",
                                      showCompanyHome, showHiddenFiles, useLocalComments];
    return [connectionStringPref MD5];
}

#pragma mark -
#pragma mark Misc Migration
- (void)migrateApp {
    if(![[FDKeychainUserDefaults standardUserDefaults] boolForKey:@"migration.DownloadMetadata"])
        [self migrateMetadataFile];
    
    NSDictionary *allPreferences = [[FDKeychainUserDefaults standardUserDefaults] dictionaryRepresentation];
    //Contains all the numbers of the bundle versions that the migration has run
    NSMutableArray *allFirstLaunch = [NSMutableArray array];
    for (NSString* key in allPreferences) {
        // If debug is enabled, we don't add the bundle version so that every migration command runs
        if ([key hasPrefix:@"first_launch_"] && !DEBUG_MIGRATION) {
            // found a key that starts with first_launch_ which means that is a user default
            // that we set when the migration was run
            // We then remove the "first_launch_" prefix and get the bundle version
            NSString *bundleVersion = [key stringByReplacingOccurrencesOfString:@"first_launch_" withString:@""];
            [allFirstLaunch addObject:bundleVersion];
        }
    }
    
    if([self isFirstLaunchOfThisAppVersion])
    {
        [[MigrationManager sharedManager] runMigrationWithVersions:allFirstLaunch];
        [self updateAppVersion];
    }
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
    
    [[FDKeychainUserDefaults standardUserDefaults] setBool:YES forKey:@"migration.DownloadMetadata"];
    [[FDKeychainUserDefaults standardUserDefaults] synchronize];
}

@end
