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
//  CMISServiceManager.h
//
// Singleton class used to centralize the use of the ServiceDocumentRequest and TenantsHTTPRequest
// and support to multi accounts. It provides a clean and unified interface if you want to access a service
// document wheather you want to load, reload or just access the cached service document (already requested)
// of a normal server account or cloud account.

#import <Foundation/Foundation.h>
#import "ASINetworkQueue.h"
@class CMISServiceManager;
@class ServiceDocumentRequest;


extern NSString * const kCMISServiceManagerErrorDomain;

/**
 * As a Listener for this class you can listen for a request (specific to an account UUID) finish and/or the whole queue to run.
 * If listening for a given request you have to make sure to check if the request is the one that you expect
 * since is not guaranteed to make one call to the listeners even if the operation called it involves only one request.
 */
@protocol CMISServiceManagerListener
@optional
//Queue requests
- (void)serviceManagerRequestsFinished:(CMISServiceManager *)serviceManager;
- (void)serviceManagerRequestsFailed:(CMISServiceManager *)serviceManager;
//Individual requests
- (void)serviceDocumentRequestFinished:(ServiceDocumentRequest *)serviceRequest;
- (void)serviceDocumentRequestFailed:(ServiceDocumentRequest *)serviceRequest;
@end


@interface CMISServiceManager : NSObject
{
@private
    BOOL _showOfflineAlert;
    NSMutableSet *_accountsRunning;
}
@property (nonatomic, retain) ASINetworkQueue *networkQueue;
@property (nonatomic, assign) BOOL servicesLoaded;
@property (nonatomic, retain) NSError *error;
@property (nonatomic, retain) NSMutableSet *accountsRunning;
@property (nonatomic, assign) BOOL isRequestForExpiredFiles;

/**
 * This will remove the listener from both listeners list in the singleton.
 * This means that you will not have to call manually the removeQueueListener: and the removeListener:forAccountUuid:
 */
- (void)removeAllListeners:(id<CMISServiceManagerListener>)aListner;

/**
 * Adds a new listener that wants to know if a service document request finished or failed for a given account UUID.
 */
- (void)addListener:(id<CMISServiceManagerListener>) newListener forAccountUuid:(NSString *)uuid;
/**
 * Removes the individual request listener from the singleton.
 */
- (void)removeListener:(id<CMISServiceManagerListener>) newListener forAccountUuid:(NSString *)uuid;

/**
 * Adds a new queue listener that will get called after any network queue request finishes
 */
- (void)addQueueListener:(id<CMISServiceManagerListener>) newListener;
/**
 * Removes the queue listener from the singleton.
 */
- (void)removeQueueListener:(id<CMISServiceManagerListener>) newListener;

/**
 * Will try to retrieve all the service documents cached. If they're not cached it will make the
 * ServiceDocumentRequest or TenantsHTTPRequest to load them and cache.
 * This will always result on a call to the queue listener and to the individual listeners for the accounts that were not caches
 */
- (void)loadAllServiceDocuments;
/**
 * Will try to retrieve all the service documents cached. If they're not cached it will make the
 * ServiceDocumentRequest or TenantsHTTPRequest to load them and cache only if the account has complete credentials.
 * This will always result on a call to the queue listener and to the individual listeners for the accounts that were not caches
 */
- (void)loadAllServiceDocumentsWithCredentials;
/**
 * Will always call the ServiceDocumentRequest or TenantsHTTPRequest to load them and cache.
 * This will always result on a call to the queue listener and to the individual listeners
 */
- (void)reloadAllServiceDocuments;

/**
 * Will try to retrieve a given account's service documents cached. If it's not cached it will make the
 * ServiceDocumentRequest or TenantsHTTPRequest to load it and cache.
 * This will always result on a call to the queue listener and to the individual listeners
 */
- (void)loadServiceDocumentForAccountUuid:(NSString *)uuid;
/**
 * Will always call the ServiceDocumentRequest or TenantsHTTPRequest to load the service document and cache it.
 * This will always result on a call to the queue listener and to the individual listeners
 */
- (void)reloadServiceDocumentForAccountUuid:(NSString *)uuid;

/**
 * Deletes the service document cached for a given account
 */
- (void)deleteServiceDocumentForAccountUuid:(NSString *)uuid;

- (BOOL)isActive;

/**
 * Returns the shared singleton
 */
+ (id)sharedManager;

@end
