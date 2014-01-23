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
#import "FileUtils.h"
#import "AppProperties.h"

@implementation AssetUploadItem
@synthesize assetURL = _assetURL;
@synthesize imageQuality = _imageQuality;
@synthesize tempImagePath = _tempImagePath;

- (void)dealloc
{
    [_assetURL release];
    [_imageQuality release];
    [_tempImagePath release];
    [super dealloc];
}

- (id)initWithAssetURL:(NSURL *)assetURL
{
    self = [super init];
    if(self)
    {
        [self setAssetURL:assetURL];
    }
    return self;
}

- (void)createPreview:(PreviewCreateResultBlock)finishBlock
{
    ALAssetsLibrary *assetLibrary = [[[ALAssetsLibrary alloc] init] autorelease];
    
    // As suggested in: http://stackoverflow.com/questions/8473110/using-alassetslibrary-and-alasset-take-out-image-as-nsdata
    [assetLibrary assetForURL:self.assetURL resultBlock:^(ALAsset *asset) 
     {
         NSURL *preview = [AssetUploadItem createPreviewFromAsset:asset];

         [self setTempImagePath:[preview path]];
         finishBlock(preview);
     } 
    failureBlock:^(NSError *err) 
    {
        AlfrescoLogDebug(@"Error: %@",[err localizedDescription]);
        finishBlock(nil);
    }];
}

+ (NSURL *)createPreviewFromAsset:(ALAsset *)asset
{
    ALAssetRepresentation *rep = [asset defaultRepresentation];
    Byte *buffer = (Byte*)malloc(rep.size);
    NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:rep.size error:nil];
    NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
    NSString *extension = [[[asset.defaultRepresentation url] pathExtension] lowercaseString];
    
    NSString *tempImageName = [[NSString generateUUID] stringByAppendingPathExtension:extension];
    NSString *tempImagePath = [FileUtils pathToTempFile:tempImageName];
    [data writeToFile:tempImagePath atomically:YES];
    return [NSURL fileURLWithPath:tempImagePath];
}

- (void)preUpload
{
    NSString *userSelectedSizing = [[FDKeychainUserDefaults standardUserDefaults] objectForKey:@"ImageUploadSizingOption"];
    NSDictionary *allImageQualities = [AppProperties propertyForKey:kImageUploadSizingOptionDict];
    NSDictionary *selectedQuality = [allImageQualities objectForKey:userSelectedSizing];
    
    if(!selectedQuality)
    {
        return;
    }
    
    CGFloat compressionQuality = [[selectedQuality objectForKey:@"ImageCompressionQualityFloat"] floatValue];
    CGFloat imageResizeRatio = [[selectedQuality objectForKey:@"ImageResizeRatioFloat"] floatValue];
    
    if(compressionQuality >= 1 && imageResizeRatio >= 1)
    {
        //No need to resize or compression
        return;
    }
    
    // From SO question: http://stackoverflow.com/questions/5125323/problem-setting-exif-data-for-an-image
    CGImageSourceRef  source = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:self.tempImagePath], NULL);
    //get all the metadata in the image
    NSDictionary *metadata = (NSDictionary *) CGImageSourceCopyPropertiesAtIndex(source,0,NULL);
    //make the metadata dictionary mutable so we can add properties to it
    NSMutableDictionary *metadataAsMutable = [[metadata mutableCopy]autorelease];
    [metadata release];
    CFStringRef UTI = CGImageSourceGetType(source);
    
    //this will be the data CGImageDestinationRef will write into
    NSMutableData *dest_data = [NSMutableData data];
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithData((CFMutableDataRef)dest_data,UTI,1,NULL);
    
    if(!destination) {
        AlfrescoLogDebug(@"***Could not create image destination ***");
        if (source) 
        {
            CFRelease(source);
        }
        return;
    }
    
    if(compressionQuality < 1)
    {
        [metadataAsMutable setObject:[NSNumber numberWithFloat:compressionQuality] forKey:(id)kCGImageDestinationLossyCompressionQuality];
    }
    
    CGImageRef imgRef = NULL;
    // The next  if will always be YES at this point but the code is in place
    // in case the configuration changes and either one of the two quality settings is 1 (no compression/resizing needed) 
    if(imageResizeRatio < 1)
    {
        CGFloat width = [[metadataAsMutable objectForKey:(id)kCGImagePropertyPixelWidth] floatValue];
        CGFloat height = [[metadataAsMutable objectForKey:(id)kCGImagePropertyPixelHeight] floatValue];
        
        CGFloat maxDimension = MAX(width, height);
        CGFloat thumbDimension = ceilf(maxDimension * imageResizeRatio);
        CFDictionaryRef options = (CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:(id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailFromImageAlways, (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailFromImageAlways, (id)[NSNumber numberWithFloat:thumbDimension], (id)kCGImageSourceThumbnailMaxPixelSize, nil];
        imgRef = CGImageSourceCreateThumbnailAtIndex(source, 0, options);
        CGImageDestinationAddImage(destination, imgRef, (CFDictionaryRef) metadataAsMutable);
    }
    else {
        //add the image contained in the image source to the destination, overidding the old metadata with our modified metadata
        CGImageDestinationAddImageFromSource(destination,source,0, (CFDictionaryRef) metadataAsMutable);
    }
    
    //tell the destination to write the image data and metadata into our data object.
    //It will return false if something goes wrong
    BOOL success = NO;
    success = CGImageDestinationFinalize(destination);
    
    if(!success) {
        AlfrescoLogDebug(@"***Could not create data from image destination ***");
    }
    
    //now we have the data ready to go, so do whatever you want with it
    //here we just write it to disk at the same path we were passed
    [dest_data writeToFile:self.tempImagePath atomically:YES];
    
    //cleanup
    
    CFRelease(destination);
    CFRelease(source);
    if (imgRef != NULL)
        CFRelease(imgRef);
}

+ (ALAsset*) assetFromURL:(NSURL*) assetURL
{
    __block ALAsset *assetObj = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
    dispatch_async(queue, ^{
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library assetForURL:assetURL resultBlock:^(ALAsset *asset) {
            if (asset) {
                assetObj = [asset retain];
            }
            dispatch_semaphore_signal(semaphore);
        } failureBlock:^(NSError *error) {
            AlfrescoLogDebug(@"Counld not crate asset from assetURL:%@. Error %@", [assetURL absoluteString], error);
        }];
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return assetObj;
}

@end
