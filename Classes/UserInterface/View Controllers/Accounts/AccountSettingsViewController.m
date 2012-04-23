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
//  AccountSettingsViewController.m
//

#import "AccountSettingsViewController.h"
#import "AccountStatusManager.h"
#import "FDGenericTableViewPlistReader.h"
#import "AccountManager.h"
#import "IpadSupport.h"

@implementation AccountSettingsViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[AccountStatusManager sharedManager] requestAllAccountStatus];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (IS_IPAD)
    {
        [IpadSupport clearDetailController];
    }
}

- (void)navigateIntoLastAccount
{
    NSArray *accounts = [self.datasource objectForKey:@"accounts"];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[accounts count]-1 inSection:1];
    [self.actionsDelegate rowWasSelectedAtIndexPath:indexPath withDatasource:self.datasource andController:self];
}

+ (AccountSettingsViewController *)genericTableViewWithPlistPath:(NSString *)plistPath andTableViewStyle:(UITableViewStyle)tableStyle
{
    FDGenericTableViewPlistReader *settingsReader = [[[FDGenericTableViewPlistReader alloc] initWithPlistPath:plistPath] autorelease];
    AccountSettingsViewController *controller = [[AccountSettingsViewController alloc] init];
    [controller setTableStyle:tableStyle];
    [controller setSettingsReader:settingsReader];
    return [controller autorelease];
}

@end
