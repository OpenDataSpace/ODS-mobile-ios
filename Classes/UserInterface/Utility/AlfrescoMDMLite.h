//
//  AlfrescoMDMLite.h
//  FreshDocs
//
//  Created by Mohamad Saeedi on 18/12/2012.
//
//

#import <Foundation/Foundation.h>
#import "CMISMDMRequest.h"
#import "ASINetworkQueue.h"
#import "CMISServiceManager.h"

@class AlfrescoMDMLite;

@protocol AlfrescoMDMLiteDelegate <NSObject>
@optional
- (void)mdmLiteRequestFinished:(AlfrescoMDMLite *)mdmManager forItems:(NSArray*)items;
@end

@protocol AlfrescoMDMServiceManagerDelegate <NSObject>
@optional
- (void)mdmServiceManagerRequestFinsished:(AlfrescoMDMLite *)mdmManager withSuccess:(BOOL)success;
@end

@interface AlfrescoMDMLite : NSObject <CMISServiceManagerListener>

@property (nonatomic, retain) ASINetworkQueue *requestQueue;
@property (nonatomic, assign) id<AlfrescoMDMLiteDelegate> delegate;
@property (nonatomic, assign) id<AlfrescoMDMServiceManagerDelegate> serviceDelegate;

- (BOOL)isRestrictedDownload:(NSString*)fileName;
- (BOOL)isRestrictedSync:(NSString*) fileName;

- (BOOL)isDownloadExpired:(NSString*)fileName withAccountUUID:(NSString*)accountUUID;
- (BOOL)isSyncExpired:(NSString*)fileName withAccountUUID:(NSString*)accountUUID;

- (void)loadMDMInfo:(NSArray*)nodes withAccountUUID:(NSString*)accountUUID andTenantId:(NSString*)tenantID;
- (void)loadRepositoryInfoForAccount:(NSString*)accountUUID;

+ (AlfrescoMDMLite *)sharedInstance;

@end
