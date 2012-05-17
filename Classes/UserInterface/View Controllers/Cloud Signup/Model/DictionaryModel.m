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
//  DictionaryModel.m
//

#import "DictionaryModel.h"

@implementation DictionaryModel
@synthesize delegate = _delegate;
@synthesize updateAction = _updateAction;

- (void)dealloc
{
	[_temporaryModel release];
	[super dealloc];
}

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		_temporaryModel = [[NSMutableDictionary dictionary] retain];
	}
	return self;
}

- (id)initWithDictionary:(NSDictionary *)dictionary
{
	self = [super init];
	if (self != nil)
	{
		_temporaryModel = [[NSMutableDictionary dictionaryWithDictionary:dictionary] retain];
	}
	return self;
}

- (void)setObject:(id)value forKey:(NSString *)key
{
	if (nil == key) return;
	
	[_temporaryModel setValue:value forKey:key];
    // Calling the delegate each time a change in the Model
    if(self.delegate && [self.delegate respondsToSelector:self.updateAction])
    {
        [self.delegate performSelector:self.updateAction withObject:self];
    }
}

- (id)objectForKey:(NSString *)key
{
	if (nil == key) return nil;
	
	return [_temporaryModel valueForKey:key];
}

- (NSDictionary *)dictionary
{
    return [NSDictionary dictionaryWithDictionary:_temporaryModel];
}

@end
