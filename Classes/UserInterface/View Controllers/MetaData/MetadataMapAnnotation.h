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
//  MetadataMapAnnotation.h

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

/** 
 * Map Annotation helper class for displaying the location where the image was taken
 */
@interface MetadataMapAnnotation : NSObject <MKAnnotation>

@property (nonatomic, retain) NSDictionary *metadataDictionary;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

/**
 @param location - the latitude/longitude co-ordinate pair to be used
 @param metadata - the NSDictionary, containing the whole set of metadata returned from the server. At the moment this is not used. But in case
 we want to annotate the location of the image on the map it would be useful to base this on the image metadata
 @return MetadataMapAnnotation
 */
- (id)initWithCoordinates:(CLLocationCoordinate2D)location andMetadata:(NSDictionary *)metadata;

@end
