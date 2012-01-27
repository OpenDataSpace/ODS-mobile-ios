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
//  FileProtectionTest.m
//

#import <GHUnitIOS/GHUnit.h>
#import "SavedDocument.h"

@interface FileProtectionTest : GHTestCase { }
@end

@implementation FileProtectionTest

- (void)testTempFileProtection
{
#if !TARGET_IPHONE_SIMULATOR
    NSString *tempPath = [SavedDocument pathToTempFile:@"button_submitanswer.png"];
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"button_submitanswer" ofType:@"png"];
    NSData *imageData = [NSData dataWithContentsOfFile:imagePath];
    NSError *error = nil;
    
    [imageData writeToFile:tempPath options:NSDataWritingFileProtectionComplete error:&error];
    
    GHAssertNil(error, @"Error %@ ocurred when trying to save the temp file",[error description]);
    
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:tempPath error:&error];
    GHAssertNil(error, @"Error %@ ocurred when trying to read the temp file",[error description]);
    
    GHAssertTrue([[fileAttributes objectForKey:NSFileProtectionKey] isEqual:NSFileProtectionComplete], @"The file protection in the temp file is %@ instead of %@", [fileAttributes objectForKey:NSFileProtectionKey], NSFileProtectionComplete);
    
#endif // TARGET_IPHONE_SIMULATOR
}

- (void)testDocumentFileProtection
{
#if !TARGET_IPHONE_SIMULATOR
    NSString *docPath = [SavedDocument pathToSavedFile:@"button_submitanswer.png"];
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"button_submitanswer" ofType:@"png"];
    NSData *imageData = [NSData dataWithContentsOfFile:imagePath];
    NSError *error = nil;
    
    [imageData writeToFile:docPath options:NSDataWritingFileProtectionComplete error:&error];
    
    GHAssertNil(error, @"Error %@ ocurred when trying to save the doc file",[error description]);
    
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:docPath error:&error];
    GHAssertNil(error, @"Error %@ ocurred when trying to read the doc file",[error description]);
    
    GHAssertTrue([[fileAttributes objectForKey:NSFileProtectionKey] isEqual:NSFileProtectionComplete], @"The file protection in the doc file is %@ instead of %@", [fileAttributes objectForKey:NSFileProtectionKey], NSFileProtectionComplete);
#endif // TARGET_IPHONE_SIMULATOR
}

- (void)tearDownClass
{
    NSString *tempPath = [SavedDocument pathToTempFile:@"button_submitanswer.png"];
    [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
    
    NSString *docPath = [SavedDocument pathToSavedFile:@"button_submitanswer.png"];
    [[NSFileManager defaultManager] removeItemAtPath:docPath error:nil];
}
@end
