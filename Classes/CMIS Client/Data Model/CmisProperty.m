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
//  CmisProperty.m
//

#import "CmisProperty.h"

@implementation CmisProperty
@synthesize type;
@synthesize propertyDefinitionId;
@synthesize displayName;
@synthesize queryName;
@synthesize cmisValue;

// Static Constants
static NSString *kPropertyDefinitionId_Attr = @"propertyDefinitionId";
static NSString *kDisplayName_Attr = @"displayName";
static NSString *kQueryName_Attr = @"queryName";


#pragma mark Memory Management

- (void)dealloc
{
    [type release];
    [propertyDefinitionId release];
    [displayName release];
    [queryName release];
    [cmisValue release];
    
    [super dealloc];
}

#pragma mark Initialization

- (id)initWithType:(NSString *)propType propertyDefinitionId:(NSString *)propDefId displayName:(NSString *)propDisplayName queryName:(NSString *)propQueryName
{
    self = [super init];
    if (self) {
        [self setType:propType];
        [self setPropertyDefinitionId:propDefId];
        [self setDisplayName:propDisplayName];
        [self setQueryName:queryName];
    }
    
    return self;
}

- (id)initWithType:(NSString *)propType usingXmlAttributeDictionary:(NSDictionary *)cmisPropertyAttributes
{
    self = [super init];
    if (self) {
        [self setType:propType];
        [self setPropertyDefinitionId:[cmisPropertyAttributes objectForKey:kPropertyDefinitionId_Attr]];
        [self setDisplayName:[cmisPropertyAttributes objectForKey:kDisplayName_Attr]];
        [self setQueryName:[cmisPropertyAttributes objectForKey:kQueryName_Attr]];
    }
    
    return self;
}

@end
