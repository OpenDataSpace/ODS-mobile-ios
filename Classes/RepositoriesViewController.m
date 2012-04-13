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
//  RepositoriesViewController.m
//

#import "RepositoriesViewController.h"
#import "IFTextViewTableView.h"
#import "RepositoryServices.h"
#import "RepositoryInfo.h"
#import "TableCellViewController.h"
#import "IFTemporaryModel.h"
#import "RootViewController.h"
#import "CMISServiceManager.h"
#import "AccountManager.h"

@interface RepositoriesViewController ()
- (void)repositoryCellPressed:(id)sender;
- (void)refreshButtonPressed:(id)sender;
- (MBProgressHUD *)createHUD;
- (void)setupBackButton;
@end


@implementation RepositoriesViewController
@synthesize selectedAccountUUID = _selectedAccountUUID;
@synthesize repositoriesForAccount = _repositoriesForAccount;
@synthesize viewTitle = _viewTitle;
@synthesize HUD = _HUD;

#pragma mark dealloc & init

- (void)dealloc
{
    [[CMISServiceManager sharedManager] removeAllListeners:self];
    
    [_viewTitle release];
    [_selectedAccountUUID release];
    [_repositoriesForAccount release];
    [_HUD release];
    
    [super dealloc];
}

- (id)initWithAccountUUID:(NSString *)uuid
{
    if (self = [super initWithStyle:UITableViewStylePlain])
    {
        _selectedAccountUUID = [uuid retain];
    }
    return self;
}


#pragma mark - View lifecycle

- (void)loadView
{
    self.view = [[[IFTextViewTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain] autorelease];
	[(IFTextViewTableView *)self.view setDelegate:self];
	[(IFTextViewTableView *)self.view setDataSource:self];
	[self.view setAutoresizesSubviews:YES];
	[self.view setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [[self navigationItem] setTitle:[self viewTitle]];
    
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshButtonPressed:)];
    [[self navigationItem] setRightBarButtonItem:refreshButton];
    [refreshButton release];    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[CMISServiceManager sharedManager] removeAllListeners:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setHUD:[self createHUD]];
    [self.HUD setGraceTime:0.5f];
    [self.HUD show:YES];
    
    CMISServiceManager *serviceManager = [CMISServiceManager sharedManager];
    [serviceManager addListener:self forAccountUuid:[self selectedAccountUUID]];
    [serviceManager addQueueListener:self];
    [serviceManager loadServiceDocumentForAccountUuid:[self selectedAccountUUID]];
    
    [self setupBackButton];
    

}

- (void)setupBackButton
{
    //Retrieve account count
    NSArray *allAccounts = [[AccountManager sharedManager] activeAccounts];
    NSInteger accountCount = [allAccounts count];
    if (accountCount == 1) 
    {
        [self.navigationItem setHidesBackButton:YES];
    }
    else 
    {
        [self.navigationItem setHidesBackButton:NO];
    }
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillUnload
{
    [[CMISServiceManager sharedManager] removeAllListeners:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - GenericTableView Methods

static NSString *RepositoryInfoKey = @"RepositoryInfo";

- (void)constructTableGroups
{
    if (![self model])
    {
        [self setModel:[[[IFTemporaryModel alloc] init] autorelease]];
    }
    
	NSMutableArray *headers = [NSMutableArray array];
    NSMutableArray *groups =  [NSMutableArray array];
	NSMutableArray *footers = [NSMutableArray array];
    
    NSMutableArray *mainGroup = [NSMutableArray array];
    [headers addObject:@""];
    [groups addObject:mainGroup];
    [footers addObject:@""];
    
    for (RepositoryInfo *repoInfo in [self repositoriesForAccount]) 
    {
        IFTemporaryModel *tmpModel = [[IFTemporaryModel alloc] init];
        [tmpModel setObject:repoInfo forKey:RepositoryInfoKey];
        
        NSString *labelText = [repoInfo repositoryName];
        if ([repoInfo tenantID]) {
            labelText = [repoInfo tenantID];
        }
        
        TableCellViewController *cellController = [[TableCellViewController alloc] initWithAction:@selector(repositoryCellPressed:) 
                                                                                         onTarget:self withModel:tmpModel];
        [tmpModel release];
        
        [cellController setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        [cellController.textLabel setText:labelText];
        [[cellController imageView] setImage:[UIImage imageNamed:kNetworkIcon_ImageName]];
        
        [mainGroup addObject:cellController];
        [cellController release];
    }
    
    if ([mainGroup count] != 0) {
    tableHeaders = [headers retain];
    tableGroups = [groups retain];
    tableFooters = [footers retain];
    }
}


#pragma mark - UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kDefaultTableCellHeight;
}


#pragma mark - CMISServiceManagerListener

- (void)serviceManagerRequestsFinished:(CMISServiceManager *)serviceManager
{
    NSArray *array = [NSArray arrayWithArray:[[RepositoryServices shared] getRepositoryInfoArrayForAccountUUID:[self selectedAccountUUID]]];
    [self setRepositoriesForAccount:array];
    
    [[self HUD] hide:YES];
    [[[self navigationItem] rightBarButtonItem] setEnabled:YES];
    
    [[CMISServiceManager sharedManager] removeQueueListener:self];
    [[CMISServiceManager sharedManager] removeListener:self forAccountUuid:[self selectedAccountUUID]];
    
    [self updateAndReload];
}

- (void)serviceManagerRequestsFailed:(CMISServiceManager *)serviceManager
{
    [[self HUD] hide:YES];
    [[[self navigationItem] rightBarButtonItem] setEnabled:YES];
    
    [[CMISServiceManager sharedManager] removeQueueListener:self];
    [[CMISServiceManager sharedManager] removeListener:self forAccountUuid:[self selectedAccountUUID]];
}


#pragma mark - MBProgressHUDDelegate Method
- (void)hudWasHidden
{
    // Remove HUD from screen when the HUD was hidded
    [self.HUD setTaskInProgress:NO];
    [self.HUD removeFromSuperview];
    [self.HUD setDelegate:nil];
    [self setHUD:nil];
}

#pragma mark - Action Handlers

- (void)repositoryCellPressed:(id)sender
{
    TableCellViewController *cellController = (TableCellViewController *)sender;
    IFTemporaryModel *tmpModel = [cellController model];
    RepositoryInfo *repoInfo = [tmpModel objectForKey:RepositoryInfoKey];
    
    NSString *repoName = [repoInfo repositoryName];
    if ([repoInfo tenantID]) {
        repoName = [repoInfo tenantID];
    }
    
    RootViewController *nextController = [[RootViewController alloc] initWithNibName:kFDRootViewController_NibName bundle:nil];
    [nextController setSelectedAccountUUID:[self selectedAccountUUID]];
    [nextController setTenantID:[repoInfo tenantID]];
    [nextController setRepositoryID:[repoInfo repositoryId]];
    [[nextController navigationItem] setTitle:repoName];
    
    [[self navigationController] pushViewController:nextController animated:YES];
    [nextController release];
}

- (void)refreshButtonPressed:(id)sender
{
    [[[self navigationItem] rightBarButtonItem] setEnabled:NO];
    
    
    [self setHUD:[self createHUD]];
    [self.HUD show:YES];
    
    CMISServiceManager *serviceManager = [CMISServiceManager sharedManager];
    [serviceManager addListener:self forAccountUuid:[self selectedAccountUUID]];
    [serviceManager addQueueListener:self];
    [serviceManager reloadServiceDocumentForAccountUuid:[self selectedAccountUUID]];
}

#pragma mark - Utility Methods

- (MBProgressHUD *)createHUD
{
    MBProgressHUD *tmpHud = [[[MBProgressHUD alloc] initWithView:[[self navigationController] view]] autorelease];
    [[[self navigationController] view] addSubview:tmpHud];
    
    [tmpHud setRemoveFromSuperViewOnHide:YES];
    [tmpHud setDelegate:self];
    [tmpHud setTaskInProgress:YES];
    [tmpHud setMinShowTime:kHUDMinShowTime];
    [tmpHud setGraceTime:KHUDGraceTime];
    
    return tmpHud;
}


@end
