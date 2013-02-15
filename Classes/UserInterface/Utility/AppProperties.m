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
NSString * const kALicenses = @"about.licenses";

NSString * const kBShowAddButton = @"browse.showAddButton";
NSString * const kBShowMetadataDisclosure = @"browse.showMetadataDisclosure";
NSString * const kBUseRelativeDate = @"browse.useRelativeDate";
NSString * const kBShowDownloadFolderButton = @"browse.showDownloadButton";
NSString * const kBShowEditButton = @"browse.showEditButton";
NSString * const kBAllowHideActivities = @"settings.allowHideActivities";
NSString * const kBDownloadFolderTree =  @"browse.downloadFolderTree";

NSString * const kPShowCommentButton = @"preview.showCommentButton";
NSString * const kPShowLikeButton = @"preview.showLikeButton";
NSString * const kPShowCommentButtonBadge = @"preview.showCommentButtonBadge";

NSString * const kDShowMetadata = @"downloads.showMetadata";

NSString * const kDefaultTabbarSelection = @"default.tabbar.selection";

NSString * const kUUseJPEG = @"upload.useJPEG";

NSString * const kAlfrescoMeSignupLink = @"alfrescome.signupLink";
NSString * const kAlfrescoCloudTermsOfServiceUrl = @"alfrescocloud.termOfServices.url";
NSString * const kAlfrescoCloudPrivacyPolicyUrl = @"alfrescocloud.privacyPolicy.url";
NSString * const kAlfrescoCustomerCareUrl = @"alfrescocloud.customerCare.url";
NSString * const kAlfrescoCloudHostname = @"alfrescocloud.hostname";

NSString * const kHomescreenShow = @"homescreen.show";

NSString * const kAccountsDefaultVendor = @"accounts.defaultVendor";
NSString * const kAccountsVendors = @"accounts.vendors";
NSString * const kAccountsAllowCloudAccounts = @"acccounts.allowCloudAccounts";
NSString * const kHelpGuidesShow = @"helpGuides.show";

NSString * const kSplashscreenDisplayTimeKey = @"splashscreen.displayTime";
NSString * const kSplashscreenShowKey = @"splashscreen.show";

NSString * const kDPExcludedAccounts = @"dataProtection.excludedAccounts";

NSString * const kImageUploadSizingOptionDict = @"ImageUploadSizingOptionDict";
NSString * const kImageUploadSizingOptionValues = @"ImageUploadSizingOptionValues";
NSString * const kImageUploadSizingOptionDefault = @"ImageUploadSizingOptionDefault";

NSString * const kDevelopmentAllVersions = @"development.allVersions";
NSString * const kDevelopmentVersion13 = @"development.version.1.3";

@implementation AppProperties

+ (void)initialize
{
    if (!plist)
    {
        NSString *path = [[NSBundle mainBundle] pathForResource:kAppFile ofType:@"plist"];
        plist = [[NSDictionary alloc] initWithContentsOfFile:path];
    }
}

+ (id)propertyForKey:(NSString *)key
{
    id property = [plist objectForKey:key];
    
    if (nil == property)
    {
        alfrescoLog(AlfrescoLogLevelTrace, @"Tried to acces property %@ but not found. Check the %@ file.",key,kAppFile);
    }
    else
    {
        alfrescoLog(AlfrescoLogLevelTrace, @"Property %@ found with value: %@",key, property);
    }
    
    return property;
}

+ (BOOL)isExcludedAccount:(AccountInfo *)accountInfo
{
    NSArray *excludedAccounts = [self propertyForKey:kDPExcludedAccounts];
    for (NSDictionary *excluded in excludedAccounts)
    {
        NSString *username = [excluded objectForKey:@"username"];
        NSString *hostname = [excluded objectForKey:@"hostname"];
        NSString *port = [excluded objectForKey:@"port"];
        NSString *serviceDocument = [excluded objectForKey:@"serviceDocument"];
        
        if ([accountInfo.username isEqualToString:username] && [accountInfo.hostname isEqualToString:hostname] && [accountInfo.port isEqualToString:port] && [accountInfo.serviceDocumentRequestPath isEqualToString:serviceDocument])
        {
            return YES;
        }
    }
    
    return NO;
}

@end
