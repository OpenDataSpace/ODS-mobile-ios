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
//  UploadItem.m
//

#import "UploadItem.h"
#import "Utility.h"

@implementation UploadItem
@synthesize fileName = _fileName;
@synthesize extension = _extension;
@synthesize previewURL = _previewURL;
@synthesize uploadType = _uploadType;

- (void)dealloc
{
    [_fileName release];
    [_extension release];
    [_previewURL release];
    [super dealloc];
}

- (NSString *)completeFileName
{
    return [self.fileName stringByAppendingPathExtension:self.extension];
}

- (void)createUploadDataWithResultBlock:(UploadItemResultBlock)finishBlock
{
    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}

- (NSString *)mimeType
{
    return mimeTypeForFilename([self completeFileName]);
}

@end
