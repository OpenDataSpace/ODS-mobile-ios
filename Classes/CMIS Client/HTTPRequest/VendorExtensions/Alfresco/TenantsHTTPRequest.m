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
//  NetworksHTTPRequest.m
//

#import "TenantsHTTPRequest.h"

NSString * const kPaidBusinessClassName = @"PAID_BUSINESS";

@implementation TenantsHTTPRequest

- (void)dealloc
{
    [_allTenantIDs release];
    
    [super dealloc];
}

+ (id)tenantsRequestForAccountUUID:(NSString *)uuid
{
    AlfrescoLogDebug(@"Instance of TenantsHTTPRequest created with account UUID: %@", uuid);
    return [self requestForServerAPI:kServerAPINetworksCollection accountUUID:uuid];
}

#pragma mark - ASIHTTPRequestDelegate methods

- (void)requestFinishedWithSuccessResponse
{
    AlfrescoLogTrace(@"Tenants response: %@", [self responseString]);
	NSArray *result = [self arrayFromJSONResponse];
    
    /**
     * The home tenant might not be valid (e.g. for the case where a gmail.com user has been invited to a site)
     * See MOBILE-1281: Configuring an account where the user has been invited with a GMail account causes multiple password prompts to appear
     */
    NSMutableArray *tenantIDs = [NSMutableArray array];
    
    // Primary enabled?
    if ([[result valueForKeyPath:@"data.home.enabled"] boolValue])
    {
        [tenantIDs addObject:[result valueForKeyPath:@"data.home.tenant"]];
    }
    
    // Secondaries
    for (NSDictionary *secondary in [result valueForKeyPath:@"data.secondary"])
    {
        if ([secondary[@"enabled"] boolValue])
        {
            [tenantIDs addObject:secondary[@"tenant"]];
        }
    }

    self.allTenantIDs = [NSArray arrayWithArray:tenantIDs];

    // Account class
    self.paidAccount = [[result valueForKeyPath:@"data.home.className"] isEqualToString:kPaidBusinessClassName];
}

@end
