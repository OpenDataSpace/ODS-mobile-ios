//
//  DocumentItem.m
//  FreshDocs
//
//  Created by Tijs Rademakers on 14/08/2012.
//  Copyright (c) 2012 U001b. All rights reserved.
//

#import "DocumentItem.h"
#import "Utility.h"

@implementation DocumentItem

@synthesize nodeRef = _nodeRef;
@synthesize name = _name;
@synthesize title = _title;
@synthesize itemDescription = _itemDescription;
@synthesize modifiedDate = _modifiedDate;
@synthesize modifiedBy = _modifiedBy;

- (void) dealloc {
    [_nodeRef release];
	[_name release];
	[_title release];
	[_itemDescription release];
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
        self.itemDescription = description;
        [description release];
        
        NSString *modifiedDateString = [[json valueForKey:@"modified"] copy];
        self.modifiedDate = dateFromIso(modifiedDateString);
        [modifiedDateString release];
        
        NSString *modifier = [[json valueForKey:@"modifier"] copy];
        self.modifiedBy = modifier;
        [modifier release];
    }
    
    return self;
}

@end
