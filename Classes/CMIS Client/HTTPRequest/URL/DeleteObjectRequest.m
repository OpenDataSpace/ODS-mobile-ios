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
 *
 * ***** END LICENSE BLOCK ***** */
//
//  DeleteObjectRequest.m
//

#import "DeleteObjectRequest.h"
#import "RepositoryItem.h"

@implementation DeleteObjectRequest

+ (DeleteObjectRequest *)deleteRepositoryItem:(RepositoryItem *)repositoryItem accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
    NSString *url = [repositoryItem deleteURL];

    DeleteObjectRequest *deleteRequest = [DeleteObjectRequest requestWithURL:[NSURL URLWithString:url] accountUUID:uuid];
    [deleteRequest setShouldContinueWhenAppEntersBackground:YES];
	[deleteRequest setAllowCompressedResponse:YES];
    [deleteRequest setShouldAttemptPersistentConnection:NO]; // workaround for multiple DELETE requests observed with Wireshark
	
	[deleteRequest setRequestMethod:@"DELETE"];
	
	return deleteRequest;
}

@end
