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
//  MoreViewController.m
//

#import "MoreViewController.h"
#import "Theme.h"
#import "IFTextViewTableView.h"
#import "IFTemporaryModel.h"
#import "IFButtonCellController.h"
#import "IpadSupport.h"
#import "AboutViewController.h"
#import "TableCellViewController.h"
#import "Utility.h"
#import "ActivitiesTableViewController.h"
#import "AppProperties.h"
#import "FDSettingsViewController.h"
#import "AccountSettingsViewController.h"
#import "AccountManager.h"
#import "HelpViewController.h"
#import "AccountCellController.h"
#import "DownloadsViewController.h"
#import "SearchViewController.h"

@interface MoreViewController(private)
- (void) startHUD;
- (void) stopHUD;
@end

@implementation MoreViewController
@synthesize HUD = _HUD;
@synthesize manageAccountsCell = _manageAccountsCell;

- (void) dealloc 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_HUD release];
    [_manageAccountsCell release];
    
    [super dealloc];
}

- (void) viewDidUnload 
{
    [super viewDidUnload];
    self.tableView = nil;
    
    //IFGenericTableViewController
    [tableGroups release];
    tableGroups = nil;
    [tableFooters release];
    tableGroups = nil;
    [tableHeaders release];
    tableHeaders = nil;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLastAccountDetails:) name:kLastAccountDetailsNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAccountListUpdated:) name:kNotificationAccountListUpdated object:nil];
        //Updates the badge in the More Tab
        [self handleAccountListUpdated:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [Theme setThemeForUINavigationBar:self.navigationController.navigationBar];
    [self.navigationItem setTitle:NSLocalizedString(@"more.view.title", @"More")];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Always Rotate
    return YES;
}

- (void)loadView
{
	// NOTE: This code circumvents the normal loading of the UITableView and replaces it with an instance
	// of IFTextViewTableView (which includes a workaround for the hit testing problems in a UITextField.)
	// Check the header file for IFTextViewTableView to see why this is important.
	//
	// Since there is no style accessor on UITableViewController (to obtain the value passed in with the
	// initWithStyle: method), the value is hard coded for this use case. Too bad.
    
	self.view = [[[IFTextViewTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain] autorelease];
	[(IFTextViewTableView *)self.view setDelegate:self];
	[(IFTextViewTableView *)self.view setDataSource:self];
	[self.view setAutoresizesSubviews:YES];
	[self.view setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
}

#pragma mark -
#pragma mark Generic Table View Construction
- (void)constructTableGroups
{
    if (![self.model isKindOfClass:[IFTemporaryModel class]]) {
        IFTemporaryModel *tempModel = [[IFTemporaryModel alloc] init];
        [self setModel:tempModel];
        [tempModel release];
	}
    
    // Arrays for section headers, bodies and footers
	NSMutableArray *headers = [NSMutableArray array];
	NSMutableArray *groups =  [NSMutableArray array];
    
    NSMutableArray *moreCellGroup = [NSMutableArray array];

    /**
     * Search
     */
    TableCellViewController *searchCell = [[[TableCellViewController alloc] initWithAction:@selector(showSearchView) onTarget:self] autorelease];
    searchCell.textLabel.text = NSLocalizedString(@"search.view.title", @"Search");
    searchCell.imageView.image = [UIImage imageNamed:kSearchMoreIcon_ImageName];
    searchCell.selectionStyle = UITableViewCellSelectionStyleBlue;
    searchCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [moreCellGroup addObject:searchCell];
    
    /**
     * Downloads
     */
    TableCellViewController *downloadsCell = [[[TableCellViewController alloc] initWithAction:@selector(showDownloadsView) onTarget:self] autorelease];
    downloadsCell.textLabel.text = NSLocalizedString(@"downloads.view.title", @"Favorites");
    downloadsCell.imageView.image = [UIImage imageNamed:kDownloadsMoreIcon_ImageName];
    downloadsCell.selectionStyle = UITableViewCellSelectionStyleBlue;
    downloadsCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [moreCellGroup addObject:downloadsCell];

    /**
     * Manage Accounts
     */
    AccountCellController *serversCell = [[[AccountCellController alloc] initWithAction:@selector(showServersView) onTarget:self] autorelease];
    serversCell.textLabel.text = NSLocalizedString(@"Manage Accounts", @"Manage Accounts");
    serversCell.imageView.image = [UIImage imageNamed:kAccountsMoreIcon_ImageName];
    serversCell.selectionStyle = UITableViewCellSelectionStyleBlue;
    serversCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    if([[[AccountManager sharedManager] errorAccounts] count] > 0)
    {
        [serversCell setWarningImage:[UIImage imageNamed:kImageUIButtonBarBadgeError]];
    }
    [self setManageAccountsCell:serversCell];
    [moreCellGroup addObject:serversCell];

    /**
     * Help
     */
    // The help option will only be shown if app setting "helpGuides.show" is YES
    BOOL showHelpAppProperty = [[AppProperties propertyForKey:kHelpGuidesShow] boolValue];
    if (showHelpAppProperty)
    {
        TableCellViewController *helpCell = [[[TableCellViewController alloc] initWithAction:@selector(showHelpView) onTarget:self] autorelease];
        helpCell.textLabel.text = NSLocalizedString(@"help.view.title", @"Help tab bar button label");
        helpCell.imageView.image = [UIImage imageNamed:kHelpMoreIcon_ImageName];
        helpCell.selectionStyle = UITableViewCellSelectionStyleBlue;
        helpCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        [moreCellGroup addObject:helpCell];
    }

    /**
     * About
     */
    TableCellViewController *aboutCell = [[[TableCellViewController alloc] initWithAction:@selector(showAboutView) onTarget:self] autorelease];
    aboutCell.textLabel.text = NSLocalizedString(@"About", @"About tab bar button label");
    aboutCell.imageView.image = [UIImage imageNamed:kAboutMoreIcon_ImageName];
    aboutCell.selectionStyle = UITableViewCellSelectionStyleBlue;
    [moreCellGroup addObject:aboutCell];
    
    /**
     * Settings
     */
    TableCellViewController *settingsCell = [[[TableCellViewController alloc] initWithAction:@selector(showSettingsView) onTarget:self] autorelease];
    settingsCell.textLabel.text = NSLocalizedString(@"Settings", @"Settings");
    settingsCell.imageView.image = [UIImage imageNamed:kSettingsMoreIcon_ImageName];
    settingsCell.selectionStyle = UITableViewCellSelectionStyleBlue;
    [moreCellGroup addObject:settingsCell];
    
    if(!IS_IPAD)
    {
        for(TableCellViewController* cell in moreCellGroup)
        {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    
    [headers addObject:@""];
	[groups addObject:moreCellGroup];
    
    tableGroups = [groups retain];
	tableHeaders = [headers retain];
    
	[self assignFirstResponderHostToCellControllers];
}

- (void)showAboutView
{
    AboutViewController *aboutViewController = [[AboutViewController alloc] initWithNibName:@"AboutView" bundle:nil];
    [IpadSupport pushDetailController:aboutViewController withNavigation:[self navigationController] andSender:self];
    [aboutViewController release];
}

- (void)showDownloadsView
{
    DownloadsViewController *downloadsViewController = [[DownloadsViewController alloc] init];
    [[self navigationController] pushViewController:downloadsViewController animated:YES];
    [downloadsViewController release];
}

- (void)showSearchView
{
    SearchViewController *searchViewController = [[SearchViewController alloc] initWithNibName:@"SearchViewController" bundle:nil];
    [[self navigationController] pushViewController:searchViewController animated:YES];
    [searchViewController release];
}

- (void)showServersView
{
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"AccountSettingsConfiguration" ofType:@"plist"];
    AccountSettingsViewController *viewController = [AccountSettingsViewController genericTableViewWithPlistPath:plistPath andTableViewStyle:UITableViewStylePlain];
    [[self navigationController] pushViewController:viewController animated:YES];
}

- (void)showSettingsView
{
    FDSettingsViewController *viewController = [[FDSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [IpadSupport pushDetailController:viewController withNavigation:[self navigationController] andSender:self];
    [viewController release];
}

- (void)showHelpView
{
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"HelpConfiguration" ofType:@"plist"];
    HelpViewController *viewController = [HelpViewController genericTableViewWithPlistPath:plistPath andTableViewStyle:UITableViewStyleGrouped];
    [[self navigationController] pushViewController:viewController animated:YES];
}

#pragma mark - 
#pragma mark UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kDefaultTableCellHeight;
}

#pragma mark - MBProgressHUD Helper Methods

- (void)startHUD
{
	if (!self.HUD)
    {
        self.HUD = createAndShowProgressHUDForView(self.tableView);
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

#pragma mark - NotificationCenter methods

- (void)applicationWillResignActive:(NSNotification *)notification 
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)handleLastAccountDetails:(NSNotification *)notification 
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(handleLastAccountDetails:) withObject:notification waitUntilDone:NO];
        return;
    }
    
    [self.navigationItem setTitle:NSLocalizedString(@"more.view.title", @"More")];

    AccountSettingsViewController *viewController = nil;

    if ([self.navigationController.visibleViewController class] != [AccountSettingsViewController class])
    {
        [self.navigationController popToRootViewControllerAnimated:NO];
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"AccountSettingsConfiguration" ofType:@"plist"];
        viewController = [AccountSettingsViewController genericTableViewWithPlistPath:plistPath andTableViewStyle:UITableViewStylePlain];
        [[self navigationController] pushViewController:viewController animated:NO];
    }
    else
    {
        viewController = (AccountSettingsViewController *)self.navigationController.visibleViewController;
    }
    
    [viewController navigateIntoLastAccount];
    [[self tabBarController] setSelectedViewController:[self navigationController]];
}

- (void)handleAccountListUpdated:(NSNotification *)notification
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(handleAccountListUpdated:) withObject:notification waitUntilDone:NO];
        return;
    }
    
    //The main controller in the "More" tab is the navigation controller
    NSArray *awaitingAccounts = [[AccountManager sharedManager] awaitingVerificationAccounts];
    NSArray *errorAccounts = [[AccountManager sharedManager] errorAccounts];
    if([errorAccounts count] > 0)
    {
        [[self.navigationController tabBarItem] setBadgeValue:@"!"];
        [self.manageAccountsCell setWarningImage:[UIImage imageNamed:kImageUIButtonBarBadgeError]];
        [self updateAndRefresh];
    }
    else if([awaitingAccounts count] > 0)
    {
        [[self.navigationController tabBarItem] setBadgeValue:[NSString stringWithFormat:@"%d", [awaitingAccounts count]]];
    }
    else 
    {
        [[self.navigationController tabBarItem] setBadgeValue:nil];
        [self.manageAccountsCell setWarningImage:nil];
        [self updateAndRefresh];
    }
}

@end
