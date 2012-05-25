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
//  ActionServiceHTTPRequest.m
//

#import "ActionServiceHTTPRequest.h"
#import "SBJSON.h"

@implementation ActionServiceHTTPRequest

+ (id)requestWithDefinitionName:(ActionDefinitionName)definitionName withNode:(NSString *)node accountUUID:(NSString *)accountUUID tenantID:(NSString *)tenantID
{
    NSDictionary *infoDict = [NSDictionary dictionaryWithObject:@"true" forKey:@"ASYNC"];
    ActionServiceHTTPRequest *request = [ActionServiceHTTPRequest requestForServerAPI:kServerAPIActionService accountUUID:accountUUID tenantID:tenantID infoDictionary:infoDict];
    NSDictionary *actionDefinitions = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"extract-metadata", [NSNumber numberWithInteger:ActionDefinitionExtractMetadata],
                            nil
                            ];
    
    NSString *actionDefinition = [actionDefinitions objectForKey:[NSNumber numberWithInteger:definitionName]];
    NSMutableDictionary *postDict = [NSMutableDictionary dictionaryWithCapacity:2];
    [postDict setObject:node forKey:@"actionedUponNode"];
    [postDict setObject:actionDefinition forKey:@"actionDefinitionName"];
    
    SBJSON *jsonObj = [SBJSON new];
    NSString *postBody = [jsonObj stringWithObject:postDict];
    NSMutableData *postData = [NSMutableData dataWithData:[postBody dataUsingEncoding:NSUTF8StringEncoding]];
    [request setPostBody:postData];
    [request setRequestMethod:@"POST"];
    
    [jsonObj release];
    return request;
}

@end
