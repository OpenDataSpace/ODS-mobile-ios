//
//  PeoplePickerViewController.m
//  FreshDocs
//
//  Created by Tijs Rademakers on 24/08/2012.
//  Copyright (c) 2012 U001b. All rights reserved.
//

#import "PeoplePickerViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "MBProgressHUD.h"
#import "Utility.h"
#import "PeopleManager.h"
#import "AccountManager.h"
#import "Person.h"
#import "AvatarHTTPRequest.h"
#import "AsyncLoadingUIImageView.h"
#import "ASIDownloadCache.h"
#import "PersonTableViewCell.h"

@interface PeoplePickerViewController () <MBProgressHUDDelegate, PeopleManagerDelegate>

@property (nonatomic, retain) NSArray *searchResults;
@property (nonatomic, retain) MBProgressHUD *HUD;

- (void) startHUD;
- (void) stopHUD;

@end

@implementation PeoplePickerViewController

@synthesize searchResults = _searchResults;
@synthesize HUD = _HUD;
@synthesize delegate = _delegate;

- (void)dealloc
{
    [_searchResults release];
    [_HUD release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.title = @"Choose assignee";
    
    self.searchResults = [NSArray array];
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
    [searchBar sizeToFit];
    searchBar.delegate = self;
    searchBar.placeholder = @"Search";
    self.tableView.tableHeaderView = searchBar;
    
    [searchBar release];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

#pragma mark -
#pragma mark UITableView data source and delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.searchResults count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *kCellID = @"cell";
    
    PersonTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID];
    
    if (cell == nil)
    {
        cell = [[[PersonTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellID] autorelease];
    }
    
    Person *person = [self.searchResults objectAtIndex:indexPath.row];
    
    cell.personLabel.text = [NSString stringWithFormat:@"%@ %@", person.firstName, person.lastName];
    
    if (person.userName)
    {
        AccountInfo *account = [[[AccountManager sharedManager] activeAccounts] objectAtIndex:0];
        
        // Set url for async loading of assignee avatar picture
        AvatarHTTPRequest *avatarHTTPRequest = [AvatarHTTPRequest
                                                httpRequestAvatarForUserName:person.userName
                                                accountUUID:account.uuid
                                                tenantID:nil];
        avatarHTTPRequest.secondsToCache = 86400; // a day
        avatarHTTPRequest.downloadCache = [ASIDownloadCache sharedCache];
        [avatarHTTPRequest setCachePolicy:ASIOnlyLoadIfNotCachedCachePolicy];
        [cell.personImageView setImageWithRequest:avatarHTTPRequest];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate)
    {
        Person *person = [self.searchResults objectAtIndex:indexPath.row];
        [self.delegate personPicked:person];
        self.delegate = nil;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark UISearchBar Delegate Methods

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    if (searchBar.text.length > 1)
    {
        [self startHUD];
        [[PeopleManager sharedManager] setDelegate:self];
        AccountInfo *account = [[[AccountManager sharedManager] activeAccounts] objectAtIndex:0];
        [[PeopleManager sharedManager] startPeopleSearchRequestWithQuery:searchBar.text accountUUID:account.uuid tenantID:nil];
    }
}

#pragma mark - PeopleManagerDelegate Methods

- (void)peopleRequestFinished:(NSArray *)people
{
    NSMutableArray *peopleArray = [NSMutableArray arrayWithCapacity:people.count];
    for (NSDictionary *personDict in people) {
        Person *person = [[Person alloc] initWithJsonDictionary:personDict];
        [peopleArray addObject:person];
        [person release];
    }
    
    if (people.count == 0)
    {
        Person *person = [[Person alloc] init];
        person.firstName = @"No people found";
        [peopleArray addObject:person];
    }
    
    self.searchResults = [NSArray arrayWithArray:peopleArray];
    [self.tableView reloadData];
    
    [self stopHUD];
}

- (void)peopleRequestFailed:(PeopleManager *)peopleManager
{
    Person *person = [[Person alloc] init];
    person.firstName = @"Failed to search for people";
    self.searchResults = [NSArray arrayWithObject:person];
    [self stopHUD];
}

#pragma mark - MBProgressHUD Helper Methods
- (void)startHUD
{
	if (!self.HUD)
    {
        self.HUD = createAndShowProgressHUDForView(self.navigationController.view);
	}
}

- (void)stopHUD
{
	if (self.HUD)
    {
        stopProgressHUD(self.HUD);
		self.HUD = nil;
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
