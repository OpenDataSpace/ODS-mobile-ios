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
//  MetadataMapViewController.m
//

#import "MetadataMapViewController.h"
#import "MetadataMapAnnotation.h"

@implementation MetadataMapViewController

@synthesize metadataDictionary = _metadataDictionary;
@synthesize coordinate = _coordinate;

- (void)dealloc
{
    [_metadataDictionary release];
    
    [super dealloc];
}

- (id)initWithCoordinates:(CLLocationCoordinate2D)location andMetadata:(NSDictionary *)metadata
{
    if (self = [super init])
    {
        MKMapView *mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
        MKCoordinateRegion region = MKCoordinateRegionMake(location, MKCoordinateSpanMake(0.2, 0.2));
        
        MetadataMapAnnotation *mapAnnotation = [[MetadataMapAnnotation alloc] initWithCoordinates:location andMetadata:metadata];
        [mapView addAnnotation:mapAnnotation];
        [mapView setRegion:region animated:YES];
        [mapView setUserTrackingMode:MKUserTrackingModeNone];
        [mapView regionThatFits:region];
        [self.view addSubview:mapView];
        [mapAnnotation release];
        [mapView release];
        
        UIBarButtonItem *customMapButton = [[[UIBarButtonItem alloc]
                                             initWithTitle:NSLocalizedString(@"metadata.button.loadMapApp", @"Open In Map App") 
                                                     style:UIBarButtonItemStylePlain 
                                                    target:self 
                                                    action:@selector(loadMapApp:)] autorelease];
        [self.navigationItem setRightBarButtonItem:customMapButton];

        [self setCoordinate:location];
        [self setMetadataDictionary:metadata];

        CLLocationManager *locationManager = [[CLLocationManager alloc] init];
        [locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
        [locationManager release];
    }
    return self;
}

- (IBAction)loadMapApp:(id)sender
{
    if (NSClassFromString(@"MKMapItem") != nil)
    {
        // iOS 6
        MKPlacemark *placemark = [[[MKPlacemark alloc] initWithCoordinate:self.coordinate addressDictionary:nil] autorelease];
        MKMapItem *mapItem = [[[MKMapItem alloc] initWithPlacemark:placemark] autorelease];
        [mapItem setName:[[self.metadataDictionary objectForKey:@"cmis:name"] stringByDeletingPathExtension]];
        [mapItem openInMapsWithLaunchOptions:nil];
    }
    else
    {
        // iOS < 6
        NSString *searchString = [NSString stringWithFormat:@"%f,%f", self.coordinate.latitude, self.coordinate.longitude];
        NSString *mapURL = [NSString stringWithFormat:@"http://maps.google.com/maps?q=%@",[searchString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:mapURL]];
    }
}

@end
