//
//  AlfrescoMDMLite.h
//  FreshDocs
//
//  Created by Mohamad Saeedi on 18/12/2012.
//
//

#import <Foundation/Foundation.h>

@interface AlfrescoMDMLite : NSObject

- (BOOL)isRestrictedDownload:(NSString*)fileName;
- (BOOL)isRestrictedSync:(NSString*) fileName;

- (BOOL)isDownloadExpired:(NSString*)fileName;
- (BOOL)isSyncExpired:(NSString*)fileName;

+ (AlfrescoMDMLite *)sharedInstance;

@end
