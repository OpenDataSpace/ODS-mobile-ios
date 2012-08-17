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
//  AccountAutocreateViewController.m
//

#import "AccountAutocreateViewController.h"
#import "AccountAutocreateDatasource.h"
#import "AccountAutocreateRowRender.h"
#import "FDGenericTableViewPlistReader.h"

@implementation AccountAutocreateViewController

@synthesize delegate = _delegate;

- (id)init
{
    self = [super init];
    if (self)
    {
        [self setSettingsReader:[[[FDGenericTableViewPlistReader alloc] initWithPlistPath:[[NSBundle mainBundle] pathForResource:@"AccountAutocreateConfiguration" ofType:@"plist"]] autorelease]];
        [self setTableStyle:UITableViewStyleGrouped];
    }
    return self;
}

- (void)setData:(NSDictionary *)data
{
    [(AccountAutocreateDatasource *)self.datasourceDelegate setData:data];
}

#pragma mark - AccountViewControllerDelegate

- (void)accountControllerDidFinishSaving:(AccountViewController *)accountViewController
{
    [accountViewController dismissModalViewControllerAnimated:YES];
    if (self.delegate && [self.delegate respondsToSelector:@selector(accountControllerDidFinishSaving:)])
    {
        [self.delegate performSelector:@selector(accountControllerDidFinishSaving:) withObject:accountViewController];
    }
}

- (void)accountControllerDidCancel:(AccountViewController *)accountViewController
{
    [accountViewController dismissModalViewControllerAnimated:YES];
    if (self.delegate && [self.delegate respondsToSelector:@selector(accountControllerDidCancel:)])
    {
        [self.delegate performSelector:@selector(accountControllerDidCancel:) withObject:accountViewController];
    }
}

#pragma mark - Class Methods

+ (AccountAutocreateViewController *)genericTableViewWithPlistPath:(NSString *)plistPath andTableViewStyle:(UITableViewStyle)tableStyle
{
    FDGenericTableViewPlistReader *settingsReader = [[[FDGenericTableViewPlistReader alloc] initWithPlistPath:plistPath] autorelease];
    AccountAutocreateViewController *controller = [[[AccountAutocreateViewController alloc] init] autorelease];
    [controller setTableStyle:tableStyle];
    [controller setSettingsReader:settingsReader];
    return controller;
}

@end
