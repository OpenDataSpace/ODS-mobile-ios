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
//  AssetUploadItem.h
// 
// Upload Item that creates the upload data from an asset URL
// Will also resize the image to the desired quality

#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "UploadHelper.h"

typedef void (^PreviewCreateResultBlock)(NSURL *previewURL);

@interface AssetUploadItem : NSObject <UploadHelper>
@property (nonatomic, retain) NSURL *assetURL;
@property (nonatomic, copy) NSString *imageQuality;
@property (nonatomic, copy) NSString *tempImagePath;

- (id)initWithAssetURL:(NSURL *)assetURL;
- (void)createPreview:(PreviewCreateResultBlock)finishBlock;

+ (NSURL *)createPreviewFromAsset:(ALAsset *)asset;

+ (ALAsset*) assetFromURL:(NSURL*) assetURL;
@end
