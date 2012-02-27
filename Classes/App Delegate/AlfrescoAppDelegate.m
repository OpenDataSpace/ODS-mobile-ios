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

#define IS_IPAD ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

/*
 Set to YES if the migration if we want to test migration and NO to have the standard behaviour for migration
 */
#define DEBUG_MIGRATION NO

static NSInteger kAlertResetAccountTag = 0;
static NSInteger kAlertUpdateFailedTag = 1;

@interface AlfrescoAppDelegate (private)
- (NSDictionary *)partnerInfoForIncomingFile:(id)annotation;
- (NSURL *)saveIncomingFileWithURL:(NSURL *)url;
- (NSURL *)saveIncomingFileWithURL:(NSURL *)url toFilePath:(NSString *)filePath;
- (BOOL)updateRepositoryNode:(DownloadMetadata *)fileMetadata fileURLToUpload:(NSURL *)fileURLToUpload;
- (BOOL)updateRepositoryNode:(DownloadMetadata *)fileMetadata fileURLToUpload:(NSURL *)fileURLToUpload withFileName:(NSString *)fileName;
- (void)displayContentsOfFileWithURL:(NSURL *)url;
- (void)displayContentsOfFileWithURL:(NSURL *)url setActiveTabBar:(int)tabBarIndex;
- (NSString *)applicationDocumentsDirectory;
- (void)registerDefaultsFromSettingsBundle;
- (void)sendDidRecieveMemoryWarning:(UIViewController *) controller;
- (NSArray *)userPreferences;
- (void)rearrangeTabs;
- (BOOL)isFirstLaunchOfThisAppVersion;
- (void)updateAppVersion;

- (void)detectReset;
- (void)migrateApp;
- (void)migrateMetadataFile;
- (NSString *)hashForUserPreferences;
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
@synthesize postProgressBar;
@synthesize userPreferencesHash;
@synthesize mainViewController;

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
    [moreNavController release];
    [postProgressBar release];
    
    [tabBarDelegate release];
    [split release];
    [updatedFileName release];
    [userPreferencesHash release];
    [mainViewController release];

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

    [ASIHTTPRequest setDefaultCacheIfEnabled];
    [self rearrangeTabs];

    if ( !isIPad2Device )
    {
        [[TVOutManager sharedInstance] setImplementation:kTVOutImplementationCADisplayLink];
        [[TVOutManager sharedInstance] startTVOut];
    }
        
}

- (void) applicationDidEnterBackground:(UIApplication *)application {
    // Simulate a memory warning in our view controllers so they are responsible
    // to free up the memory
    [self sendDidRecieveMemoryWarning:tabBarController];
    
    if(split) {
        [self sendDidRecieveMemoryWarning:split];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsChanged:) 
                                                 name:NSUserDefaultsDidChangeNotification object:nil];
    
    BOOL forgetSessionOnBackground = [[NSUserDefaults standardUserDefaults] boolForKey:@"sessionForgetWhenInactive"];
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

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions 
{
    [[SessionKeychainManager sharedManager] clearSession];
    [[self tabBarController] setDelegate:self];
    [self migrateApp];
    
    UIDeviceHardware *device = [[UIDeviceHardware alloc] init];
    isIPad2Device = [[device platform] hasPrefix:@"iPad2"];
    
    [device release];
    
	[self registerDefaultsFromSettingsBundle];
    
    NSString *flurryKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FlurryAPIKey"];
    if (nil != flurryKey && [flurryKey length] > 0) 
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
    
    mainViewController = nil;
    if (IS_IPAD)
    {
        PlaceholderViewController *viewController = [[[PlaceholderViewController alloc] init] autorelease];
        DetailNavigationController *detail = [[[DetailNavigationController alloc]initWithRootViewController:viewController] autorelease]; // a detail view will come here
        UINavigationController *nav = [[[UINavigationController alloc] initWithRootViewController:tabBarController] autorelease];
        nav.navigationBarHidden = YES;
        
        [Theme setThemeForUINavigationController:detail];
        split = [[MGSplitViewController alloc] init];
        split.delegate = detail;
        split.viewControllers = [NSArray arrayWithObjects: nav,detail, nil];
        [IpadSupport registerGlobalDetail:detail];
        [window addSubview:[split view]];
        self.mainViewController = split;
    }
    else
    {
        [window addSubview:[tabBarController view]];
        self.mainViewController = tabBarController;
    }
    
    int defaultTabIndex = [[AppProperties propertyForKey:kDefaultTabbarSelection] intValue];
    [tabBarController setSelectedIndex:defaultTabIndex];
    
    [self rearrangeTabs];

#if defined (TARGET_ALFRESCO)
    if (YES == [self isFirstLaunchOfThisAppVersion])
    {
        SplashScreenViewController *splashScreen = [[[SplashScreenViewController alloc] init] autorelease];
        [splashScreen setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
        [self.mainViewController presentModalViewController:splashScreen animated:YES];
        [window addSubview:[splashScreen view]];
    }
#endif

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
    
    [[CMISServiceManager sharedManager] loadAllServiceDocumentsWithCredentials];
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
    // Would be nice to use a keypath for this but I (BW) could get that working...
    // This pulls the first urlScheme from the main bundle.
    NSArray *urlTypes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleURLTypes"];
    NSDictionary *urlType = (nil == urlTypes ? nil : [urlTypes objectAtIndex:0]);
    NSArray *urlSchemes = (nil == urlType ? nil : [urlType objectForKey:@"CFBundleURLSchemes"]);
    NSString *urlScheme = (nil == urlSchemes ? nil : [urlSchemes objectAtIndex:0]);
    
    NSString *incomingProtocol = [url scheme];
    NSString *incomingHost     = [url host];
    if (nil != urlScheme && [incomingProtocol isEqual:urlScheme]) 
    {
        if ([incomingHost isEqualToString:@"add-account"]) 
        {
            NSDictionary *queryPairs = [url queryPairs];
            
            NSString *username = defaultString((NSString *)[queryPairs objectForKey:@"username"], @"");
            NSString *password = defaultString((NSString *)[queryPairs objectForKey:@"password"], @"");
            NSString *host = defaultString((NSString *)[queryPairs objectForKey:@"host"], (NSString*)[self defaultPreferenceForKey:@"host"]);
            NSString *port = defaultString((NSString *)[queryPairs objectForKey:@"port"], (NSString*)[self defaultPreferenceForKey:@"port"]);
            NSString *protocol = defaultString((NSString *)[queryPairs objectForKey:@"protocol"], (NSString *)[self defaultPreferenceForKey:@"protocol"]);
            NSString *webapp = defaultString((NSString *)[queryPairs objectForKey:@"webapp"], (NSString *)[self defaultPreferenceForKey:@"webapp"]);
            BOOL showCompanyHome =  stringToBoolWithNumericDefault((NSString *)[queryPairs objectForKey:@"showCompanyHome"], (NSNumber *)[self defaultPreferenceForKey:@"showCompanyHome"]);
            BOOL showHidden = stringToBoolWithNumericDefault((NSString *)[queryPairs objectForKey:@"showHidden"], (NSNumber *)[self defaultPreferenceForKey:@"showHidden"]);
            BOOL fullTextSearch = stringToBoolWithNumericDefault((NSString *)[queryPairs objectForKey:@"fullTextSearch"], (NSNumber *)[self defaultPreferenceForKey:@"fullTextSearch"]);
            
            AccountInfo *incomingAccountInfo = [[AccountInfo alloc] init];
            [incomingAccountInfo setUsername:username];
            [incomingAccountInfo setPassword:password];
            [incomingAccountInfo setHostname:host];
            [incomingAccountInfo setPort:port];
            [incomingAccountInfo setProtocol:protocol];
            [incomingAccountInfo setServiceDocumentRequestPath:webapp];
            [incomingAccountInfo setDescription:[NSString stringWithFormat:@"%@@%@", username, host]];
            
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setBool:showCompanyHome forKey:@"showCompanyHome"];
            [userDefaults setBool:showHidden forKey:@"showHidden"];
            [userDefaults setBool:fullTextSearch forKey:@"fullTextSearch"];
            
            NSMutableArray *accountList = [[AccountManager sharedManager] allAccounts];
            [accountList addObject:incomingAccountInfo];
            [incomingAccountInfo release];
            [[AccountManager sharedManager] saveAccounts:accountList];
            
            [[NSNotificationCenter defaultCenter] postAccountListUpdatedNotification:[NSDictionary dictionaryWithObject:[incomingAccountInfo uuid] forKey:@"uuid"]];
            
            
            // TODO: Refresh views in case creds have changed.
        }
    } 
    else if ([incomingProtocol isEqualToString:@"file"])
    {        
        // Check annotation data for Quickoffice integration
        NSString *receivedSecretUUID = [annotation objectForKey: PartnerApplicationSecretUUIDKey];
        NSString *partnerApplicationSecretUUID = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"QuickofficePartnerKey"];
        NSDictionary *partnerInfo = [self partnerInfoForIncomingFile:annotation];
        
        if (partnerInfo != nil && [receivedSecretUUID isEqualToString: partnerApplicationSecretUUID] == YES)
        {
            // extract the file metadata, if present
            NSDictionary *fileMeta = [partnerInfo objectForKey:PartnerApplicationFileMetadataKey];
            NSString *originalFilePath = [partnerInfo objectForKey:PartnerApplicationDocumentPathKey];
            
            if (fileMeta != nil)
            {
                DownloadMetadata *downloadMeta = [[DownloadMetadata alloc] initWithDownloadInfo:fileMeta];
                
                // grab the content and upload it to the provided nodeRef
                if (originalFilePath != nil)
                {
                    NSString *originalFileName = [[originalFilePath pathComponents] lastObject];
                    [[FileDownloadManager sharedInstance] setDownload:fileMeta forKey:originalFileName];
                    [self updateRepositoryNode:downloadMeta fileURLToUpload:url withFileName:originalFileName];
                }
                else
                {
                    NSLog(@"WARNING: File received with incomplete partner info!");
                    [self updateRepositoryNode:downloadMeta fileURLToUpload:url];
                }
                
                [downloadMeta release];
            }
            else
            {
                // save the file locally to the downloads folder
                NSURL *saveToURL;
                if (originalFilePath != nil)
                {
                    // the downloaded filename will have changed from the original
                    saveToURL = [self saveIncomingFileWithURL:url toFilePath:originalFilePath];
                }
                else
                {
                    // save with the name we were given
                    saveToURL = [self saveIncomingFileWithURL:url];
                }
                
                // display the contents of the saved file
                [self displayContentsOfFileWithURL:saveToURL setActiveTabBar:3];
            }
        }
        else
        {
            // save the incoming file
            NSURL *saveToURL = [self saveIncomingFileWithURL:url];
            
            // Set the "do not backup" flag
            addSkipBackupAttributeToItemAtURL(saveToURL);
            
            // display the contents of the saved file
            [self displayContentsOfFileWithURL:saveToURL setActiveTabBar:3];
        }
    }
    
    return YES;
}

#pragma mark -
#pragma mark Private methods

- (NSDictionary *)partnerInfoForIncomingFile:(id)annotation
{
    NSDictionary *alfOptions = nil;
    
    if (annotation != nil)
    {
        NSLog(@"annotation = %@", annotation);
        
        alfOptions = [annotation objectForKey:PartnerApplicationInfoKey];
    }
    
    return alfOptions;
}

- (NSURL *)saveIncomingFileWithURL:(NSURL *)url
{
    return [self saveIncomingFileWithURL:url toFilePath:nil];
}

- (NSURL *)saveIncomingFileWithURL:(NSURL *)url toFilePath:(NSString *)filePath
{
    NSURL *saveToURL;
    
    // TODO: lets be robust, make sure a file exists at the URL
	
	NSString *incomingFilePath = [url path];
	NSString *incomingFileName = [[incomingFilePath pathComponents] lastObject];
	NSString *saveToPath = filePath != nil ? filePath : [[self applicationDocumentsDirectory] stringByAppendingPathComponent:incomingFileName];
	saveToURL = [NSURL fileURLWithPath:saveToPath];
    
	NSFileManager *fileManager = [NSFileManager defaultManager];
	BOOL fileExistsInFavorites = [fileManager fileExistsAtPath:saveToPath];
	if (fileExistsInFavorites) {
		[fileManager removeItemAtURL:saveToURL error:NULL];
		NSLog(@"Removed File '%@' From Favorites Folder", incomingFileName);
	}
    
    if ([fileManager fileExistsAtPath:[FileUtils pathToTempFile:incomingFileName]]) {
        NSURL *tempURL = [NSURL fileURLWithPath:[FileUtils pathToTempFile:incomingFileName]];
        [fileManager removeItemAtURL:tempURL error:NULL];
    }
    
    //	BOOL incomingFileMovedSuccessfully = [fileManager moveItemAtURL:url toURL:saveToURL error:NULL];
	BOOL incomingFileMovedSuccessfully = [fileManager moveItemAtPath:[url path] toPath:[saveToURL path] error:NULL];
	if (!incomingFileMovedSuccessfully) 
    {
        // return nil if document move failed.
		saveToURL = nil;
	} else 
    {
        [[FileProtectionManager sharedInstance] completeProtectionForFileAtPath:[saveToURL path]];
    }
    
    return saveToURL;
}

- (void)displayContentsOfFileWithURL:(NSURL *)url
{
    [self displayContentsOfFileWithURL:url setActiveTabBar:-1];
}

- (void)displayContentsOfFileWithURL:(NSURL *)url setActiveTabBar:(int)tabBarIndex
{
    NSString *incomingFilePath = [url path];
	NSString *incomingFileName = [[incomingFilePath pathComponents] lastObject];
    
    DocumentViewController *viewController = [[[DocumentViewController alloc] 
                                               initWithNibName:kFDDocumentViewController_NibName bundle:[NSBundle mainBundle]] autorelease];
    
    NSDictionary *downloadInfo = [[FileDownloadManager sharedInstance] downloadInfoForFilename:incomingFileName];
    NSString *filename = incomingFileName;
    
    if (downloadInfo)
    {
        DownloadMetadata *fileMetadata = [[DownloadMetadata alloc] initWithDownloadInfo:downloadInfo];
        
        if (fileMetadata.key)
        {
            filename = fileMetadata.key;
        }
        [viewController setFileMetadata:fileMetadata];
        [viewController setCmisObjectId:fileMetadata.objectId];
        [viewController setContentMimeType:fileMetadata.contentStreamMimeType];
        [viewController setSelectedAccountUUID:fileMetadata.accountUUID];
        [viewController setTenantID:fileMetadata.tenantID];
        [fileMetadata release];
    }
    else
    {
        [viewController setIsDownloaded:YES];
    }
    
    NSData *fileData = [NSData dataWithContentsOfFile:incomingFilePath];
    [viewController setFileName:filename];
	[viewController setFileData:fileData];
	[viewController setHidesBottomBarWhenPushed:YES];
    
	if (tabBarIndex >= 0 && [[self tabBarController] selectedIndex] != tabBarIndex)
    {
        [[self tabBarController] setSelectedIndex:tabBarIndex];
        UINavigationController *navController = (UINavigationController *)[[self tabBarController] selectedViewController];
        [navController popToRootViewControllerAnimated:NO];
        
        [IpadSupport clearDetailController];
    }
    
	[IpadSupport pushDetailController:viewController withNavigation:self.navigationController andSender:self];
}

- (BOOL)updateRepositoryNode:(DownloadMetadata *)fileMetadata fileURLToUpload:(NSURL *)fileURLToUpload
{
    return [self updateRepositoryNode:fileMetadata fileURLToUpload:fileURLToUpload withFileName:nil];
}

- (BOOL)updateRepositoryNode:(DownloadMetadata *)fileMetadata fileURLToUpload:(NSURL *)fileURLToUpload withFileName:(NSString *)useFileName
{
    NSString *filePath = [fileURLToUpload path];
    
    // if we're given a "useFileName" then move the document to the new name
    if (useFileName != nil)
    {
        NSString *oldPath = [fileURLToUpload path];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        filePath = [FileUtils pathToTempFile:useFileName];
        if ([fileManager fileExistsAtPath:filePath])
        {
            [fileManager removeItemAtPath:filePath error:NULL];
        }
        
        BOOL isFileMoved = [fileManager moveItemAtPath:oldPath toPath:filePath error:NULL];
        if (!isFileMoved)
        {
            NSLog(@"ERROR: Could not move %@ to %@", oldPath, filePath);
            filePath = [fileURLToUpload path];
        }
    }
    
    NSLog(@"updating file at %@ to nodeRef: %@", filePath, fileMetadata.objectId);
    
    // extract node id from object id
	NSString *fileName = [[filePath pathComponents] lastObject];
    NSArray *idSplit = [fileMetadata.objectId componentsSeparatedByString:@"/"];
    NSString *nodeId = [idSplit objectAtIndex:3];
    
    // build CMIS setContent PUT request
    NSString *mimeType = fileMetadata.contentStreamMimeType;
    NSData *documentData = nil;
    if ([mimeType isEqualToString:@"text/plain"])
    {
        // make sure we read the text files using their current encoding
        NSString *fileContents = [NSString stringWithContentsOfFile:filePath usedEncoding:NULL error:NULL];
        documentData = [fileContents dataUsingEncoding:NSUTF8StringEncoding];
    }
    else
    {
        documentData = [NSData dataWithContentsOfFile:filePath];
    }
    
    AlfrescoUtils *alfrescoUtils = [AlfrescoUtils sharedInstanceForAccountUUID:fileMetadata.accountUUID];
    NSURL *putLink = nil;
    if (fileMetadata.tenantID == nil)
    {
        putLink = [alfrescoUtils setContentURLforNode:nodeId];
    }
    else
    {
        putLink = [alfrescoUtils setContentURLforNode:nodeId tenantId:fileMetadata.tenantID];
    }
    
    NSLog(@"putLink = %@", putLink);
    
    NSString *putBody  = [NSString stringWithFormat:@""
                          "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>"
                          "<entry xmlns=\"http://www.w3.org/2005/Atom\" xmlns:app=\"http://www.w3.org/2007/app\" xmlns:cmisra=\"http://docs.oasis-open.org/ns/cmis/restatom/200908/\">"
                          "<cmisra:content>"
                          "<cmisra:mediatype>%@</cmisra:mediatype>"
                          "<cmisra:base64>%@</cmisra:base64>"
                          "</cmisra:content>"
                          "<title>%@</title>"
                          "</entry>",
                          mimeType,
                          [documentData base64EncodedString],
                          fileName
                          ];
    
    // upload the updated content to the repository showing progress
    self.postProgressBar = [PostProgressBar createAndStartWithURL:putLink
                                                      andPostBody:putBody
                                                         delegate:self 
                                                          message:NSLocalizedString(@"postprogressbar.update.document", @"Updating Document")
                                                      accountUUID:fileMetadata.accountUUID
                                                    requestMethod:@"PUT" 
                                                    supressErrors:YES];
    self.postProgressBar.fileData = [NSURL fileURLWithPath:filePath];
    
    return YES;
}

- (NSString *)applicationDocumentsDirectory
{
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (BOOL)usingFlurryAnalytics
{
    NSString *flurryKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FlurryAPIKey"];
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

    [[AccountManager sharedManager] saveAccounts:[NSMutableArray array]];
    
    if ([self setupDefaultAccounts]) 
    {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kMultiAccountSetup];
        
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
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

- (BOOL)isFirstLaunchOfThisAppVersion
{
    // Return whether this is the first time this particular version of the app has been launched
    BOOL isFirstLaunch = NO;
    NSString *bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    NSString *appFirstStartOfVersionKey = [NSString stringWithFormat:@"first_launch_%@", bundleVersion];
    NSNumber *alreadyStartedOnVersion = [[NSUserDefaults standardUserDefaults] objectForKey:appFirstStartOfVersionKey];
    if ((!alreadyStartedOnVersion || [alreadyStartedOnVersion boolValue] == NO) || DEBUG_MIGRATION)
    {
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
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:appFirstStartOfVersionKey];
    }
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
    else if (alertView.tag == kAlertUpdateFailedTag)
    {
        if (buttonIndex == 1)
        {
            // copy the edited file to the Documents folder
            if ([FileUtils saveTempFile:updatedFileName withName:updatedFileName])
            {
                NSString *savedFilePath = [FileUtils pathToSavedFile:updatedFileName];
                [self displayContentsOfFileWithURL:[[[NSURL alloc] initFileURLWithPath:savedFilePath] autorelease] setActiveTabBar:3];
            }
            else
            {
                NSLog(@"Failed to save the edited file %@ to Documents folder", updatedFileName);
                
                [[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"savetodocs.alert.title", @"Save Failed") 
                                             message:NSLocalizedString(@"savetodocs.alert.description", @"Failed to save the edited file to Downloads")
                                            delegate:nil 
                                   cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK") 
                                   otherButtonTitles:nil, nil] autorelease] show];
            }
            
            // release the updatedFileUrl
            [updatedFileName release];
        }
    }
}

#pragma mark -
#pragma mark Global notifications
//This will only be called if the user preferences related to the repository connection changed.
- (void)defaultsChanged:(NSNotification *)notification {
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
#pragma mark PostProgressBarDelegate
- (void) post:(PostProgressBar *)bar completeWithData:(NSData *)data
{
    if (data != nil)
    {
        NSURL *url = (NSURL *)data;
        NSLog(@"URL: %@", url);
        [self displayContentsOfFileWithURL:url];
    }
}

- (void) post:(PostProgressBar *)bar failedWithData:(NSData *)data
{
    if (data != nil)
    {
        NSURL *url = (NSURL *)data;
        NSLog(@"URL: %@", url);
        
        // save the URL so the prompt delegate can access it
        updatedFileName = [[[[url pathComponents] lastObject] copy] retain];
        
        // TODO: show error about authentication and prompt user to save to downloads area
        UIAlertView *failurePrompt = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"updatefailed.alert.title", @"Save Failed") 
                                                                message:NSLocalizedString(@"updatefailed.alert.confirm", @"Do you want to save the file to the Downloads folder?") 
                                                               delegate:self 
                                                      cancelButtonTitle:NSLocalizedString(@"No", @"No") 
                                                      otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil];
        [failurePrompt setTag:kAlertUpdateFailedTag];
        [failurePrompt show];
        [failurePrompt release];
    }
}

#pragma mark -
#pragma mark Misc Migration
- (void)migrateApp {
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"migration.DownloadMetadata"])
        [self migrateMetadataFile];
    
    NSDictionary *allPreferences = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
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
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"migration.DownloadMetadata"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end

