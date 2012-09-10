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

#import <QuartzCore/QuartzCore.h>
#import "PeoplePickerViewController.h"
#import "Utility.h"
#import "PeopleManager.h"
#import "AvatarHTTPRequest.h"
#import "AsyncLoadingUIImageView.h"
#import "ASIDownloadCache.h"
#import "PersonTableViewCell.h"
#import "ThemeProperties.h"
#import "FileUtils.h"

#define SEARCH_BAR_HEIGHT 40
#define BUTTON_BACKGROUND_HEIGHT 40
#define BUTTON_HEIGHT 30
#define PERSON_CELL_HEIGHT 70

#define RECENT_PEOPLE_INDEX_PERSON_OBJECT 0
#define RECENT_PEOPLE_INDEX_COUNT 1
#define RECENT_PEOPLE_INDEX_TIMESTAMP 2


@interface PeoplePickerViewController () <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, MBProgressHUDDelegate, PeopleManagerDelegate>

@property (nonatomic, retain) NSMutableDictionary *recentPeople;
@property BOOL showRecentPeople;

@property (nonatomic, retain) NSArray *searchResults;
@property (nonatomic, retain) MBProgressHUD *HUD;
@property (nonatomic, retain) NSString *accountUuid;
@property (nonatomic, retain) NSString *tenantID;

@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) UIView *buttonBackground;
@property (nonatomic, retain) UIButton *finishSelectionButton;
@property (nonatomic, retain) UIButton *deselectAllButton;

- (void) startHUD;
- (void) stopHUD;

@end

// Constants
NSString * const kRecentPeopleStoreFilename = @"RecentPeopleDataStore.plist";
NSInteger const kMaxNumberOfRecentPeople =  10;

@implementation PeoplePickerViewController

@synthesize searchResults = _searchResults;
@synthesize HUD = _HUD;
@synthesize accountUuid = _accountUuid;
@synthesize tenantID = _tenantID;

@synthesize selection = _selection;
@synthesize isMultipleSelection = _isMultipleSelection;

@synthesize searchBar = _searchBar;
@synthesize tableView = _tableView;
@synthesize buttonBackground = _buttonBackground;
@synthesize finishSelectionButton = _finishSelectionButton;
@synthesize deselectAllButton = _deselectAllButton;

@synthesize delegate = _delegate;
@synthesize recentPeople = _recentPeople;
@synthesize showRecentPeople = _showRecentPeople;


- (id)initWithAccount:(NSString *)uuid tenantID:(NSString *)tenantID
{
    self = [super init];
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
    [_selection release];
    [_tableView release];
    [_buttonBackground release];
    [_finishSelectionButton release];
    [_deselectAllButton release];
    [_searchBar release];

    [_recentPeople release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.title = NSLocalizedString(@"people.picker.title", nil);
    
    [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                             target:self
                                                                                             action:@selector(cancelEdit:)] autorelease]];
    self.searchResults = [NSArray array];
    if (!self.selection)
    {
        self.selection = [NSMutableArray array];
    }

    [self createSearchBar];
    [self createTableView];
    [self createFinishSelectionButton];
    [self createDeselectAllButton];

//    [self loadRecentPeople];
}

- (void)cancelEdit:(id)sender
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
    
    [tableView setEditing:YES];
    
    [tableView setAllowsMultipleSelectionDuringEditing:YES];
    
    self.tableView = tableView;
    [self.view addSubview:tableView];
    [tableView release];
}

- (void)createFinishSelectionButton
{
    // Background
    UIView *backgroundView = [[UIView alloc] init];
    backgroundView.backgroundColor = [ThemeProperties segmentedControlBkgColor];
    backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    self.buttonBackground = backgroundView;
    [self.view addSubview:self.buttonBackground];
    [backgroundView release];
    
    // Button
    UIButton *finishSelectionButton = [[UIButton alloc] init];
    [finishSelectionButton addTarget:self action:@selector(finishSelectionButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    UIImage *buttonImage = [[UIImage imageNamed:@"blue-button-30.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(1, 4, 1, 5)];
    [finishSelectionButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [finishSelectionButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    [finishSelectionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [finishSelectionButton setTitle:NSLocalizedString(@"people.picker.selection.button.attach", nil) forState:UIControlStateNormal];
    [finishSelectionButton setEnabled:NO];
    
    
    self.finishSelectionButton = finishSelectionButton;
    [finishSelectionButton release];
    
    [self.view addSubview:self.finishSelectionButton];
}

- (void)finishSelectionButtonTapped
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

- (void)createDeselectAllButton
{
    UIButton *deselectAllButton = [[UIButton alloc] init];
    deselectAllButton.enabled = NO;
    UIImage *buttonImage = [[UIImage imageNamed:@"red-button-30.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(1, 4, 1, 5)];
    [deselectAllButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [deselectAllButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    [deselectAllButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [deselectAllButton setTitle:NSLocalizedString(@"people.picker.deselectAll", nil) forState:UIControlStateNormal];
    [deselectAllButton addTarget:self action:@selector(deselectAllButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    self.deselectAllButton = deselectAllButton;
    [deselectAllButton release];
    
    [self.view addSubview:self.deselectAllButton];
}

- (void)deselectAllButtonPressed
{
    // Remove all selections from the model
    [self.selection removeAllObjects];
    
    // Update UI's
    
    [self selectionDidUpdate];
    [self.tableView reloadData];
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
                                      self.view.frame.size.height - BUTTON_BACKGROUND_HEIGHT - currentHeight);

    // Buttons
    CGRect backgroundViewFrame = CGRectMake(0,
                                            self.tableView.frame.origin.y + self.tableView.frame.size.height,
                                            self.view.frame.size.width,
                                            BUTTON_BACKGROUND_HEIGHT);
    self.buttonBackground.frame = backgroundViewFrame;

    CGFloat margin = 20;
    CGFloat buttonWidth = (backgroundViewFrame.size.width - (3 * margin)) / 2;
    self.deselectAllButton.frame = CGRectMake(margin,
                                              backgroundViewFrame.origin.y + (backgroundViewFrame.size.height - BUTTON_HEIGHT) / 2,
                                              buttonWidth,
                                              BUTTON_HEIGHT);

    self.finishSelectionButton.frame = CGRectMake(
                                                  self.deselectAllButton.frame.origin.x + self.deselectAllButton.frame.size.width + margin,
                                                  self.deselectAllButton.frame.origin.y,
                                                  buttonWidth,
                                                  BUTTON_HEIGHT);
}

#pragma mark Recent People methods

- (void)loadRecentPeople
{
    NSMutableDictionary *recentPeople = [NSKeyedUnarchiver unarchiveObjectWithFile:[FileUtils pathToConfigFile:kRecentPeopleStoreFilename]];
    if (!recentPeople)
    {
         recentPeople = [NSMutableDictionary dictionary];
    }
    self.showRecentPeople = YES;
    self.recentPeople = recentPeople;
    [self.tableView reloadData];
}

- (void)synchronizeRecentPeopleDataStore
{
    // Add the people which aren't part of the cache yet
    for (Person *selectedPerson in self.selection)
    {
        NSNumber *count = [NSNumber numberWithInt:1];
        NSDate *lastUsage = [NSDate date];

        // Check if already present
        NSArray *previousPersonEntry = [self.recentPeople objectForKey:selectedPerson.userName];
        if (previousPersonEntry)
        {
            NSNumber *previousCount = [previousPersonEntry objectAtIndex:RECENT_PEOPLE_INDEX_COUNT];
            count = [NSNumber numberWithInt:(previousCount.intValue + 1)];
        }

        [self.recentPeople setObject:[NSArray arrayWithObjects:selectedPerson, count, lastUsage, nil] forKey:selectedPerson.userName];
    }

    // If cache size is too big, we need to remove some entries
    while (self.recentPeople.count > kMaxNumberOfRecentPeople)
    {
        [self pruneRecentPeople];
    }

    // Write cache to disk
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.recentPeople];
    NSError *error = nil;
    NSString *path = [FileUtils pathToConfigFile:kRecentPeopleStoreFilename];
    [data writeToFile:path options:NSDataWritingAtomic error:&error];

    if (error)
    {
        NSLog(@"[WARNING] Could not write recent people to disk: %@", error.localizedDescription);
    }
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
    if (userNameOfOldestEntry != nil && userNameOfEntryWithLeastCounts != nil
            && [userNameOfOldestEntry isEqualToString:userNameOfEntryWithLeastCounts])
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.searchResults && self.searchResults.count > 0)
    {
        return self.searchResults.count;
    }
    else if (self.recentPeople && self.recentPeople.count > 0)
    {
        return self.recentPeople.count;
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
    if (self.searchResults && self.searchResults.count > 0)
    {
        Person *person = [self.searchResults objectAtIndex:indexPath.row];
        return [self createPersonCellForTableView:tableView indexPath:indexPath
                            userName:person.userName firstName:person.firstName lastName:person.lastName];
    }
    else if (self.recentPeople && self.recentPeople.count > 0)
    {
        NSString *userName = [self.recentPeople.allKeys objectAtIndex:indexPath.row];
        Person *person = [((NSArray *) [self.recentPeople objectForKey:userName]) objectAtIndex:RECENT_PEOPLE_INDEX_PERSON_OBJECT];
        return [self createPersonCellForTableView:tableView indexPath:indexPath
                            userName:person.userName firstName:person.firstName lastName:person.lastName];
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

- (UITableViewCell *)createPersonCellForTableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
        userName:(NSString *)userName firstName:(NSString *)firstName lastName:(NSString *)lastName
{
    static NSString *kCellID = @"cell";

    PersonTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID];
    if (cell == nil)
    {
        cell = [[[PersonTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellID] autorelease];
    }

    cell.personLabel.text = [NSString stringWithFormat:@"%@ %@", (firstName != nil) ? firstName : @"", (lastName != nil) ? lastName : @"" ];
    cell.selected = [self indexOfPersonSelected:userName] >= 0;

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

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // If single-select, clear anything that was selected before
    if (self.isMultipleSelection == NO)
    {
        // Remove from model
        [self.selection removeAllObjects];
        
        // Deselect if the tableView is still the same
        NSIndexPath *previousIndexPath = [self.tableView indexPathForSelectedRow];
        if (previousIndexPath)
        {
            [self.tableView deselectRowAtIndexPath:previousIndexPath animated:YES];
        }
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Person *person = nil;
    if (self.searchResults && self.searchResults.count > 0)
    {
        person = [self.searchResults objectAtIndex:indexPath.row];

    }
    else if (self.recentPeople && self.recentPeople.count > 0)
    {
        NSString *userName = [self.recentPeople.allKeys objectAtIndex:indexPath.row];
        person = [((NSArray *) [self.recentPeople objectForKey:userName]) objectAtIndex:RECENT_PEOPLE_INDEX_PERSON_OBJECT];
    }

    if (person)
    {
        [self.selection addObject:person];
        [self selectionDidUpdate];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Person *person = nil;
    if (self.searchResults && self.searchResults.count > 0)
    {
        person = [self.searchResults objectAtIndex:indexPath.row];
    }

    if (person)
    {
        int selectionIndex = [self indexOfPersonSelected:person.userName];
        if (selectionIndex >= 0)
        {
            [self.selection removeObjectAtIndex:selectionIndex];
        }

        [self selectionDidUpdate];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( (self.searchResults && self.searchResults.count > 0)
        || (self.recentPeople && self.recentPeople.count > 0))
    {
        return YES;
    }
    else 
    {
        return NO;
    }
}

- (void)selectionDidUpdate
{
    if (self.selection.count > 0)
    {
        NSString *itemText = self.selection.count > 1 ? NSLocalizedString(@"people.picker.persons", nil) : NSLocalizedString(@"people.picker.person", nil);
    
        self.deselectAllButton.enabled = YES;
        self.finishSelectionButton.enabled = YES;
        if (!IS_IPAD) // IPhone doesn't have enough space to add the whole shabang
        {
            [self.finishSelectionButton setTitle:[NSString stringWithFormat:@"%@ (%d)",
                                                  NSLocalizedString(@"people.picker.selection.button.attach", nil), 
                                                  self.selection.count] forState:UIControlStateNormal];
        }
        else if (self.selection.count > 1)
        {
            [self.finishSelectionButton setTitle:[NSString stringWithFormat:@"%@ %d %@",
                                                  NSLocalizedString(@"people.picker.selection.button.attach", nil), 
                                                  self.selection.count, itemText] forState:UIControlStateNormal];
        }
        else
        {
            [self.finishSelectionButton setTitle:[NSString stringWithFormat:@"%@ %@",
                                                  NSLocalizedString(@"people.picker.selection.button.attach", nil), 
                                                  itemText] forState:UIControlStateNormal];
        }
    }
    else
    {
        self.deselectAllButton.enabled = NO;
        self.finishSelectionButton.enabled = NO;
        [self.finishSelectionButton setTitle:NSLocalizedString(@"people.picker.selection.button.attach", nil) forState:UIControlStateNormal];
    }
}

- (int) indexOfPersonSelected:(NSString *)userName
{
    for (Person *selectedPerson in self.selection) {
        if ([selectedPerson.userName isEqualToString:userName])
        {
            return [self.selection indexOfObject:selectedPerson];
        }
    }
    return -1;
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

    self.showRecentPeople = NO;
    [self.tableView reloadData];
    
    for (int i = 0; i <  self.searchResults.count; i++) {
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
