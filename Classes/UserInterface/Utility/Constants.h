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
//  Constants.h
//
//  This class has been include in the precompiled class header (FreshDocs.pch)
//  and therefore does not need to be included in any class files.
//

//
// General Notification Types
//
extern NSString * const kDetailViewControllerChangedNotification;
extern NSString * const kUserPreferencesChangedNotification;
extern NSString * const kKeychainUserDefaultsDidChangeNotification;

extern NSString * const kSyncPreferenceChangedNotification;
//
// Repo/AccountList Notification Types
//
extern NSString * const kNotificationAccountListUpdated;
extern NSString * const kNotificationAccountStatusChanged;

//
// Uploads Notification Types
//
extern NSString * const kNotificationUploadFinished;
extern NSString * const kNotificationUploadFailed;
extern NSString * const kNotificationUploadQueueChanged;
extern NSString * const kNotificationUploadStarted;
extern NSString * const kNotificationUploadWaiting;
extern NSString * const kNotificationFavoriteUploadCancelled;

//
// Favorite Uploads Notification Types
//
extern NSString * const kNotificationFavoriteUploadFinished;
extern NSString * const kNotificationFavoriteUploadFailed;
extern NSString * const kNotificationFavoriteUploadQueueChanged;
extern NSString * const kNotificationFavoriteUploadStarted;
extern NSString * const kNotificationFavoriteUploadWaiting;

//
// Downloads Notification Types
//
extern NSString * const kNotificationDownloadFinished;
extern NSString * const kNotificationDownloadFailed;
extern NSString * const kNotificationDownloadQueueChanged;
extern NSString * const kNotificationDownloadStarted;

//
// Repository Documents Notification Types
//
extern NSString * const kNotificationDocumentUpdated;

//
// Favorite Downloads Notification Types
//
extern NSString * const kNotificationFavoriteDownloadFinished;
extern NSString * const kNotificationFavoriteDownloadFailed;
extern NSString * const kNotificationFavoriteDownloadQueueChanged;
extern NSString * const kNotificationFavoriteDownloadStarted;
extern NSString * const kNotificationFavoriteDownloadCancelled;

//
// Account Notification Types
//
extern NSString * const kAccountUpdateNotificationEdit;
extern NSString * const kAccountUpdateNotificationDelete;
extern NSString * const kAccountUpdateNotificationAdd;
extern NSString * const kAccountUpdateNotificationAllAccounts;
extern NSString * const kBrowseDocumentsNotification;
extern NSString * const kLastAccountDetailsNotification;

//
// Task notification types
//
extern NSString * const kNotificationTaskCompleted;

//
// General Purpose Constants
//
extern NSString * const kFDDocumentViewController_NibName;
extern NSString * const kFDRootViewController_NibName;
extern NSString * const kFDHTTP_Protocol;
extern NSString * const kFDHTTPS_Protocol;
extern NSString * const kFDHTTP_DefaultPort;
extern NSString * const kFDHTTPS_DefaultPort;
extern NSString * const kFDAlfresco_RepositoryVendorName;

extern NSTimeInterval const kNetworkProgressDialogGraceTime;
extern NSTimeInterval const kDocumentFadeInTime;
extern NSTimeInterval const kHUDMinShowTime;
extern NSTimeInterval const KHUDGraceTime;

extern NSString * const kDefaultTenantID;


/**
 * The name of the images used in the UITableViewCells
 */
extern NSString * const kAboutMoreIcon_ImageName;
extern NSString * const kAccountsMoreIcon_ImageName;
extern NSString * const kCloudIcon_ImageName;
extern NSString * const kDownloadsMoreIcon_ImageName;
extern NSString * const kHelpGuideIcon_ImageName;
extern NSString * const kHelpMoreIcon_ImageName;
extern NSString * const kNetworkIcon_ImageName;
extern NSString * const kSearchMoreIcon_ImageName;
extern NSString * const kServerIcon_ImageName;
extern NSString * const kSettingsMoreIcon_ImageName;
extern NSString * const kTwisterClosedIcon_ImageName;
extern NSString * const kTwisterOpenIcon_ImageName;
extern NSString * const kImageUIButtonBarBadgeError;

/**
 * Sync Favorites Preference
 */
extern NSString * const kSyncPreference;
extern NSString * const kSyncedFilesDirectory;
extern NSString * const kSyncOnCellular;

extern NSString * const kNotificationDocumentFavoritedOrUnfavorited;
extern NSString * const kNotificationSyncObstacles;

extern NSTimeInterval const kSyncAfterDelay;

extern NSString * const kFDLibraryConfigFolderName;

extern CGFloat const kDefaultTableCellHeight;
extern CGFloat const kTableCellTextLeftPadding;

extern NSString * const kDefaultAccountsPlist_FileName;

/**
 * MDMLite
 */
extern NSString * const kMDMAspectKey;
extern NSString * const kFileExpiryKey;
// Custom Notifications
extern NSString * const kNotificationExpiredFiles;
extern NSString * const kNotificationViewedDocumentRestrictionStatus;

/**
 * User Preferences name constants
 * Search
 */
extern NSString * const kFDSearchSelectedUUID;
extern NSString * const kFDSearchSelectedTenantID;
extern NSString * const kFDSearchSelectedGuid;
extern NSString * const kFDSearchSelectedTitle;

/**
 * CMIS Request Constants
 */
extern NSString * const kCMISDefaultPropertyFilterValue;
extern NSString * const kCMISExtendedPropertyFilterValue;

/**
 * Create Document Constants
 */
extern NSString * const kCreateDocumentTemplateFilename;
extern NSString * const kCreateDocumentDocExtension;
extern NSString * const kCreateDocumentPresentationExtension;
extern NSString * const kCreateDocumentSpreadsheetExtension;
extern NSString * const kCreateDocumentTextExtension;

/**
 * The number of file suffixes that are tried to avoid file overwrites
 */
extern unsigned int const kFileSuffixMaxAttempts;

/**
 * Alfresco Site visibility
 */
extern NSString * const kSiteVisibilityPublic;
extern NSString * const kSiteVisibilityPrivate;
extern NSString * const kSiteVisibilityModerated;

/**
 * Workflow Constants
 */
extern NSString * const kActivitiWorkflowIdPrefix;
extern NSString * const kJBPMWorkflowIdPrefix;

/**
 * System Preference Keys
 */
extern NSString * const kPreferenceApplicationFirstRun;

@interface Constants : NSObject
@end
