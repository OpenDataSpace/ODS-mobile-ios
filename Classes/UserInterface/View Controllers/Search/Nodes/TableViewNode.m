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
//  TableViewNode.m
//

#import "TableViewNode.h"

@implementation TableViewNode
@synthesize value;
@synthesize parent;
@synthesize indentationLevel;
@synthesize canExpand;
@synthesize isExpanded;
@synthesize accountUUID;

- (void)dealloc {
    [value release];
    [parent release];
    [accountUUID release];
    [_tenantID release];
    [super dealloc];
}

- (NSString *)title {
    NSLog(@"WARNING - property must be implemented in the subclasses");
    return nil;
}

- (NSString *)breadcrumb {
    NSLog(@"WARNING - property must be implemented in the subclasses");
    return nil;
}

- (UIImage *)cellImage {
    NSLog(@"WARNING - property must be implemented in the subclasses");
    return nil;
}

- (NSString *)tenantID {
    return nil;
}

- (void)setTenantID:(NSString *)tenantID {
    NSLog(@"WARNING - property must be implemented in the subclasses");
    return;
}
    
@end
