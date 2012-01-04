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
//  AppProperties.h
//

#import <Foundation/Foundation.h>

//About Property Keys
extern NSString * const kAClientUrl;
extern NSString * const kAUseGradient;

//Browse Property Keys
extern NSString * const kBShowSettingsButton;
extern NSString * const kBShowAddButton;
extern NSString * const kBShowMetadataDisclosure;
extern NSString * const kBUseRelativeDate;
extern NSString * const kBShowDownloadFolderButton;
extern NSString * const kBAllowHideActivities;
//Downloads the whole folder tree if YES or just the current folder if NO
extern NSString * const kBDownloadFolderTree;

//Document Preview Property Keys
extern NSString * const kPShowCommentButton;
extern NSString * const kPShowLikeButton;
extern NSString * const kPShowCommentButtonBadge;

//More View Property keys
extern NSString * const kMShowSimpleSettings;

extern NSString * const kDShowMetadata;

extern NSString * const kDefaultTabbarSelection;

extern NSString * const kUUseJPEG;

extern NSString * const kAlfrescoMeSignupLink;

@interface AppProperties : NSObject
+ (id) propertyForKey:(NSString*) key;
@end
