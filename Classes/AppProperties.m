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
//  AppProperties.m
//

#import "AppProperties.h"

static NSDictionary *plist = nil;
NSString * const kAppFile = @"App";
NSString * const kAClientUrl = @"about.clientUrl";
NSString * const kAUseGradient = @"about.background.useGradient";

NSString * const kBShowSettingsButton = @"showSettings";
NSString * const kBShowAddButton = @"browse.showAddButton";
NSString * const kBShowMetadataDisclosure = @"browse.showMetadataDisclosure";
NSString * const kBUseRelativeDate = @"browse.useRelativeDate";
NSString * const kBShowDownloadFolderButton = @"browse.showDownloadButton";
NSString * const kBAllowHideActivities = @"settings.allowHideActivities";
NSString * const kBDownloadFolderTree =  @"browse.downloadFolderTree";

NSString * const kPShowCommentButton = @"preview.showCommentButton";
NSString * const kPShowLikeButton = @"preview.showLikeButton";
NSString * const kPShowCommentButtonBadge = @"preview.showCommentButtonBadge";


NSString * const kMShowSimpleSettings = @"more.showSimpleSettings";

NSString * const kDShowMetadata = @"downloads.showMetadata";

NSString * const kDefaultTabbarSelection = @"default.tabbar.selection";

NSString * const kUUseJPEG = @"upload.useJPEG";

NSString * const kAlfrescoMeSignupLink = @"alfrescome.signupLink";
NSString * const kAlfrescoCloudTermsOfServiceUrl = @"alfrescocloud.termOfServices.url";
NSString * const kAlfrescoCloudPrivacyPolicyUrl = @"alfrescocloud.privacyPolicy.url";
NSString * const kAlfrescoCustomerCareUrl = @"alfrescocloud.customerCare.url";

NSString * const kHomescreenShow = @"homescreen.show";

@implementation AppProperties

+ (void)initialize {
    if (!plist) {
        NSString *path = [[NSBundle mainBundle] pathForResource:kAppFile ofType:@"plist"];
        plist = [[NSDictionary alloc] initWithContentsOfFile:path];
    }
}

+ (id) propertyForKey:(NSString *)key {
    id property = [plist objectForKey:key];
    
#if MOBILE_DEBUG
    if(nil == property) {
        NSLog(@"Tried to acces property %@ but not found. Check the %@ file.",key,kAppFile);
    } else {
        NSLog(@"Property %@ found with value: %@",key, property);
    }
#endif
    
    return property;
}

@end
