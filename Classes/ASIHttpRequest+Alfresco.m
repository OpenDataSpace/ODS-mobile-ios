//
//  ***** BEGIN LICENSE BLOCK *****
//  Version: MPL 1.1
//
//  The contents of this file are subject to the Mozilla Public License Version
//  1.1 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS" basis,
//  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
//  for the specific language governing rights and limitations under the
//  License.
//
//  The Original Code is the Alfresco Mobile App.
//  The Initial Developer of the Original Code is Zia Consulting, Inc.
//  Portions created by the Initial Developer are Copyright (C) 2011
//  the Initial Developer. All Rights Reserved.
//
//
//  ***** END LICENSE BLOCK *****
//
//
//  ASIHttpRequest+Alfresco.m
//

#import "ASIHttpRequest+Alfresco.h"
#import "Utility.h"


@implementation ASIHTTPRequest (Alfresco)

+ (NSString *)alfrescoRepositoryBaseServiceUrlString
{
    NSString *serviceRootPath = serviceDocumentURIString();
    if ([[serviceRootPath lastPathComponent] isEqualToString:@"cmis"]) 
    {
        serviceRootPath = [serviceRootPath stringByDeletingLastPathComponent];
        if ([[serviceRootPath lastPathComponent] isEqualToString:@"api"]) {
            serviceRootPath = [serviceRootPath stringByDeletingLastPathComponent];
            }
    }
    else
        serviceRootPath = @"/service";
    
    NSString *urlString = [NSString stringWithFormat:@"%@://%@:%@%@", 
                           userPrefProtocol(), userPrefHostname(), userPrefPort(),
                           serviceRootPath];
    
    NSLog(@"Base Alfresco Repository Service URL: %@", urlString);
    
    return urlString;
}



@end
