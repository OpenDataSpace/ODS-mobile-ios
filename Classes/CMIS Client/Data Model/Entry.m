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
//  Entry.m
//

#import "Entry.h"

@implementation Entry

@synthesize atomId = _atomId;
@synthesize atomTitle = _atomTitle;
@synthesize contentURL = _contentURL;
@synthesize contentType = _contentType;
@synthesize linkRelations = _linkRelations;
@synthesize cmisProperties = _cmisProperties;
@synthesize allowableActions = _allowableActions;

- (void)dealloc
{
    [_atomId release];
    [_atomTitle release];
    [_contentURL release];
    [_contentType release];
    [_linkRelations release];
    [_cmisProperties release];
    [_allowableActions release];
    [super dealloc];
}

- (id)init
{
    if (self = [super init])
    {
        [self setLinkRelations:[NSMutableArray array]];
        [self setCmisProperties:[NSMutableArray array]];
        [self setAllowableActions:[NSMutableArray array]];
    }
    
    return self;
}

@end
