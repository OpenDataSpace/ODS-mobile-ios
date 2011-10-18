//
//  PropertyInfo.m
//  FreshDocs
//
//  Created by Michael Muller on 5/11/10.
//  Copyright 2010 Michael J Muller. All rights reserved.
//

#import "PropertyInfo.h"


@implementation PropertyInfo

@synthesize propertyId;
@synthesize localName;
@synthesize localNamespace;
@synthesize displayName;
@synthesize queryName;
@synthesize description;
@synthesize propertyType;
@synthesize cardinality;
@synthesize updatability;
@synthesize inherited;
@synthesize required;
@synthesize queryable;
@synthesize orderable;
@synthesize openChoice;

- (void) dealloc {
	[propertyId release];
	[localName release];
	[localNamespace release];
	[displayName release];
	[queryName release];
	[description release];
	[propertyType release];
	[cardinality release];
	[updatability release];
	[inherited release];
	[required release];
	[queryable release];
	[orderable release];
	[openChoice release];
	[super dealloc];
}

@end
