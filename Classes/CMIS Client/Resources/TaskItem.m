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
//  TaskItem.m
//

#import "TaskItem.h"
#import "Utility.h"

@implementation TaskItem

@synthesize name = _name;
@synthesize title = _title;
@synthesize description = _description;
@synthesize state = _state;
@synthesize initiator = _initiator;
@synthesize owner = _owner;
@synthesize startDate = _startDate;
@synthesize dueDate = _dueDate;
@synthesize priority = _priority;

- (void) dealloc {
	[_name release];
	[_title release];
	[_description release];
    [_state release];
    [_initiator release];
    [_owner release];
    [_startDate release];
    [_dueDate release];
    [_priority release];
	
	[super dealloc];
}

- (TaskItem *) initWithJsonDictionary:(NSDictionary *) json {    
    self = [super init];
    
    if(self) {
        self.name = [[json objectForKey:@"name"] copy];
        self.title = [[json objectForKey:@"title"] copy];
        self.description = [[[json objectForKey:@"properties"] objectForKey:@"bpm_description"] copy];
        self.startDate = dateFromIso([[[json objectForKey:@"properties"] objectForKey:@"bpm_startDate"] copy]);
        if ([[[json objectForKey:@"properties"] objectForKey:@"bpm_dueDate"] class] != [NSNull class])
        {
            self.dueDate = dateFromIso([[[json objectForKey:@"properties"] objectForKey:@"bpm_dueDate"] copy]);
        }
        self.priority = [[[json objectForKey:@"propertyLabels"] objectForKey:@"bpm_priority"] copy];
    }
    
    return self;
}

@end
