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
#import "MBProgressHUD.h"
#import "ServersTableViewController.h"
#import "AccountSettingsViewController.h"
#import "AccountManager.h"

@interface MoreViewController(private)
- (void) startHUD;
- (void) stopHUD;
@end

@implementation MoreViewController
@synthesize aboutViewController;
@synthesize activitiesController;
@synthesize HUD;

- (void) dealloc 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [aboutViewController release];
    [activitiesController release];
    [HUD release];
    [super dealloc];
}

- (void) viewDidUnload 
{
    [super viewDidUnload];
    self.aboutViewController = nil;
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
        //The main controller in the "More" tab is the navigation controller
        NSArray *awaitingAccounts = [[AccountManager sharedManager] awaitingVerificationAccounts];
        if([awaitingAccounts count] > 0)
        {
            [[self.navigationController tabBarItem] setBadgeValue:[NSString stringWithFormat:@"%d", [awaitingAccounts count]]];
        }
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
    
    TableCellViewController *serversCell = [[[TableCellViewController alloc] initWithAction:@selector(showServersView) onTarget:self] autorelease];
    serversCell.textLabel.text = NSLocalizedString(@"Manage Accounts", @"Manage Accounts");
    serversCell.imageView.image = [UIImage imageNamed:kAccountsMoreIcon_ImageName];
    [moreCellGroup addObject:serversCell];
    
    TableCellViewController *aboutCell = [[[TableCellViewController alloc] initWithAction:@selector(showAboutView) onTarget:self] autorelease];
    aboutCell.textLabel.text = NSLocalizedString(@"About", @"About tab bar button label");
    aboutCell.imageView.image = [UIImage imageNamed:kAboutMoreIcon_ImageName];
    [moreCellGroup addObject:aboutCell];
    
    
    BOOL showSimpleSettings = [[AppProperties propertyForKey:kMShowSimpleSettings] boolValue];
    if(showSimpleSettings) {
        TableCellViewController *simpleSettingsCell = [[[TableCellViewController alloc] initWithAction:@selector(showSimpleSettings) onTarget:self] autorelease];
        simpleSettingsCell.textLabel.text = NSLocalizedString(@"more.simpleSettingsLabel", @"Simple Settings Label");
        
        [moreCellGroup addObject:simpleSettingsCell];
    }
    
    
    
    if(!IS_IPAD) {
        for(TableCellViewController* cell in moreCellGroup) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
    }
    
    [headers addObject:@""];
	[groups addObject:moreCellGroup];
    
    tableGroups = [groups retain];
	tableHeaders = [headers retain];
    
	[self assignFirstResponderHostToCellControllers];
}

- (void) showAboutView {
    NSString *nibName = nil;
    if(IS_IPAD) {
        nibName = @"AboutView~iPad";
    } else {
        nibName = @"AboutView";        
    }
    
    self.aboutViewController = [[[AboutViewController alloc] initWithNibName:nibName bundle:nil] autorelease];
    [IpadSupport pushDetailController:aboutViewController withNavigation:[self navigationController] andSender:self];
}

- (void)showServersView
{
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"AccountSettingsConfiguration" ofType:@"plist"];
    AccountSettingsViewController *viewController = [AccountSettingsViewController genericTableViewWithPlistPath:plistPath andTableViewStyle:UITableViewStylePlain];
    [[self navigationController] pushViewController:viewController animated:YES];
}

- (void)showActivitiesView {
    [IpadSupport pushDetailController:activitiesController withNavigation:[self navigationController] andSender:self];
}

#pragma mark - 
#pragma mark UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kDefaultTableCellHeight;
}

#pragma mark -
#pragma mark MBProgressHUD Helper Methods
- (void)startHUD
{
	if (HUD) {
		return;
	}
    
    [self setHUD:[MBProgressHUD showHUDAddedTo:self.tableView animated:YES]];
    [self.HUD setRemoveFromSuperViewOnHide:YES];
    [self.HUD setTaskInProgress:YES];
    [self.HUD setMode:MBProgressHUDModeIndeterminate];
}

- (void)stopHUD
{
	if (HUD) {
		[HUD setTaskInProgress:NO];
		[HUD hide:YES];
		[HUD removeFromSuperview];
		[self setHUD:nil];
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
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"AccountSettingsConfiguration" ofType:@"plist"];
    AccountSettingsViewController *viewController = [AccountSettingsViewController genericTableViewWithPlistPath:plistPath andTableViewStyle:UITableViewStylePlain];
    [[self navigationController] pushViewController:viewController animated:NO];
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
    if([awaitingAccounts count] > 0)
    {
        [[self.navigationController tabBarItem] setBadgeValue:[NSString stringWithFormat:@"%d", [awaitingAccounts count]]];
    }
    else 
    {
        [[self.navigationController tabBarItem] setBadgeValue:nil];
    }
}

@end
