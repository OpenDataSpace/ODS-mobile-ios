//
//  SelectTenantViewController.m
//  FreshDocs
//
//  Created by Tijs Rademakers on 28/08/2012.
//  Copyright (c) 2012 U001b. All rights reserved.
//

#import "SelectTenantViewController.h"
#import "AccountInfo.h"
#import "RepositoryServices.h"
#import "RepositoryInfo.h"
#import "Theme.h"
#import "SelectTaskTypeViewController.h"

@interface SelectTenantViewController ()

@property (nonatomic, retain) NSString *accountUuid;
@property (nonatomic, retain) NSArray *repositories;

@end

@implementation SelectTenantViewController

@synthesize accountUuid = _accountUuid;
@synthesize repositories = _repositories;

- (id)initWithStyle:(UITableViewStyle)style account:(NSString *)uuid
{
    self = [super initWithStyle:style];
    if (self) {
        self.accountUuid = uuid;
    }
    return self;
}

- (void)dealloc
{
    [_accountUuid release];
    [_repositories release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [Theme setThemeForUITableViewController:self];
    [self setTitle:@"Choose tenant"];
    
    [self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                             target:self
                                                                                             action:@selector(cancel:)] autorelease]];
    
    RepositoryServices *repoService = [RepositoryServices shared];
    self.repositories = [repoService getRepositoryInfoArrayForAccountUUID:self.accountUuid];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)cancel:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.repositories.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    RepositoryInfo *repositoryInfo = [self.repositories objectAtIndex:indexPath.row];
    cell.textLabel.text = ([repositoryInfo tenantID] != nil) ? repositoryInfo.tenantID : repositoryInfo.repositoryName;
    cell.imageView.image = [UIImage imageNamed:kNetworkIcon_ImageName];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RepositoryInfo *repositoryInfo = [self.repositories objectAtIndex:indexPath.row];
    SelectTaskTypeViewController *taskTypeController = [[SelectTaskTypeViewController alloc] initWithStyle:UITableViewStyleGrouped 
                                                                                                   account:self.accountUuid tenantID:repositoryInfo.tenantID];
    [self.navigationController pushViewController:taskTypeController animated:YES];
    [taskTypeController release];
}

@end
