//
//  ServiceInfo.h
//  FreshDocs
//
//  Created by Michael Muller on 4/29/10.
//  Copyright 2010 Michael J Muller. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ServiceInfo : NSObject {
}

- (BOOL)isPreReleaseCmis;

- (NSString *) lastModifiedByPropertyName;
- (NSString *) lastModificationDatePropertyName;
- (NSString *) baseTypeIdPropertyName;
- (NSString *) objectIdPropertyName;
- (NSString *) contentStreamLengthPropertyName;

- (BOOL)isAtomNamespace:(NSString *)namespace;
- (BOOL)isAtomPubNamespace:(NSString *)namespace;
- (BOOL)isCmisNamespace:(NSString *)namespace;
- (BOOL)isCmisRestAtomNamespace:(NSString *)namespace;

- (NSString *)cmisPropertyIdAttribute;

- (NSString *)hostURL;
- (NSURL *)serviceDocumentURL;

- (NSURL *)childrenURLforNode: (NSString*)node;

+ (ServiceInfo*)sharedInstance;
+ (id)allocWithZone:(NSZone *)zone;
- (id)copyWithZone:(NSZone *)zone;

@end
