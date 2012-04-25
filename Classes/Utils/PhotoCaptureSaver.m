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
//  PhotoCaptureSaver.m
//

#import "PhotoCaptureSaver.h"

@implementation PhotoCaptureSaver
@synthesize originalImage = _originalImage;
@synthesize metadata = _metadata;
@synthesize assetURL = _assetURL;
@synthesize locationManager = _locationManager;
@synthesize userLocation = _userLocation;
@synthesize delegate = _delegate;

- (void)dealloc
{
    [_originalImage release];
    [_metadata release];
    [_assetURL release];
    [_locationManager release];
    [_userLocation release];
    [super dealloc];
}

- (id)initWithPickerInfo:(NSDictionary *)pickerInfo andDelegate:(id<PhotoCaptureSaverDelegate>)delegate
{
    self = [super init];
    if(self)
    {
        [self setDelegate:delegate];
        [self setOriginalImage:[pickerInfo objectForKey:UIImagePickerControllerOriginalImage]];
        [self setMetadata:[pickerInfo objectForKey:UIImagePickerControllerMediaMetadata]];
        [self setLocationManager:[[[CLLocationManager alloc] init] autorelease]];
        [self.locationManager setDelegate:self];
    }
    return self;
}

- (void)startSavingImage
{
    [self.locationManager startUpdatingLocation];
}

- (void)saveImage:(CLLocation *)location
{
    NSMutableDictionary *mutableMetadata = [NSMutableDictionary dictionaryWithDictionary:self.metadata];
    if (location) {
        // From http://stackoverflow.com/questions/4043685/problem-in-writing-metadata-to-image
        // Create formatted date
        NSTimeZone      *timeZone   = [NSTimeZone timeZoneWithName:@"UTC"];
        NSDateFormatter *formatter  = [[NSDateFormatter alloc] init]; 
        [formatter setTimeZone:timeZone];
        [formatter setDateFormat:@"HH:mm:ss.SS"];
        
        // Create GPS Dictionary
        NSDictionary *gpsDict   = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithFloat:fabs(location.coordinate.latitude)], kCGImagePropertyGPSLatitude
                                   , ((location.coordinate.latitude >= 0) ? @"N" : @"S"), kCGImagePropertyGPSLatitudeRef
                                   , [NSNumber numberWithFloat:fabs(location.coordinate.longitude)], kCGImagePropertyGPSLongitude
                                   , ((location.coordinate.longitude >= 0) ? @"E" : @"W"), kCGImagePropertyGPSLongitudeRef
                                   , [formatter stringFromDate:[location timestamp]], kCGImagePropertyGPSTimeStamp
                                   , nil];
        
        // Memory Management
        [formatter release];
        
        // Set GPS Dictionary to be part of media Metadata
        [mutableMetadata setValue:gpsDict forKey:(NSString *)kCGImagePropertyGPSDictionary];
    } 
    
    ALAssetsLibraryWriteImageCompletionBlock completeBlock = ^(NSURL *assetURL, NSError *error){
        if (!error) {  
            //get asset url
            [self setAssetURL:assetURL];
            NSLog(@"Saved image url: %@", assetURL);
            if([self.delegate respondsToSelector:@selector(photoCaptureSaver:didFinishSavingWithAssetURL:)])
            {
                [self.delegate photoCaptureSaver:self didFinishSavingWithAssetURL:assetURL];
            }
        }  
        else {
            if([self.delegate respondsToSelector:@selector(photoCaptureSaver:didFailWithError:)])
            {
                [self.delegate photoCaptureSaver:self didFailWithError:error];
            }
        }
    };
    
    ALAssetsLibrary *library = [[[ALAssetsLibrary alloc] init] autorelease];
    [library writeImageToSavedPhotosAlbum:[self.originalImage CGImage] 
                                 metadata:mutableMetadata
                          completionBlock:completeBlock];
}


#pragma mark - CLLocationManagerDelegate methods
/* We will only try to retrieve once the location, after that we stop the service
 */
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    [self setUserLocation:newLocation];
    [self.locationManager stopUpdatingLocation];
    [self setLocationManager:nil];
    
    [self saveImage:self.userLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [self.locationManager stopUpdatingLocation];
    [self setLocationManager:nil];
    
    [self saveImage:nil];
}
@end
