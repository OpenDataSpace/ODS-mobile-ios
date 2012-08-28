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
 *
 * ***** END LICENSE BLOCK ***** */
//
//  AccountAutocreateDatasource.m
//

#import "AccountAutocreateDatasource.h"

@implementation AccountAutocreateDatasource

@synthesize delegate = _delegate;
@synthesize action = _action;
@synthesize data = _data;

- (void)dealloc
{
    [_data release];
    [super dealloc];
}

- (NSDictionary *)datasource
{
    return [NSDictionary dictionaryWithDictionary:self.data];
}

- (void)delegate:(id)delegate forDatasourceChangeWithSelector:(SEL)action
{
    [self setDelegate:delegate];
    [self setAction:action];
}

- (void)notifyDatasourceUpdated
{
    if (self.delegate && [self.delegate respondsToSelector:self.action])
    {
        [self.delegate performSelector:self.action withObject:[self datasource] withObject:nil];
    }
}

- (void)setData:(NSDictionary *)data
{
    [_data autorelease];
    _data = [data retain];
    [self notifyDatasourceUpdated];
}

@end
