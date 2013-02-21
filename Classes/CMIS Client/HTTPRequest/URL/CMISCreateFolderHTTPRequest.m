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
//  CMISCreateFolderHTTPRequest.m
//

#import "CMISCreateFolderHTTPRequest.h"
#import "CMISMediaTypes.h"
#import "GTMNSString+XML.h"

@implementation CMISCreateFolderHTTPRequest

+ (CMISCreateFolderHTTPRequest *)cmisCreateFolderRequestNamed:(NSString *)folderName parentItem:(RepositoryItem *)repositoryItem accountUUID:(NSString *)accountUUID
{
    NSString *postBody = [NSString stringWithFormat:@""
                          "<?xml version=\"1.0\" ?>"
                          "<entry xmlns=\"http://www.w3.org/2005/Atom\" xmlns:app=\"http://www.w3.org/2007/app\" xmlns:cmisra=\"http://docs.oasis-open.org/ns/cmis/restatom/200908/\">"
                          "<title type=\"text\">%@</title>"
                          "<cmisra:object xmlns:cmis=\"http://docs.oasis-open.org/ns/cmis/core/200908/\">"
                          "<cmis:properties>"
                          "<cmis:propertyId propertyDefinitionId=\"cmis:objectTypeId\">"
                          "<cmis:value>cmis:folder</cmis:value>"
                          "</cmis:propertyId>"
                          "</cmis:properties>"
                          "</cmisra:object>"
                          "</entry>", [folderName gtm_stringBySanitizingAndEscapingForXML]];

    NSURL *requestURL = [NSURL URLWithString:repositoryItem.identLink];
    CMISCreateFolderHTTPRequest *request = [CMISCreateFolderHTTPRequest requestWithURL:requestURL accountUUID:accountUUID];
    request.requestMethod = @"POST";
    [request addRequestHeader:@"Content-Type" value:kAtomEntryMediaType];
    request.shouldContinueWhenAppEntersBackground = YES;
    request.postBody = [NSMutableData dataWithData:[postBody dataUsingEncoding:NSUTF8StringEncoding]];
    request.contentLength = postBody.length;
    
    return request;
}

@end
