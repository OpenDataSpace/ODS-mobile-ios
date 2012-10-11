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
#import "Utility.h"
#import "PeopleManager.h"
#import "AvatarHTTPRequest.h"
#import "AsyncLoadingUIImageView.h"
#import "ASIDownloadCache.h"
#import "PersonTableViewCell.h"
#import "FileUtils.h"

#define SEARCH_BAR_HEIGHT 40
#define PERSON_CELL_HEIGHT_IPAD 70
#define PERSON_CELL_HEIGHT_IPHONE 40

// Used for storing the cache on disk
#define RECENT_PEOPLE_INDEX_PERSON_OBJECT 0
#define RECENT_PEOPLE_INDEX_COUNT 1
#define RECENT_PEOPLE_INDEX_TIMESTAMP 2


@interface PeoplePickerViewController () <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, MBProgressHUDDelegate, PeopleManagerDelegate>

@property(nonatomic, retain) NSString *recentPeopleStoreFileName;
@property(nonatomic, retain) NSMutableDictionary *recentPeople;

// We're sorting the user names separately.
@property(nonatomic, retain) NSArray *sortedRecentPeopleUserNames;

@property BOOL showRecentPeople;

@property(nonatomic, retain) NSArray *searchResults;
@property(nonatomic, retain) MBProgressHUD *HUD;
@property(nonatomic, retain) NSString *accountUuid;
@property(nonatomic, retain) NSString *tenantID;

@property(nonatomic, retain) UISearchBar *searchBar;
@property(nonatomic, retain) UITableView *tableView;

- (void)startHUD;
- (void)stopHUD;

@end

// Constants
NSString *const kRecentPeopleStoreFilenameTemplate = @"RecentPeopleDataStore-%@-%@.plist";
NSInteger const kMaxNumberOfRecentPeople = 10;

@implementation PeoplePickerViewController

@synthesize searchResults = _searchResults;
@synthesize HUD = _HUD;
@synthesize accountUuid = _accountUuid;
@synthesize tenantID = _tenantID;

@synthesize selection = _selection;
@synthesize isMultipleSelection = _isMultipleSelection;

@synthesize searchBar = _searchBar;
@synthesize tableView = _tableView;

@synthesize delegate = _delegate;
@synthesize recentPeople = _recentPeople;
@synthesize showRecentPeople = _showRecentPeople;
@synthesize recentPeopleStoreFileName = _recentPeopleStoreFileName;
@synthesize sortedRecentPeopleUserNames = _sortedRecentPeopleUserNames;


- (id)initWithAccount:(NSString *)uuid tenantID:(NSString *)tenantID
{
    self = [super init];
    if (self)
    {
        self.accountUuid = uuid;
        self.tenantID = tenantID;

        self.recentPeopleStoreFileName = [NSString stringWithFormat:kRecentPeopleStoreFilenameTemplate,
                                                                    (uuid) ? uuid : @"", (tenantID) ? tenantID : @""];
    }
    return self;
}

- (void)dealloc
{
    [_searchResults release];
    [_HUD release];
    [_accountUuid release];
    [_tenantID release];
    [_selection release];
    [_tableView release];
    [_searchBar release];

    [_recentPeople release];
    [_recentPeopleStoreFileName release];
    [_sortedRecentPeopleUserNames release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"people.picker.title", nil);

    [self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                             target:self
                                                                                             action:@selector(cancelButtonTapped)] autorelease]];

    UIBarButtonItem *doneButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                 target:self
                                                                                 action:@selector(peopleSelectionDone)] autorelease];
    [doneButton setTitle:NSLocalizedString(@"people.picker.done", nil)];
    styleButtonAsDefaultAction(doneButton);
    [self.navigationItem setRightBarButtonItem:doneButton];

    if (!self.selection)
    {
        self.selection = [NSMutableArray array];
    }

    [self createSearchBar];
    [self createTableView];

    [self loadRecentPeople];
}

- (void)cancelButtonTapped
{
    [self removeFromCurrentViewControllerStack];
}

- (void)removeFromCurrentViewControllerStack
{
    if ([self.navigationController viewControllers].count == 1)
    {
        [self dismissModalViewControllerAnimated:YES];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)createSearchBar
{
    // Searchbar view
    UISearchBar *searchBar = [[UISearchBar alloc] init];
    searchBar.barStyle = UIBarStyleBlackOpaque;
    searchBar.placeholder = NSLocalizedString(@"people.picker.search", nil);
    self.searchBar = searchBar;
    [searchBar release];
    [self.view addSubview:self.searchBar];

    // Searchbar delegate
    self.searchBar.delegate = self;
}

- (void)createTableView
{
    UITableView *tableView = [[UITableView alloc] init];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    tableView.delegate = self;
    tableView.dataSource = self;

    [tableView setEditing:self.isMultipleSelection];
    [tableView setAllowsMultipleSelectionDuringEditing:YES];

    self.tableView = tableView;
    [self.view addSubview:tableView];
    [tableView release];
}

// Here is where all the frames are set
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    // Site selection
    CGFloat currentHeight = 0;
    self.searchBar.frame = CGRectMake(0, currentHeight, self.view.frame.size.width, SEARCH_BAR_HEIGHT);
    currentHeight += SEARCH_BAR_HEIGHT;

    // TableView
    self.tableView.frame = CGRectMake(0, currentHeight, self.view.frame.size.width,
            self.view.frame.size.height - currentHeight);
}

#pragma mark Cancel or finish selection

- (void)peopleSelectionDone
{
    // Sync the selected people to the recent people
    [self synchronizeRecentPeopleDataStore];

    // Inform delegates and remove popup/popover
    if (self.delegate)
    {
        [self.delegate personsPicked:self.selection];
    }

    if ([self.navigationController viewControllers].count == 1)
    {
        [self dismissModalViewControllerAnimated:YES];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark Recent People methods

- (void)loadRecentPeople
{
    NSMutableDictionary *recentPeople = [NSKeyedUnarchiver unarchiveObjectWithFile:[FileUtils pathToConfigFile:self.recentPeopleStoreFileName]];
    if (!recentPeople)
    {
        recentPeople = [NSMutableDictionary dictionary];
    }

    // See https://issues.alfresco.com/jira/browse/MOBILE-719
    // Add any previously selected person
    if (self.selection)
    {
        for (Person *previouslySelectedPerson in self.selection)
        {
            if ([recentPeople objectForKey:previouslySelectedPerson.userName] == nil)
            {
                [recentPeople setValue:[self personToStorableArrayForRecentPeopleCache:previouslySelectedPerson] forKey:previouslySelectedPerson.userName];
            }
        }
    }

    self.showRecentPeople = YES;
    self.recentPeople = recentPeople;
    [self sortRecentPeople];

    [self.tableView reloadData];
}

- (void)synchronizeRecentPeopleDataStore
{
    // Add the people which aren't part of the cache yet
    for (Person *selectedPerson in self.selection)
    {
        [self.recentPeople setObject:[self personToStorableArrayForRecentPeopleCache:selectedPerson] forKey:selectedPerson.userName];
    }

    // If cache size is too big, we need to remove some entries
    while (self.recentPeople.count > kMaxNumberOfRecentPeople)
    {
        [self pruneRecentPeople];
    }

    // Write cache to disk
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.recentPeople];
    NSError *error = nil;
    NSString *path = [FileUtils pathToConfigFile:self.recentPeopleStoreFileName];
    [data writeToFile:path options:NSDataWritingAtomic error:&error];

    if (error)
    {
        NSLog(@"[WARNING] Could not write recent people to disk: %@", error.localizedDescription);
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    }
}

- (NSArray *)personToStorableArrayForRecentPeopleCache:(Person *)person
{
    NSNumber *count = [NSNumber numberWithInt:1];
    NSDate *lastUsage = [NSDate date];

    // Check if already present
    NSArray *previousPersonEntry = [self.recentPeople objectForKey:person.userName];
    if (previousPersonEntry)
    {
        NSNumber *previousCount = [previousPersonEntry objectAtIndex:RECENT_PEOPLE_INDEX_COUNT];
        count = [NSNumber numberWithInt:(previousCount.intValue + 1)];
    }
    return [NSArray arrayWithObjects:person, count, lastUsage, nil];
}

- (void)pruneRecentPeople
{
    // Find the oldest entry and find the entry with the least counts
    NSString *userNameOfOldestEntry = nil;
    NSDate *oldestDate = nil;
    NSString *userNameOfEntryWithLeastCounts = nil;
    int oldestCount = -1;

    for (NSString *userName in self.recentPeople)
    {
        if ([self indexOfPersonSelected:userName] == -1)  // ie. the user has not selected this person this time
        {
            NSArray *currentPersonEntry = [self.recentPeople objectForKey:userName];
            int currentPersonCount = ((NSNumber *) [currentPersonEntry objectAtIndex:RECENT_PEOPLE_INDEX_COUNT]).intValue;
            NSDate *currentPersonTimeStamp = [currentPersonEntry objectAtIndex:RECENT_PEOPLE_INDEX_TIMESTAMP];

            if (!oldestDate || [oldestDate compare:currentPersonTimeStamp] == NSOrderedDescending)
            {
                userNameOfOldestEntry = userName;
                oldestDate = currentPersonTimeStamp;
            }

            if (oldestCount == -1 || oldestCount > currentPersonCount)
            {
                userNameOfEntryWithLeastCounts = userName;
                oldestCount = currentPersonCount;
            }
        }
    }

    // If the oldest is equal to the one with least counts, it's easy: we just delete that one
    if (userNameOfOldestEntry != nil && userNameOfEntryWithLeastCounts != nil && [userNameOfOldestEntry isEqualToString:userNameOfEntryWithLeastCounts])
    {
        [self.recentPeople removeObjectForKey:userNameOfOldestEntry];
    }
            // Otherwise, we remove the one with the least counts, but we also subtract the count of the oldest, such that it has more chance to be removed next time
    else if (userNameOfOldestEntry != nil && userNameOfEntryWithLeastCounts != nil)
    {
        [self.recentPeople removeObjectForKey:userNameOfEntryWithLeastCounts];

        NSArray *oldestPersonEntry = [self.recentPeople objectForKey:userNameOfOldestEntry];
        int previousCount = ((NSNumber *) [oldestPersonEntry objectAtIndex:RECENT_PEOPLE_INDEX_COUNT]).intValue;
        [self.recentPeople setValue:[NSArray arrayWithObjects:[oldestPersonEntry objectAtIndex:0],
                                                              [NSNumber numberWithInt:(previousCount - 1)],
                                                              [oldestPersonEntry objectAtIndex:2], nil]
                             forKey:userNameOfOldestEntry];
    }
    // If no entries matched our requirements, this means that the user added many new entries at once. We just randomly pick on.
    else
    {
        [self.recentPeople removeObjectForKey:[self.recentPeople.allKeys objectAtIndex:0]];
    }
}

#pragma mark -
#pragma mark UITableView data source and delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.searchResults)
    {
        return 2;
    }
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.searchResults && section == 0)
    {
        return self.searchResults.count;
    }
    else if (self.recentPeople && self.recentPeople.count > 0)
    {
        return self.recentPeople.count;
    }
    return 1;  // For the 'no results' cell
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.searchResults)
    {
        if (section == 0)
        {
            return [NSString stringWithFormat:NSLocalizedString(@"people.picker.search.results", nil), self.searchBar.text];
        }
        else
        {
            return NSLocalizedString(@"people.picker.recently.selected", nil);
        }
    }
    // Only recents are shown if there are no search results
    return NSLocalizedString(@"people.picker.recently.selected", nil);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return IS_IPAD ? PERSON_CELL_HEIGHT_IPAD : PERSON_CELL_HEIGHT_IPHONE;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Person *person = [self personForIndexPath:indexPath];

    if (person)
    {
        return [self createPersonCellForTableView:tableView indexPath:indexPath
                                           userName:person.userName firstName:person.firstName lastName:person.lastName];
    }

    UITableViewCell *noResultsCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
    noResultsCell.textLabel.text = NSLocalizedString(@"people.picker.no.results", nil);
    noResultsCell.textLabel.font = [UIFont boldSystemFontOfSize:18];
    noResultsCell.textLabel.textColor = [UIColor grayColor];
    noResultsCell.textLabel.textAlignment = UITextAlignmentCenter;
    noResultsCell.selectionStyle = UITableViewCellSelectionStyleNone;
    return noResultsCell;
}

- (UITableViewCell *)createPersonCellForTableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
                                         userName:(NSString *)userName firstName:(NSString *)firstName lastName:(NSString *)lastName
{
    static NSString *kCellID = @"cell";

    PersonTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID];
    if (cell == nil)
    {
        cell = [[[PersonTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellID] autorelease];
    }

    cell.personLabel.text = [NSString stringWithFormat:@"%@ %@", (firstName != nil) ? firstName : @"", (lastName != nil) ? lastName : @""];

    if ([self indexOfPersonSelected:userName] >= 0)
    {
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }

    if (userName)
    {
        // Set url for async loading of assignee avatar picture
        AvatarHTTPRequest *avatarHTTPRequest = [AvatarHTTPRequest
                httpRequestAvatarForUserName:userName
                                 accountUUID:self.accountUuid
                                    tenantID:self.tenantID];
        avatarHTTPRequest.secondsToCache = 86400; // a day
        avatarHTTPRequest.downloadCache = [ASIDownloadCache sharedCache];
        [avatarHTTPRequest setCachePolicy:ASIOnlyLoadIfNotCachedCachePolicy];
        [cell.personImageView setImageWithRequest:avatarHTTPRequest];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Person *person = [self personForIndexPath:indexPath];

    // Add it to the collection of selected people
    if (person)
    {
        if (!self.isMultipleSelection)
        {
            [self.selection removeAllObjects];
        }
        [self.selection addObject:person];
    }

    // If single select -> we're done!
    if (!self.isMultipleSelection)
    {
        [self peopleSelectionDone];
    }
    else
    {
        // See https://issues.alfresco.com/jira/browse/MOBILE-719
        // If you select one from the search results, which isn't in the recent list,
        // that person should be added to the recent list
        if ([self.recentPeople objectForKey:person.userName] == nil)
        {
            [self.recentPeople setValue:[self personToStorableArrayForRecentPeopleCache:person] forKey:person.userName];
            [self sortRecentPeople];
            [tableView reloadData];
        }
        else
        {
            [self reloadCellsWithSamePersonAsIndexPath:indexPath];
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Person *person = [self personForIndexPath:indexPath];

    if (person)
    {
        int selectionIndex = [self indexOfPersonSelected:person.userName];
        if (selectionIndex >= 0)
        {
            [self.selection removeObjectAtIndex:selectionIndex];
            [self reloadCellsWithSamePersonAsIndexPath:indexPath];
        }
    }
}

- (void)reloadCellsWithSamePersonAsIndexPath:(NSIndexPath *)indexPath
{
    Person *changedPerson = [self personForIndexPath:indexPath];

    NSMutableArray *indexPaths = [NSMutableArray array];

    // Find all the other cells with the same person
    if (self.searchResults != nil && self.searchResults.count > 0)
    {
        for (uint i=0; i<self.searchResults.count; i++)
        {
            Person *searchedPerson = [self.searchResults objectAtIndex:i];
            if ([changedPerson.userName isEqualToString:searchedPerson.userName])
            {
                [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
                break; // only one in each collection
            }
        }
    }

    if (self.recentPeople != nil && self.recentPeople.count > 0)
    {
        for (uint i=0; i<self.sortedRecentPeopleUserNames.count; i++)
        {
            NSString *recentPersonUserName = [self.sortedRecentPeopleUserNames objectAtIndex:i];
            if ([recentPersonUserName isEqualToString:changedPerson.userName])
            {
                [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:(self.searchResults == nil ? 0 : 1)]];
                break; // only one in each collection
            }
        }
    }

    // Reload cells
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((indexPath.section == 0 && self.searchResults && self.searchResults.count > 0)
            || (indexPath.section == 1 && self.recentPeople && self.recentPeople.count > 0))
    {
        return YES;
    }
    return NO;
}

- (int)indexOfPersonSelected:(NSString *)userName
{
    for (uint i=0; i<self.selection.count; i++)
    {
        Person *selectedPerson = [self.selection objectAtIndex:i];
        if ([selectedPerson.userName isEqualToString:userName])
        {
            return i;
        }
    }
    return -1;
}

#pragma mark Helper methods

- (Person *)personForIndexPath:(NSIndexPath *)indexPath
{
    Person *person = nil;
    if (self.searchResults && indexPath.section == 0)
    {
        person = [self.searchResults objectAtIndex:indexPath.row];
    }
    else if ((self.searchResults && indexPath.section == 1 && self.recentPeople && self.recentPeople.count > 0)
            || (self.recentPeople && indexPath.section == 0 && self.recentPeople.count > 0))
    {
        NSString *userName = [self.sortedRecentPeopleUserNames objectAtIndex:indexPath.row];
        person = [((NSArray *) [self.recentPeople objectForKey:userName]) objectAtIndex:RECENT_PEOPLE_INDEX_PERSON_OBJECT];
    }
    return person;
}

- (void)sortRecentPeople
{
    self.sortedRecentPeopleUserNames = [[self.recentPeople allKeys] sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        Person *firstPerson = [[self.recentPeople objectForKey:a] objectAtIndex:RECENT_PEOPLE_INDEX_PERSON_OBJECT];
        Person *secondPerson = [[self.recentPeople objectForKey:b] objectAtIndex:RECENT_PEOPLE_INDEX_PERSON_OBJECT];

        NSString *first = [NSString stringWithFormat:@"%@ %@", firstPerson.firstName, firstPerson.lastName];
        NSString *second = [NSString stringWithFormat:@"%@ %@", secondPerson.firstName, secondPerson.lastName];
        return [first compare:second];
    }];
}

#pragma mark UISearchBar Delegate Methods

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    if (searchBar.text.length > 1)
    {
        [self startHUD];
        [self.searchBar resignFirstResponder];
        [[PeopleManager sharedManager] setDelegate:self];
        [[PeopleManager sharedManager] startPeopleSearchRequestWithQuery:searchBar.text accountUUID:self.accountUuid tenantID:self.tenantID];
    }
}

#pragma mark - PeopleManagerDelegate Methods

- (void)peopleRequestFinished:(NSArray *)people
{
    NSMutableArray *peopleArray = [NSMutableArray arrayWithCapacity:people.count];
    for (NSDictionary *personDict in people)
    {
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

    self.showRecentPeople = NO;
    [self.tableView reloadData];

    for (int i = 0; i < self.searchResults.count; i++)
    {
        Person *person = [self.searchResults objectAtIndex:i];
        if ([self indexOfPersonSelected:person.userName] >= 0)
        {
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
        }
    }

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
