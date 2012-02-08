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
//  Feed.m
//

#import "Feed.h"

@implementation Feed
@synthesize atomId;
@synthesize atomTitle;
@synthesize linkRelations;
@synthesize atomEntries;

- (id)init
{
    self = [super init];
    if (self) {
        [self setLinkRelations:[NSMutableArray array]];
        [self setAtomEntries:[NSMutableArray array]];
        // Initialization code here.
    }
    
    return self;
}



#pragma mark -
#pragma mark Key-Value Coding Methods

- (id)valueForUndefinedKey:(NSString *)key 
{
    return nil;
}

@end
