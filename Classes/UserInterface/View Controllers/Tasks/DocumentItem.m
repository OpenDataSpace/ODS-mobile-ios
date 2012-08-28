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
#import "RepositoryItem.h"

@implementation DocumentItem

@synthesize nodeRef = _nodeRef;
@synthesize name = _name;
@synthesize title = _title;
@synthesize itemDescription = _itemDescription;
@synthesize modifiedDate = _modifiedDate;
@synthesize modifiedBy = _modifiedBy;

- (void) dealloc
{
    [_nodeRef release];
	[_name release];
	[_title release];
	[_itemDescription release];
    [_modifiedDate release];
    [_modifiedBy release];
    
    [super dealloc];
}

- (id)initWithJsonDictionary:(NSDictionary *)json
{
    self = [super init];
    
    if(self)
    {
        [self setNodeRef:[json valueForKey:@"nodeRef"]];
        [self setName:[json valueForKey:@"name"]];
        [self setTitle:[json valueForKey:@"title"]];
        [self setItemDescription:[json valueForKey:@"description"]];
        [self setModifiedDate:dateFromIso([json valueForKey:@"modified"])];
        [self setModifiedBy:[json valueForKey:@"modifier"]];
    }
    
    return self;
}

- (id)initWithRepositoryItem:(RepositoryItem *)repositoryItem
{
    self = [super init];
    if (self)
    {
        self.name = repositoryItem.title;
        self.modifiedBy = repositoryItem.lastModifiedBy;
        self.modifiedDate = dateFromIso(repositoryItem.lastModifiedDate);
        self.nodeRef = repositoryItem.guid;
        self.title = repositoryItem.title;
    }
    return self;
}

@end
