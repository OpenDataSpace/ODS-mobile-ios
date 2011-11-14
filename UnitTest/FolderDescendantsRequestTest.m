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
//  FolderDescendantsRequestTest.m
//

#import <GHUnitIOS/GHUnit.h>
#import "FolderDescendantsRequest.h"

@interface FolderDescendantsRequestTest : GHTestCase { }
@end

@implementation FolderDescendantsRequestTest
- (void)testParseResponseWithChildrens {
    NSString* path = [[NSBundle mainBundle] pathForResource:@"descendants-response" 
                                                     ofType:@"xml"];
    NSMutableData *xmlResponse = [NSMutableData dataWithContentsOfFile:path];
    
    //We are just testing the parsing
    FolderDescendantsRequest *request = [FolderDescendantsRequest folderDescendantsRequestWithItem:nil];
    [request setRawResponseData:xmlResponse];
    
    [request requestFinished];
    GHTestLog(@"Sample XML was processed");
    GHAssertNotNil(request.folderDescendants, @"Folder descendants were nil", nil);
    GHAssertTrue([request.folderDescendants count] == 65, @"Should be 65 descendants in response", nil);
    //This is not true, but is returned by the non Alfresco 4.0 repository
    //Just a list of the current node folder/documents and not its descendants
    GHAssertTrue([request.folderDescendants count] != 11, @"Should be 65 descendants in response", nil);
}
@end
