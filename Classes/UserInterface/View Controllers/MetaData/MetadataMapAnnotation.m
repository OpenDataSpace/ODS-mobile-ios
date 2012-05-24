//
//  MetadataMapAnnotation.m
//  FreshDocs
//
//  Created by Peter Schmidt on 22/05/2012.
//  Copyright (c) 2012 . All rights reserved.
//

#import "MetadataMapAnnotation.h"

@implementation MetadataMapAnnotation
@synthesize coordinate;
@synthesize metadataDictionary = _metadataDictionary;
- (id)initWithCoordinates:(CLLocationCoordinate2D)location  andMetadata:(NSDictionary *)metadata
{
    self = [super init];
    if (self) 
    {
        coordinate = location;
        self.metadataDictionary = metadata;
    }
    return self;
}

- (void)dealloc
{
    self.metadataDictionary = nil;
    [super dealloc];
}

@end
