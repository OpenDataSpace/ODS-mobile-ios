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
//  PeoplePickerViewController.m
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

#define PERSON_CELL_HEIGHT 70

@interface PeoplePickerViewController () <MBProgressHUDDelegate, PeopleManagerDelegate>

@property (nonatomic, retain) NSArray *searchResults;
@property (nonatomic, retain) MBProgressHUD *HUD;
@property (nonatomic, retain) NSString *accountUuid;
@property (nonatomic, retain) NSString *tenantID;

- (void) startHUD;
- (void) stopHUD;

@end

@implementation PeoplePickerViewController

@synthesize searchResults = _searchResults;
@synthesize HUD = _HUD;
@synthesize accountUuid = _accountUuid;
@synthesize tenantID = _tenantID;
@synthesize delegate = _delegate;

- (id)initWithStyle:(UITableViewStyle)style account:(NSString *)uuid tenantID:(NSString *)tenantID
{
    self = [super initWithStyle:style];
    if (self) {
        self.accountUuid = uuid;
        self.tenantID = tenantID;
    }
    return self;
}

- (void)dealloc
{
    [_searchResults release];
    [_HUD release];
    [_accountUuid release];
    [_tenantID release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.title = NSLocalizedString(@"people.picker.title", nil);
    
    self.searchResults = [NSArray array];
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
    searchBar.barStyle = UIBarStyleBlackOpaque;
    [searchBar sizeToFit];
    searchBar.delegate = self;
    searchBar.placeholder = NSLocalizedString(@"people.picker.search", nil);

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
    if (self.searchResults)
    {
        return self.searchResults.count;
    }
    else
    {
        return 1; // For the 'no results' cell
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return PERSON_CELL_HEIGHT;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.searchResults)
    {
        static NSString *kCellID = @"cell";

        PersonTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID];

        if (cell == nil)
        {
            cell = [[[PersonTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellID] autorelease];
        }

        Person *person = [self.searchResults objectAtIndex:indexPath.row];

        cell.personLabel.text = [NSString stringWithFormat:@"%@ %@", (person.firstName != nil)
                ? person.firstName : @"", (person.lastName != nil) ? person.lastName : @"" ] ;

        if (person.userName)
        {
            // Set url for async loading of assignee avatar picture
            AvatarHTTPRequest *avatarHTTPRequest = [AvatarHTTPRequest
                                                    httpRequestAvatarForUserName:person.userName
                                                    accountUUID:self.accountUuid
                                                    tenantID:self.tenantID];
            avatarHTTPRequest.secondsToCache = 86400; // a day
            avatarHTTPRequest.downloadCache = [ASIDownloadCache sharedCache];
            [avatarHTTPRequest setCachePolicy:ASIOnlyLoadIfNotCachedCachePolicy];
            [cell.personImageView setImageWithRequest:avatarHTTPRequest];
        }
        return cell;
    }
    else
    {
        UITableViewCell *noResultsCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
        noResultsCell.textLabel.text = NSLocalizedString(@"people.picker.no.results", nil);
        noResultsCell.textLabel.font = [UIFont boldSystemFontOfSize:18];
        noResultsCell.textLabel.textColor = [UIColor grayColor];
        noResultsCell.textLabel.textAlignment = UITextAlignmentCenter;
        noResultsCell.selectionStyle = UITableViewCellSelectionStyleNone;
        return noResultsCell;
    }

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.searchResults)
    {
        if (self.delegate)
        {
            Person *person = [self.searchResults objectAtIndex:indexPath.row];
            [self.delegate personPicked:person];
            self.delegate = nil;
        }
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark -
#pragma mark UISearchBar Delegate Methods

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    if (searchBar.text.length > 1)
    {
        [self startHUD];
        [[PeopleManager sharedManager] setDelegate:self];
        [[PeopleManager sharedManager] startPeopleSearchRequestWithQuery:searchBar.text accountUUID:self.accountUuid tenantID:self.tenantID];
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

    if (peopleArray.count > 0)
    {
        self.searchResults = [NSArray arrayWithArray:peopleArray];
    }
    else
    {
        self.searchResults = nil;
    }

    [self.tableView reloadData];
    
    [self stopHUD];
}

- (void)peopleRequestFailed:(PeopleManager *)peopleManager
{
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
