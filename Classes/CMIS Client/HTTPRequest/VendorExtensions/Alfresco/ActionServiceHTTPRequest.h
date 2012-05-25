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
//  ActionServiceHTTPRequest.h
//
// Creates a request to the action Service. The template POST body for the ActionService:
// Method: POST 
// Content-Type: application/json 
// API endpoint: "api/actionQueue" 
// 
// { 
//     "actionedUponNode": "workspace://SpacesStore/abcdefgh-ijkl-mnop-qrst-uvwxyz123456", 
//     "actionDefinitionName": "extract-metadata" 
// } 

#import "BaseHTTPRequest.h"

typedef enum 
{
   ActionDefinitionExtractMetadata
} ActionDefinitionName;

@interface ActionServiceHTTPRequest : BaseHTTPRequest

/*
 Inits the requests with a given action and a node to which apply the action 
 */
+ (id)requestWithDefinitionName:(ActionDefinitionName)definitionName withNode:(NSString *)node accountUUID:(NSString *)account tenantID:(NSString *)tenantID;

@end
