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
//  AccountDatasource.m
//

#import "AccountDatasource.h"
#import "AccountManager.h"

@implementation AccountDatasource 
@synthesize delegate = _delegate;
@synthesize action = _action;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if(self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAccountListUpdated:) 
                                                     name:kNotificationAccountListUpdated object:nil];
    }
    return self;
}
-(NSDictionary *)datasource
{
    NSArray *allAccounts = [[AccountManager sharedManager] allAccounts];
    return [NSDictionary dictionaryWithObject:allAccounts forKey:@"accounts"];
}

- (void)delegate:(id)delegate forDatasourceChangeWithSelector:(SEL)action
{
    [self setDelegate:delegate];
    [self setAction:action];
}

- (void)handleAccountListUpdated:(NSNotification *)notification
{
    if(self.delegate && [self.delegate respondsToSelector:self.action])
    {
        [self.delegate performSelector:self.action withObject:[self datasource] withObject:notification];
    }
}
@end
