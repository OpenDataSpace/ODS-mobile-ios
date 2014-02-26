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
//  BrowseAccountsViewController.m
//

#import "BrowseAccountsViewController.h"
#import "FDGenericTableViewPlistReader.h"
#import "AccountInfo.h"
#import "AccountManager.h"
#import "BrowseAccountsActions.h"
#import "AccountStatusManager.h"

@implementation BrowseAccountsViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        [self setSettingsReader:[[[FDGenericTableViewPlistReader alloc] initWithPlistPath:[[NSBundle mainBundle] pathForResource:@"BrowseAccountConfiguration" ofType:@"plist"]] autorelease]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBrowseDocuments:) 
                                                     name:kBrowseDocumentsNotification object:nil];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[AccountStatusManager sharedManager] requestAllAccountStatus];
}

/* The method will listen for a BrowseDocuments event. Triggered when the user taps the Browse Account button in the account's details.
    The actions delegate gets called by a "fake" user tap into the account we want to browse into.
 */
- (void)handleBrowseDocuments:(NSNotification *)notification 
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(handleBrowseDocuments:) withObject:notification waitUntilDone:NO];
        return;
    }
    
    NSString *uuidToBrowse = [[notification userInfo] objectForKey:@"accountUUID"];
    AccountInfo *accountInfo = [[AccountManager sharedManager] accountInfoForUUID:uuidToBrowse];
    
    if (!IS_IPAD) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
            [self.navigationController popToRootViewControllerAnimated:NO];
            [BrowseAccountsActions advanceToNextViewController:accountInfo withController:self animated:NO];
        });
    }
    else {
        [self.navigationController popToRootViewControllerAnimated:NO];
        [BrowseAccountsActions advanceToNextViewController:accountInfo withController:self animated:NO];
    }
    
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {  //to fix ios6 have no such property
        [self tabBarController].tabBar.translucent = NO;
    }
    
    [[self tabBarController] setSelectedViewController:[self navigationController]];
}
@end
