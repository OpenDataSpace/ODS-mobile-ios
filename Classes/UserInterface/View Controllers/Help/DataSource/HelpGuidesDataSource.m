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
//  HelpGuidesDataSource.m
//

#import "HelpGuidesDataSource.h"

@implementation HelpGuidesDataSource

@synthesize plistDictionary = _plistDictionary;
@synthesize delegate = _delegate;
@synthesize action = _action;

- (void)dealloc
{
    [_plistDictionary release];
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self)
    {
        [self setPlistDictionary:[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"HelpConfiguration" ofType:@"plist"]]];
    }
    return self;
}

- (NSDictionary *)datasource
{
    NSArray *helpGuides = [self.plistDictionary objectForKey:@"helpGuides"];
    if (helpGuides == nil)
    {
        helpGuides = [NSArray array];
    }
    return [NSDictionary dictionaryWithObject:helpGuides forKey:@"helpGuides"];
}

- (void)delegate:(id)delegate forDatasourceChangeWithSelector:(SEL)action
{
    [self setDelegate:delegate];
    [self setAction:action];
}

- (void)handleAccountListUpdated:(NSNotification *)notification
{
    if (self.delegate && [self.delegate respondsToSelector:self.action])
    {
        [self.delegate performSelector:self.action withObject:[self datasource] withObject:notification];
    }
}

@end
