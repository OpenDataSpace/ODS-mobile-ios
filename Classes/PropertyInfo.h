//
//  PropertyInfo.h
//  FreshDocs
//
//  Created by Michael Muller on 5/11/10.
//  Copyright 2010 Michael J Muller. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PropertyInfo : NSObject {
	NSString *propertyId;
	NSString *localName;
	NSString *localNamespace;
	NSString *displayName;
	NSString *queryName;
	NSString *description;
	NSString *propertyType;
	NSString *cardinality;
	NSString *updatability;
	NSString *inherited;
	NSString *required;
	NSString *queryable;
	NSString *orderable;
	NSString *openChoice;
}

@property (nonatomic, retain) NSString *propertyId;
@property (nonatomic, retain) NSString *localName;
@property (nonatomic, retain) NSString *localNamespace;
@property (nonatomic, retain) NSString *displayName;
@property (nonatomic, retain) NSString *queryName;
@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) NSString *propertyType;
@property (nonatomic, retain) NSString *cardinality;
@property (nonatomic, retain) NSString *updatability;
@property (nonatomic, retain) NSString *inherited;
@property (nonatomic, retain) NSString *required;
@property (nonatomic, retain) NSString *queryable;
@property (nonatomic, retain) NSString *orderable;
@property (nonatomic, retain) NSString *openChoice;

@end
