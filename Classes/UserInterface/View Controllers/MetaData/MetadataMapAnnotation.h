//
//  MetadataMapAnnotation.h
//  FreshDocs
//
//  Created by Peter Schmidt on 22/05/2012.
//  Copyright (c) 2012 . All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
/** 
 Map Annotation helper class for displaying the location where the image was taken
 
 */
@interface MetadataMapAnnotation : NSObject <MKAnnotation>
{
    CLLocationCoordinate2D coordinate;    
    NSDictionary *metadataDictionary;
}
@property (nonatomic, retain) NSDictionary *metadataDictionary;
/**
 @param location - the latitude/longitude co-ordinate pair to be used
 @param metadata - the NSDictionary, containing the whole set of metadata returned from the server. At the moment this is not used. But in case
 we want to annotate the location of the image on the map it would be useful to base this on the image metadata
 @return MetadataMapAnnotation
 */
- (id)initWithCoordinates:(CLLocationCoordinate2D)location andMetadata:(NSDictionary *)metadata;
@end
