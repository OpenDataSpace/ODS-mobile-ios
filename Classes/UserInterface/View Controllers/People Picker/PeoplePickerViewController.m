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
#import "ThemeProperties.h"

#define SEARCH_BAR_HEIGHT 40
#define SITE_TYPE_SELECTION_DEFAULT_SELECTED_SEGMENT 0
#define BUTTON_BACKGROUND_HEIGHT 40
#define BUTTON_HEIGHT 30
#define BUTTON_WIDTH  200
#define PERSON_CELL_HEIGHT 70


@interface PeoplePickerViewController () <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, MBProgressHUDDelegate, PeopleManagerDelegate>

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
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
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
                ? person.firstName : @"", (person.lastName != nil) ? person.lastName : @"" ];
        
        if ([self indexOfPersonSelected:person] >= 0)
        {
            [cell setSelected:YES];
        }
        else 
        {
            [cell setSelected:NO];
        }

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
    if (self.searchResults)
    {
        Person *person = [self.searchResults objectAtIndex:indexPath.row];
        
        [self.selection addObject:person];
        
        [self selectionDidUpdate];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.searchResults)
    {
        Person *person = [self.searchResults objectAtIndex:indexPath.row];
        
        int selectionIndex = [self indexOfPersonSelected:person];
        
        if (selectionIndex >= 0)
        {
            [self.selection removeObjectAtIndex:selectionIndex];
        }
        
        [self selectionDidUpdate];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.searchResults)
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

- (int) indexOfPersonSelected:(Person *)person
{
    for (Person *selectedPerson in self.selection) {
        if ([selectedPerson.userName isEqualToString:person.userName])
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

    [self.tableView reloadData];
    
    for (int i = 0; i <  self.searchResults.count; i++) {
        Person *person = [self.searchResults objectAtIndex:i];
        if ([self indexOfPersonSelected:person] >= 0)
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
