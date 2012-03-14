//
//  BrowseAccountsViewController.m
//  FreshDocs
//
//  Created by Ricardo Villarreal on 3/13/12.
//  Copyright (c) 2012 . All rights reserved.
//

#import "BrowseAccountsViewController.h"
#import "IFTextViewTableView.h"
#import "FDGenericTableViewPlistReader.h"
#import "AccountInfo.h"
#import "AccountManager.h"
#import "TableCellViewController.h"
#import "BrowseAccountsActions.h"

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
    [self.navigationController popToRootViewControllerAnimated:NO];
    [BrowseAccountsActions advanceToNextViewController:accountInfo withController:self animated:NO];
    
    [[self tabBarController] setSelectedViewController:[self navigationController]];
}
@end
