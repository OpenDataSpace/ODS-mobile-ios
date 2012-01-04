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
//  PropertyInfo.m
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
