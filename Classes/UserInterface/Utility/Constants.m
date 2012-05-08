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
//  Constants.m
//

#import "Constants.h"

NSString * const kDetailViewControllerChangedNotification = @"detailViewControllerChanged";
NSString * const kUserPreferencesChangedNotification = @"userPreferencesChangedNotification";
NSString * const kKeychainUserDefaultsDidChangeNotification = @"keychainUserDefaultsDidChangeNotification";

NSString * const kNotificationAccountWasUpdated = @"kNotificationAccountWasUpdated";
NSString * const kNotificationAccountListUpdated = @"kNotificationAccountListUpdated";

NSString * const kNotificationUploadFinished = @"kNotificationUploadFinished";
NSString * const kNotificationUploadFailed = @"kNotificationUploadFailed";
NSString * const kNotificationUploadQueueChanged = @"kNotificationUploadQueueChanged";


NSString * const kAccountUpdateNotificationEdit = @"edit";
NSString * const kAccountUpdateNotificationDelete = @"delete";
NSString * const kAccountUpdateNotificationAdd = @"add";
NSString * const kBrowseDocumentsNotification = @"browseDocuments";


NSString * const kFDDocumentViewController_NibName = @"DocumentViewController";
NSString * const kFDRootViewController_NibName = @"RootViewController";
NSString * const kFDHTTP_Protocol = @"http";
NSString * const kFDHTTPS_Protocol = @"https";
NSString * const kFDHTTP_DefaultPort = @"80";
NSString * const kFDHTTPS_DefaultPort = @"443";
NSString * const kFDAlfresco_RepositoryVendorName = @"Alfresco";

/**
 * The number of seconds to wait before showing a network activity progress dialog.
 * Currently used by the DownloadProgressBar and PostProgressBar controls.
 */
NSTimeInterval const kNetworkProgressDialogGraceTime = 0.6;

/**
 * The number of seconds that the first-run splash screen is displayed for.
 */
NSTimeInterval const kSplashScreenDisplayTime = 2.5;

/**
 * The number of seconds that the fade-in animation lasts when displaying documents.
 */
NSTimeInterval const kDocumentFadeInTime = 0.3;

/**
 * The number of seconds that the HUD will de displayed for.  
 * TODO: use this constant any where we display a 'HUD' or MBProgressHUD
 */
NSTimeInterval const kHUDMinShowTime = 0.7;

/**
 * The number of seconds that the invoked method may be run without 
 * showing the HUD. 
 * TODO: use this constant any where we display a 'HUD' or MBProgressHUD
 */
NSTimeInterval const KHUDGraceTime = 0.2;

/**
 * The default key for an account with no tenants
 */
NSString * const kDefaultTenantID = @"NoTenantID";

/**
 * The name of the images used in the UITableViewCells
 */
NSString * const kAboutMoreIcon_ImageName = @"about-more";
NSString * const kAccountsMoreIcon_ImageName = @"accounts-more";
NSString * const kCloudIcon_ImageName = @"cloud";
NSString * const kNetworkIcon_ImageName = @"network";
NSString * const kServerIcon_ImageName = @"server";
NSString * const kTwisterClosedIcon_ImageName = @"twister-closed";
NSString * const kTwisterOpenIcon_ImageName = @"twister-open";

/**
 * The folder name used in the app's Library folder to store the configuration files
 * like the DownloadMetadata
 */
NSString * const kFDLibraryConfigFolderName = @"AppConfiguration";

/**
 * The default UITableViewCell height
 */
CGFloat const kDefaultTableCellHeight = 60.0f;

NSString * const kDefaultAccountsPlist_FileName = @"DefaultAccounts";

NSString * const kFDSearchSelectedUUID = @"searchSelectedUUID";
NSString * const kFDSearchSelectedTenantID = @"searchSelectedTenantID";

@implementation Constants
@end
