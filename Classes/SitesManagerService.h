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
//  SitesManagerService.h
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"
#import "AsynchonousDownload.h"

@class SitesManagerService;
@class SiteListDownload;
@class FavoritesSitesHttpRequest;

@protocol SitesManagerListener <NSObject>

-(void)siteManagerFinished:(SitesManagerService *)siteManager;
-(void)siteManagerFailed:(SitesManagerService *)siteManager;

@end

@interface SitesManagerService : NSObject <AsynchronousDownloadDelegate, ASIHTTPRequestDelegate> {
    NSArray *allSites;
    NSArray *mySites;
    NSArray *favoriteSites;
    NSArray *favoriteSiteNames;
    SiteListDownload *allSitesRequest; // !!!: Change back to CMISGetSites
    SiteListDownload *mySitesRequest;
    FavoritesSitesHttpRequest *favoriteSitesRequest;
    
    BOOL hasResults;
    BOOL isExecuting;
    
    NSMutableSet *listeners;
}
@property (nonatomic, retain) NSArray *allSites;
@property (nonatomic, retain) NSArray *mySites;
@property (nonatomic, retain) NSArray *favoriteSites;
@property (nonatomic, retain) NSArray *favoriteSiteNames;
@property (nonatomic, retain) SiteListDownload *allSitesRequest;
@property (nonatomic, retain) SiteListDownload *mySitesRequest;
@property (nonatomic, retain) FavoritesSitesHttpRequest *favoriteSitesRequest;

@property (nonatomic, readonly) BOOL hasResults;
@property (nonatomic, readonly) BOOL isExecuting;

-(void)addListener:(id<SitesManagerListener>)newListener;
-(void)removeListener:(id<SitesManagerListener>)newListener;
//Will perform all the needed requests to retrieve the sites
-(void)startOperations;

//Used to signal the siteManager that the current results are no longer valid
-(void)invalidateResults;

-(void)cancelOperations;

+ (SitesManagerService *)sharedInstance;
@end
