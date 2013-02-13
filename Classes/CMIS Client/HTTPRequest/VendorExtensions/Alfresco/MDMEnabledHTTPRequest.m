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
//  ClassesHTTPRequest.m
//

#import "MDMEnabledHTTPRequest.h"
#import "AlfrescoMDMLite.h"
#import <objc/runtime.h>

@implementation MDMEnabledHTTPRequest

+ (MDMEnabledHTTPRequest *)mdmEnabledRequestForAccountUUID:(NSString *)uuid tenantID:(NSString *)tenantID
{
    NSString *mdmClassName = [kMDMAspectKey stringByReplacingOccurrencesOfString:@":" withString:@"_"];
    NSDictionary *infoDictionary = [NSDictionary dictionaryWithObject:mdmClassName forKey:@"CLASSNAME"];
    MDMEnabledHTTPRequest *request = [MDMEnabledHTTPRequest requestForServerAPI:kServerAPIClasses accountUUID:uuid tenantID:tenantID infoDictionary:infoDictionary];
    [request setRequestMethod:@"GET"];
    return request;
}

- (void)requestFinishedWithSuccessResponse
{
    NSLog(@"MDM is enabled for accountUUID %@", self.accountUUID);
    
    [[AlfrescoMDMLite sharedInstance] enableMDMForAccountUUID:self.accountUUID tenantID:self.tenantID enabled:YES];
}

- (void)failWithError:(NSError *)theError
{
    // Override: Ignore a 404 error
    if (self.responseStatusCode == 404)
    {
        NSLog(@"MDM is NOT available for accountUUID %@", self.accountUUID);

        [[AlfrescoMDMLite sharedInstance] enableMDMForAccountUUID:self.accountUUID tenantID:self.tenantID enabled:NO];

        // We need to call requestFinished on ASIHTTPRequest NOT BaseHTTPRequest to avoid reentrancy to this method
        SEL requestFinishedSel = @selector(requestFinished);
        Method requestFinishedMethod = class_getInstanceMethod([[self superclass] superclass], requestFinishedSel);
        IMP requestFinishedImp = method_getImplementation(requestFinishedMethod);
        requestFinishedImp(self, requestFinishedSel);
    }
    else
    {
        [super failWithError:theError];
    }
}

@end
