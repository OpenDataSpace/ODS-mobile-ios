//
//  ***** BEGIN LICENSE BLOCK *****
//  Version: MPL 1.1
//
//  The contents of this file are subject to the Mozilla Public License Version
//  1.1 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS" basis,
//  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
//  for the specific language governing rights and limitations under the
//  License.
//
//  The Original Code is the Alfresco Mobile App.
//  The Initial Developer of the Original Code is Zia Consulting, Inc.
//  Portions created by the Initial Developer are Copyright (C) 2011
//  the Initial Developer. All Rights Reserved.
//
//
//  ***** END LICENSE BLOCK *****
//
//
//  PropertyInfo.h
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
