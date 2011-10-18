//
//  ASIHttpRequest+Alfresco.m
//  FreshDocs
//
//  Created by Gi Hyun Lee on 7/25/11.
//  Copyright 2011 Zia Consulting. All rights reserved.
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
