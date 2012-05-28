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
//  AppProperties.h
//

#import <Foundation/Foundation.h>
#import "AccountInfo.h"

//About Property Keys
extern NSString * const kAClientUrl;
extern NSString * const kAUseGradient;

//Browse Property Keys
extern NSString * const kBShowSettingsButton;
extern NSString * const kBShowAddButton;
extern NSString * const kBShowMetadataDisclosure;
extern NSString * const kBUseRelativeDate;
extern NSString * const kBShowDownloadFolderButton;
extern NSString * const kBShowEditButton;
extern NSString * const kBAllowHideActivities;
//Downloads the whole folder tree if YES or just the current folder if NO
extern NSString * const kBDownloadFolderTree;

//Document Preview Property Keys
extern NSString * const kPShowCommentButton;
extern NSString * const kPShowLikeButton;
extern NSString * const kPShowCommentButtonBadge;

//More View Property keys
extern NSString * const kDShowMetadata;

extern NSString * const kDefaultTabbarSelection;

extern NSString * const kUUseJPEG;

extern NSString * const kAlfrescoMeSignupLink;
extern NSString * const kAlfrescoCloudTermsOfServiceUrl;
extern NSString * const kAlfrescoCloudPrivacyPolicyUrl;
extern NSString * const kAlfrescoCustomerCareUrl;

extern NSString * const kHomescreenShow;

extern NSString * const kHelpGuidesShow;

extern NSString * const kSplashscreenDisplayTimeKey;

//Data protection related propertyKeys
extern NSString * const kDPExcludedAccounts;

extern NSString * const kImageUploadSizingOptionDict;
extern NSString * const kImageUploadSizingOptionValues;
extern NSString * const kImageUploadSizingOptionDefault;

@interface AppProperties : NSObject
+ (id) propertyForKey:(NSString*) key;
/*
 Determines if the account supplied is excluded from the qualifying accounts for data protection.
 Since the demo account is an enterprise account we always try to offer data protection. We need to exlude the account for data protection
 */
+ (BOOL)isExcludedAccount:(AccountInfo *)accountInfo;
@end
