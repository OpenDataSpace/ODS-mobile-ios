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
//  DocumentItem.m
//

#import "DocumentItem.h"
#import "Utility.h"

@implementation DocumentItem

@synthesize nodeRef = _nodeRef;
@synthesize name = _name;
@synthesize title = _title;
@synthesize description = _description;
@synthesize modifiedDate = _modifiedDate;
@synthesize modifiedBy = _modifiedBy;

- (void) dealloc {
    [_nodeRef release];
	[_name release];
	[_title release];
	[_description release];
    [_modifiedDate release];
    [_modifiedBy release];
    
    [super dealloc];
}

- (DocumentItem *) initWithJsonDictionary:(NSDictionary *) json {    
    self = [super init];
    
    if(self) {
        
        NSString *nodeRef = [[json valueForKey:@"nodeRef"] copy];
        self.nodeRef = nodeRef;
        [nodeRef release];
        
        NSString *name = [[json valueForKey:@"name"] copy];
        self.name = name;
        [name release];
        
        NSString *title = [[json valueForKey:@"title"] copy];
        self.title = title;
        [title release];
        
        NSString *description = [[json valueForKey:@"description"] copy];
        self.description = description;
        [description release];
        
        NSString *modifiedDateString = [[json valueForKey:@"modified"] copy];
        self.modifiedDate = dateFromIso(modifiedDateString);
        [modifiedDateString release];
        
        NSString *modifier = [json valueForKey:@"modifier"];
        self.modifiedBy = modifier;
        [modifier release];
    }
    
    return self;
}

@end
