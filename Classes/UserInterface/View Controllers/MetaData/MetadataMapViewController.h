//
//  MetadataMapViewController.h
//  FreshDocs
//
//  Created by Peter Schmidt on 22/05/2012.
//  Copyright (c) 2012 . All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@class MetadataMapAnnotation;

@interface MetadataMapViewController : UIViewController <CLLocationManagerDelegate, MKMapViewDelegate>
{
    IBOutlet MKMapView *mapView;
    CLLocationManager *locationManager;
    CLLocationCoordinate2D coordinate;
    NSDictionary *metadataDictionary;
    MetadataMapAnnotation *mapAnnotation;
}
@property (nonatomic, retain) MetadataMapAnnotation *mapAnnotation;
@property (nonatomic, retain) NSDictionary *metadataDictionary;
@property (nonatomic, retain) IBOutlet MKMapView *mapView;
- (id)initWithCoordinates:(CLLocationCoordinate2D)location andMetadata:(NSDictionary *)metadata;
- (IBAction)loadMapApp:(id)sender;
@end
