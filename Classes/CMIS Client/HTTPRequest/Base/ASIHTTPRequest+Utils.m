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
//  ASIHTTPRequest+Utils.m
//

#import "ASIHTTPRequest+Utils.h"
#import "ASIDownloadCache.h"


@implementation ASIHTTPRequest (Utils)

- (void)useCacheIfEnabled {
    BOOL useRequestCache = [[FDKeychainUserDefaults standardUserDefaults] boolForKey:@"useDownloadCache"];
    if(useRequestCache) {
        AlfrescoLogDebug(@"Using cache for request url: %@", [self.url absoluteString]);
        [self setDownloadCache:[ASIDownloadCache sharedCache]];
    } else {
        [self setDownloadCache:nil];
    }
    
}

// We clear the current Cache in the case the user switched preference
+ (void)setDefaultCacheIfEnabled {
    BOOL useRequestCache = [[FDKeychainUserDefaults standardUserDefaults] boolForKey:@"useDownloadCache"];
    
    if(useRequestCache) {
        AlfrescoLogDebug(@"Enabling caching for all requests");
        // Default policy ASIAskServerIfModifiedWhenStaleCachePolicy is fine
        [ASIHTTPRequest setDefaultCache:[ASIDownloadCache sharedCache]];
    } else {
        [ASIHTTPRequest setDefaultCache:nil];
        //We clear the cache since the user disabled the download cache
        [[ASIDownloadCache sharedCache] clearCachedResponsesForStoragePolicy:ASICacheForSessionDurationCacheStoragePolicy];
    }
}

@end
