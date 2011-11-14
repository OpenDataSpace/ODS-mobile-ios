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
 * Portions created by the Initial Developer are Copyright (C) 2011
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
#import "ServiceDocumentRequest.h"
#import "Constants.h"

@interface MoreViewController(private)
- (void) startHUD;
- (void) stopHUD;
@end

@implementation MoreViewController
@synthesize aboutViewController;
@synthesize activitiesController;
@synthesize HUD;
@synthesize serviceDocumentRequest;

- (void) dealloc {
    [aboutViewController release];
    [activitiesController release];
    [HUD release];
    [serviceDocumentRequest release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [Theme setThemeForUINavigationBar:self.navigationController.navigationBar];
    
    [self.navigationItem setTitle:NSLocalizedString(@"more.view.title", @"More")];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void) viewDidUnload {
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
    
    TableCellViewController *aboutCell = [[[TableCellViewController alloc] initWithAction:@selector(showAboutView) onTarget:self] autorelease];
    aboutCell.textLabel.text = NSLocalizedString(@"About", @"About tab bar button label");
    aboutCell.imageView.image = [UIImage imageNamed:@"about-more.png"];
    [moreCellGroup addObject:aboutCell];
    
    BOOL showMoreCell = [[AppProperties propertyForKey:kMShowSimpleSettings] 
                           boolValue];
    
    if(showMoreCell) {
        TableCellViewController *simpleSettingsCell = [[[TableCellViewController alloc] initWithAction:@selector(showSimpleSettings) onTarget:self] autorelease];
        simpleSettingsCell.textLabel.text = NSLocalizedString(@"more.simpleSettingsLabel", @"Simple Settings Label");
        
        [moreCellGroup addObject:simpleSettingsCell];
    }
    
    // Activities was moved as a main tab bar item
    // Remove this unused codewhen we are sure how we will handle hiding/showing elements of the tab bat
    // depending on the target client
    /*TableCellViewController *activitiesCell = [[[TableCellViewController alloc] initWithAction:@selector(showActivitiesView) onTarget:self] autorelease];
    activitiesCell.textLabel.text = @"Activities";
    */
    //[moreCellGroup addObject:activitiesCell];
    
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

- (void) showActivitiesView {
    [IpadSupport pushDetailController:activitiesController withNavigation:[self navigationController] andSender:self];
}

- (void) showSimpleSettings {
    SimpleSettingsViewController *viewController = [[SimpleSettingsViewController alloc] initWithStyle:UITableViewStylePlain];
    [viewController setDelegate:self];
    [viewController setModalPresentationStyle:UIModalPresentationFormSheet];
    [viewController setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
    
    [IpadSupport presentModalViewController:viewController withParent:self andNavigation:nil];
    [viewController release];
}

#pragma mark -
#pragma mark SimpleSettingsDelegate

- (void)simpleSettingsViewDidFinish:(SimpleSettingsViewController *)controller settingsDidChange:(BOOL)settingsDidChange {
    if(settingsDidChange) {
        [self startHUD];
        
        ServiceDocumentRequest *request = [ServiceDocumentRequest httpGETRequest];
        [request setDelegate:self];
        [request setDidFinishSelector:@selector(serviceDocumentRequestFinished:)];
        [request setDidFailSelector:@selector(serviceDocumentRequestFailed:)];
        [request startAsynchronous];
    }
    
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark HTTP Request Handling

- (void)serviceDocumentRequestFinished:(ServiceDocumentRequest *)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationRepositoryShouldReload object:nil];
    [self stopHUD];
}

- (void)serviceDocumentRequestFailed:(ServiceDocumentRequest *)sender
{
	NSLog(@"ServiceDocument Request Failure \n\tErrorDescription: %@ \n\tErrorFailureReason:%@ \n\tErrorObject:%@", 
          [[sender error] description], [[sender error] localizedFailureReason],[sender error]);
    
	[self stopHUD];
    
    // TODO Make sure the string bundles are updated for the different targets
    NSString *failureMessage = [NSString stringWithFormat:NSLocalizedString(@"serviceDocumentRequestFailureMessage", @"Failed to connect to the repository"),
                                [sender url]];
	
    UIAlertView *sdFailureAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"serviceDocumentRequestFailureTitle", @"Error")
															  message:failureMessage
															 delegate:nil 
													cancelButtonTitle:NSLocalizedString(@"Continue", nil)
													otherButtonTitles:nil] autorelease];
	[sdFailureAlert show];
    [sender cancel];
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

- (void) applicationWillResignActive:(NSNotification *) notification {
    [self dismissModalViewControllerAnimated:YES];
    [serviceDocumentRequest clearDelegatesAndCancel];
}

@end
