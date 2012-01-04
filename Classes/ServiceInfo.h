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
//  ServiceInfo.h
//

#import <Foundation/Foundation.h>
#import "RepositoryInfo.h"

@interface ServiceInfo : NSObject {
    NSString *accountUUID;
}

- (NSString *) lastModifiedByPropertyName;
- (NSString *) lastModificationDatePropertyName;
- (NSString *) baseTypeIdPropertyName;
- (NSString *) objectIdPropertyName;
- (NSString *) contentStreamLengthPropertyName;
- (NSString *) versionSeriesIdPropertyName;

- (BOOL)isAtomNamespace:(NSString *)namespace;
- (BOOL)isAtomPubNamespace:(NSString *)namespace;
- (BOOL)isCmisNamespace:(NSString *)namespace;
- (BOOL)isCmisRestAtomNamespace:(NSString *)namespace;

- (NSString *)cmisPropertyIdAttribute;

- (NSString *)hostURL;
- (NSURL *)serviceDocumentURL;

- (NSURL *)childrenURLforNode: (NSString*)node;
- (NSURL *)setContentURLforNode: (NSString*)nodeId;
- (NSURL *)setContentURLforNode: (NSString*)nodeId tenantId:(NSString *)tenantId;

- (id)initWithAccountUUID:(NSString *)uuid;
+ (ServiceInfo *)sharedInstanceForAccountUUID:(NSString *)uuid;
- (id)copyWithZone:(NSZone *)zone;

@end
