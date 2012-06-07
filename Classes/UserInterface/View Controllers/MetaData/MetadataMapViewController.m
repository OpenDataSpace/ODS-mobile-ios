//
//  MetadataMapViewController.m
//  FreshDocs
//
//  Created by Peter Schmidt on 22/05/2012.
//  Copyright (c) 2012 . All rights reserved.
//

#import "MetadataMapViewController.h"
#import "MetadataMapAnnotation.h"
#import <QuartzCore/QuartzCore.h>

#define IS_IPAD ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)


@interface MetadataMapViewController ()
{
}
@end

@implementation MetadataMapViewController
@synthesize mapView = _mapView;
@synthesize mapAnnotation = _mapAnnotation;
@synthesize metadataDictionary = _metadataDictionary;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (id)initWithCoordinates:(CLLocationCoordinate2D)location andMetadata:(NSDictionary *)metadata
{
    if (IS_IPAD) 
    {
        self = [super initWithNibName:@"MetadataMapViewController~iPad" bundle:nil];
    }
    else 
    {
        self = [super initWithNibName:@"MetadataMapViewController~iPhone" bundle:nil];
    }
    if (self) 
    {
        UIBarButtonItem *customMapButton = [[[UIBarButtonItem alloc]
                                             initWithTitle:NSLocalizedString(@"metadata.button.loadMapApp", @"Open In Map App") 
                                             style:UIBarButtonItemStylePlain 
                                             target:self 
                                             action:@selector(loadMapApp:)] autorelease];
        self.navigationItem.rightBarButtonItem = customMapButton;
        coordinate = location;
         self.metadataDictionary = metadata;
        locationManager = [[CLLocationManager alloc]init];
        [locationManager setDelegate:self];
        [locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
        [self.mapView setDelegate:self];
    }
    return self;
    
}



- (IBAction)loadMapApp:(id)sender
{
    NSString *searchString = [NSString stringWithFormat:@"%f,%f",coordinate.latitude, coordinate.longitude];
    NSString *mapURL = [NSString stringWithFormat:@"http://maps.google.com/maps?q=%@",[searchString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:mapURL]];
    
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    MKCoordinateRegion region;
    MKCoordinateSpan regionSpan;
    regionSpan.latitudeDelta = 0.2;
    regionSpan.longitudeDelta = 0.2;
    region.span = regionSpan;
    region.center = coordinate;
    self.mapAnnotation = [[[MetadataMapAnnotation alloc]initWithCoordinates:coordinate andMetadata:self.metadataDictionary] autorelease];
    [self.mapView addAnnotation:self.mapAnnotation];
    [self.mapView setRegion:region animated:YES];
    [self.mapView setUserTrackingMode:MKUserTrackingModeNone];
    [self.mapView regionThatFits:region];
}

- (void)viewDidUnload
{
    self.mapView = nil;
    self.mapAnnotation = nil;
    self.metadataDictionary = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)dealloc
{
    self.mapView = nil;
    self.mapAnnotation = nil;
    self.metadataDictionary = nil;
    [locationManager setDelegate:nil];
    [self.mapView setDelegate:nil];
    [super dealloc];
}

#pragma --
#pragma CLLocationManagerDelegate methods

/**
 //TODO - put up an AlertView with error message?
 */
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    
}
/**
 required callback as per spec - but nothing to do here as we don't allow user tracking
 */
- (void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated
{
    
}

@end
