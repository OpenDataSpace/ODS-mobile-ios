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
//  NewCloudAccountViewController.m
//

#import "NewCloudAccountViewController.h"
#import "FDGenericTableViewPlistReader.h"
#import "AccountManager.h"
#import "NewCloudAccountRowRender.h"
#import "IFTextCellController.h"

@implementation NewCloudAccountViewController
@synthesize delegate = _delegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if(self.delegate)
    {
        UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(handleCancel:)];
        [self.navigationItem setLeftBarButtonItem:leftButton];
        [leftButton release];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    IFTextCellController *firstName = [(NewCloudAccountRowRender *)self.rowRenderDelegate firstNameCell];
    [firstName becomeFirstResponder];
}

- (void)handleCancel:(id)sender
{
    if(self.delegate)
    {
        [self.delegate accountControllerDidCancel:self];
    }
}

+ (NewCloudAccountViewController *)genericTableViewWithPlistPath:(NSString *)plistPath andTableViewStyle:(UITableViewStyle)tableStyle
{
    FDGenericTableViewPlistReader *settingsReader = [[[FDGenericTableViewPlistReader alloc] initWithPlistPath:plistPath] autorelease];
    NewCloudAccountViewController *controller = [[NewCloudAccountViewController alloc] init];
    [controller setTableStyle:tableStyle];
    [controller setSettingsReader:settingsReader];
    return [controller autorelease];
}

- (AccountInfo *)accountInfo
{
    return [[AccountManager sharedManager] accountInfoForUUID:self.selectedAccountUUID];
}

@end
