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
//  ServiceInfo.m
//

#import "ServiceInfo.h"
#import "Utility.h"
#import "NSString+Trimming.h"
#import "RepositoryServices.h"

static ServiceInfo *sharedInstance = nil;

@implementation ServiceInfo

- (void) dealloc {
	[super dealloc];
}

#pragma mark -
#pragma mark class instance methods

- (BOOL)isAtomNamespace:(NSString *)namespace
{
	return [[namespace stringWithTrailingSlashRemoved] isEqualToString:@"http://www.w3.org/2005/Atom"];
}

- (BOOL)isAtomPubNamespace:(NSString *)namespace
{
	return [[namespace stringWithTrailingSlashRemoved] isEqualToString:@"http://www.w3.org/2007/app"];
}

- (BOOL)isCmisNamespace:(NSString *)namespace
{
	return [namespace hasPrefix:@"http://docs.oasis-open.org/ns/cmis/core"];
}

- (BOOL)isCmisRestAtomNamespace:(NSString *)namespace
{
	return [[namespace stringWithTrailingSlashRemoved] isEqualToString:@"http://docs.oasis-open.org/ns/cmis/restatom/200908"];
}

- (NSString *)cmisPropertyIdAttribute
{
	return [self isPreReleaseCmis] ? @"cmis:name" : @"propertyDefinitionId";
}

- (NSString *) lastModifiedByPropertyName
{
	return [self isPreReleaseCmis] ? @"LastModifiedBy" : @"cmis:lastModifiedBy";
}

- (NSString *) lastModificationDatePropertyName
{
	return [self isPreReleaseCmis] ? @"LastModificationDate" : @"cmis:lastModificationDate";
}

- (NSString *) baseTypeIdPropertyName
{
	return [self isPreReleaseCmis] ? @"BaseType" : @"cmis:baseTypeId";
}

- (NSString *) objectIdPropertyName
{
	return [self isPreReleaseCmis] ? @"ObjectId" : @"cmis:objectId";
}

- (NSString *) contentStreamLengthPropertyName
{
	return [self isPreReleaseCmis] ? @"ContentStreamLength" : @"cmis:contentStreamLength";
}

- (NSString *) versionSeriesIdPropertyName
{
    // is there a key in the cmis prerelease?
	return @"cmis:versionSeriesId";
}

- (BOOL)isPreReleaseCmis {
	return [[[RepositoryServices shared] currentRepositoryInfo] isPreReleaseCmis];
}


- (NSString *)hostURL
{
	NSString *protocol = userPrefProtocol();
	NSString *host = userPrefHostname();
	NSString *port = userPrefPort();
	return [NSString stringWithFormat:@"%@://%@:%@", protocol, host, port];	
}

- (NSURL *)serviceDocumentURL
{
	// FIXME: Add slash checks
	
	NSString *protocol = userPrefProtocol();
	NSString *host = userPrefHostname();
	NSString *port = userPrefPort();
	NSString *serviceDocumentURI = serviceDocumentURIString();
	NSString *serviceDocumentURLString = [NSString stringWithFormat:@"%@://%@:%@%@", protocol, host, port, serviceDocumentURI];
    NSLog(@"SERVICE DOC URL: %@", serviceDocumentURLString);
    
	return [NSURL URLWithString:serviceDocumentURLString];
}

- (NSURL *)childrenURLforNode: (NSString*)node
{
	NSString *baseUrlStr = [self hostURL];
	NSString *urlStr = [NSString stringWithFormat:@"%@%@/children?includeAllowableActions=true", baseUrlStr, node];
	NSURL *u         = [NSURL URLWithString:urlStr];
	
	return u;
}


#pragma mark -
#pragma mark Singleton methods
+ (ServiceInfo *)sharedInstance
{
    @synchronized(self)
    {
        if (sharedInstance == nil)
			sharedInstance = [[ServiceInfo alloc] init];
    }
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [super allocWithZone:zone];
            return sharedInstance;  // assignment and return on first allocation
        }
    }
    return nil; // on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
