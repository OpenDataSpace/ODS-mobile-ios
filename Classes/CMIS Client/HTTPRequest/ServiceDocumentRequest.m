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
//  ServiceDocumentRequest.m
//

#import "ServiceDocumentRequest.h"
#import "CMISMediaTypes.h"
#import "ServiceDocumentParser.h"

@implementation ServiceDocumentRequest

- (void)requestFinishedWithSuccessResponse
{
	// !!!: Check media type
		 
	ServiceDocumentParser *needToReimpl = [[ServiceDocumentParser alloc] initWithAtomPubServiceDocumentData:self.responseData];
    [needToReimpl setAccountUuid:self.accountUUID];
    [needToReimpl setTenantID:self.tenantID];
	[needToReimpl parse];
	[needToReimpl release];
}

- (void)failWithError:(NSError *)theError
{
	// TODO: We should be logging something here and doing something!
	[super failWithError:theError];
}

#pragma mark -
#pragma mark Factory Methods

+ (id)httpGETRequestForAccountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
	ServiceDocumentRequest *getRequest = [ServiceDocumentRequest requestForServerAPI:kServerAPICMISServiceInfo 
                                                                         accountUUID:uuid tenantID:aTenantID];
	[getRequest addRequestHeader:@"Accept" value:kAtomPubServiceMediaType];
	[getRequest setRequestMethod:@"GET"];
	
	return getRequest;
}

+ (id)httpGETRequestForAccountUUID:(NSString *)uuid
{
	ServiceDocumentRequest *getRequest = [ServiceDocumentRequest requestForServerAPI:kServerAPICMISServiceInfo 
                                                                          accountUUID:uuid];
	[getRequest addRequestHeader:@"Accept" value:kAtomPubServiceMediaType];
	[getRequest setRequestMethod:@"GET"];
	
	return getRequest;
}

@end
