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
//  AssetUploadItem.m
//

#import "AssetUploadItem.h"
#import "NSString+Utils.h"
#import "FileUtils.h"

@implementation AssetUploadItem
@synthesize assetURL = _assetURL;

- (void)dealloc
{
    [_assetURL release];
    [super dealloc];
}

- (id)initWithAssetURL:(NSURL *)assetURL
{
    self = [super init];
    if(self)
    {
        [self setAssetURL:assetURL];
        [self setExtension:[[self.assetURL pathExtension] lowercaseString]];
        [self setUploadType:UploadFormTypePhoto];
    }
    return self;
}

- (void)createPreview:(PreviewCreateResultBlock)finishBlock
{
    ALAssetsLibrary *assetLibrary = [[[ALAssetsLibrary alloc] init] autorelease];
    
    // As suggested in: http://stackoverflow.com/questions/8473110/using-alassetslibrary-and-alasset-take-out-image-as-nsdata
    [assetLibrary assetForURL:self.assetURL resultBlock:^(ALAsset *asset) 
     {
         ALAssetRepresentation *rep = [asset defaultRepresentation];
         Byte *buffer = (Byte*)malloc(rep.size);
         NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:rep.size error:nil];
         NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
         NSString *tempImageName = [[NSString generateUUID] stringByAppendingPathExtension:self.extension];
         NSString *tempImagePath = [FileUtils pathToTempFile:tempImageName];
         [data writeToFile:tempImagePath atomically:YES];
         [self setPreviewPath:tempImagePath];
         finishBlock(tempImagePath);
     } 
    failureBlock:^(NSError *err) 
    {
        NSLog(@"Error: %@",[err localizedDescription]);
        finishBlock(nil);
    }];
}

- (void)createUploadDataWithResultBlock:(UploadItemResultBlock)finishBlock
{
    finishBlock([NSData dataWithContentsOfFile:self.previewPath]);
}

@end
