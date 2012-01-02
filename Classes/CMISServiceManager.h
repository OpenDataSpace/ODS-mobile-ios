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
//  CMISServiceManager.h
//

#import <Foundation/Foundation.h>
#import "ASINetworkQueue.h"
@class CMISServiceManager;
@class ServiceDocumentRequest;


extern NSString * const kCMISServiceManagerErrorDomain;


@protocol CMISServiceManagerListener
@optional
//queue requests
- (void)serviceManagerRequestsFinished:(CMISServiceManager *)serviceManager;
- (void)serviceManagerRequestsFailed:(CMISServiceManager *)serviceManager;
//Individual requests
- (void)serviceDocumentRequestFinished:(ServiceDocumentRequest *)serviceRequest;
- (void)serviceDocumentRequestFailed:(ServiceDocumentRequest *)serviceRequest;
@end


@interface CMISServiceManager : NSObject
{
@private
    ASINetworkQueue *_networkQueue;
    BOOL _servicesLoaded;
    NSError *_error;
    NSMutableDictionary *_cachedTenantIDDictionary;    
    NSMutableDictionary *_listeners;
    BOOL _showOfflineAlert;
}
@property (nonatomic, retain) ASINetworkQueue *networkQueue;
@property (nonatomic, assign) BOOL servicesLoaded;
@property (nonatomic, retain) NSError *error;


- (void)removeAllListeners:(id<CMISServiceManagerListener>)aListner;

- (void)addListener:(id<CMISServiceManagerListener>) newListener forAccountUuid:(NSString *)uuid;
- (void)removeListener:(id<CMISServiceManagerListener>) newListener forAccountUuid:(NSString *)uuid;

- (void)addQueueListener:(id<CMISServiceManagerListener>) newListener;
- (void)removeQueueListener:(id<CMISServiceManagerListener>) newListener;

//will only request the serviceDocuments for the repositories not already loaded
- (void)loadAllServiceDocuments;
//will perform a full reload of the repositories and clears first the
- (void)reloadAllServiceDocuments;

//Lazy loading for the service documents
//Requests the service document for a given account if not already loaded
- (void)loadServiceDocumentForAccountUuid:(NSString *)uuid;
//Will always request the service document for a given account
- (void)reloadServiceDocumentForAccountUuid:(NSString *)uuid;

- (void)deleteServiceDocumentForAccountUuid:(NSString *)uuid;

+ (id)sharedManager;

@end
