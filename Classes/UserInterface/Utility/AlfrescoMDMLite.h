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
@class AlfrescoMDMLite;

@protocol AlfrescoMDMLiteDelegate <NSObject>
@optional
- (void)mdmLiteRequestFinished:(AlfrescoMDMLite *)mdmManager forItems:(NSArray*)items;
@end

@interface AlfrescoMDMLite : NSObject

@property (nonatomic, retain) ASINetworkQueue *requestQueue;
@property (nonatomic, assign) id<AlfrescoMDMLiteDelegate> delegate;

- (BOOL)isRestrictedDownload:(NSString*)fileName;
- (BOOL)isRestrictedSync:(NSString*) fileName;

- (BOOL)isDownloadExpired:(NSString*)fileName;
- (BOOL)isSyncExpired:(NSString*)fileName;

- (void)loadMDMInfo:(NSArray*)nodes withAccountUUID:(NSString*)accountUUID andTenantId:(NSString*)tenantID;

+ (AlfrescoMDMLite *)sharedInstance;

@end
