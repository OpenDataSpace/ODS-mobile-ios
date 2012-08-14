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
@synthesize ownerUserName = _owner;
@synthesize startDate = _startDate;
@synthesize dueDate = _dueDate;
@synthesize priority = _priority;
@synthesize ownerFullName = _ownerFullName;
@synthesize accountUUID = _accountUUID;
@synthesize tenantId = _tenantId;


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

    [_ownerFullName release];
    [_accountUUID release];
    [_tenantId release];
    [super dealloc];
}

- (TaskItem *) initWithJsonDictionary:(NSDictionary *) json {    
    self = [super init];
    
    if(self) {
        NSString *name = [[json objectForKey:@"name"] copy];
        self.name = name;
        [name release];

        NSString *title = [[json objectForKey:@"title"] copy];
        self.title = title;
        [title release];

        NSString *description = [[[json objectForKey:@"properties"] objectForKey:@"bpm_description"] copy];
        self.description = description;
        [description release];

        NSString *startDateString = [[[json objectForKey:@"workflowInstance"] objectForKey:@"startDate"] copy];
        self.startDate = dateFromIso(startDateString);
        [startDateString release];

        if ([[[json objectForKey:@"workflowInstance"] objectForKey:@"dueDate"] class] != [NSNull class])
        {
            NSString *dueDateString = [[[json objectForKey:@"workflowInstance"] objectForKey:@"dueDate"] copy];
            self.dueDate = dateFromIso(dueDateString);
            [dueDateString release];
        }

        NSString *priority = [[[json objectForKey:@"propertyLabels"] objectForKey:@"bpm_priority"] copy];
        self.priority = priority;
        [priority release];

        NSString *ownerUserName = [[[json objectForKey:@"owner"] objectForKey:@"userName"] copy];
        self.ownerUserName = ownerUserName;
        [ownerUserName release];

        NSString *firstName = [[[json objectForKey:@"owner"] objectForKey:@"firstName"] copy];
        NSString *lastName = [[[json objectForKey:@"owner"] objectForKey:@"lastName"] copy];
        self.ownerFullName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
        [firstName release];
        [lastName release];

        NSString *accountUUID = [json objectForKey:@"accountUUID"];
        self.accountUUID = accountUUID;
        [accountUUID release];

        NSString *tenantId = [json objectForKey:@"tenantId"];
        self.tenantId = tenantId;
        [tenantId release];
    }
    
    return self;
}

@end
