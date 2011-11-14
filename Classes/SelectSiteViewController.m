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
//  SelectSiteViewController.m
//

#import "SelectSiteViewController.h"
#import "RepositoryItem.h"
#import "TableCellViewController.h"
#import "AlfrescoAppDelegate.h"
#import "IFTextViewTableView.h"
#import "RepositoryServices.h"

@interface  SelectSiteViewController (private)
-(void)startHUD;
-(void)stopHUD;
-(void)requestAllSites;
@end

@implementation SelectSiteViewController
@synthesize selectedSite;
@synthesize allSitesSelected;
@synthesize allSites;
@synthesize delegate;
@synthesize HUD;

-(void)dealloc {
    [super dealloc];
    [selectedSite release];
    [allSites release];
    [HUD release];
}

-(void)viewDidLoad {
    [super viewDidLoad];
    [self requestAllSites];
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

-(void)constructTableGroups {
    NSMutableArray *mainGroup = [NSMutableArray array];
    TableCellViewController *allSitesCell = [[TableCellViewController alloc] initWithAction:@selector(selectAllSites:) onTarget:self];
    [allSitesCell.textLabel setText:NSLocalizedString(@"search.allSites", @"Entire Repository")];
    [mainGroup addObject:allSitesCell];
    [allSitesCell release];
    
    TableCellViewController *siteCell = nil;
    
    for(RepositoryItem *item in self.allSites) {
        siteCell = [[TableCellViewController alloc] initWithAction:@selector(selectSite:) onTarget:self];
        [siteCell.textLabel setText:item.title];
        NSString *folderImageName = @"folder.png";
        folderImageName = @"site.png";
        [siteCell.imageView setImage:[UIImage imageNamed:folderImageName]];
        [mainGroup addObject:siteCell];
        [siteCell release];
    }
    
    tableGroups = [[NSArray arrayWithObject:mainGroup] retain];
}

#pragma mark - Requesting sites
-(void)requestAllSites{
    BOOL sitesAreAvailable = [[RepositoryServices shared] isCurrentRepositoryVendorNameEqualTo:kAlfrescoRepositoryVendorName];
    
    if(sitesAreAvailable) {
        SitesManagerService *sitesService = [SitesManagerService sharedInstance];
        if([sitesService hasResults]) {
            [self setAllSites:[sitesService allSites]];
        } else {
            [self startHUD];
            [sitesService addListener:self];
            [sitesService startOperations];
        }
    }
}

#pragma mark -
#pragma mark SitesManagerDelegate methods

-(void)siteManagerFinished:(SitesManagerService *)siteManager {
    [self stopHUD];
    self.allSites = [siteManager allSites];
    
    [self updateAndReload];
    [[SitesManagerService sharedInstance] removeListener:self];
}

-(void)siteManagerFailed:(SitesManagerService *)siteManager {
    [self stopHUD];
    [[SitesManagerService sharedInstance] removeListener:self];
    //Request error already logged
}

#pragma mark - Cell actions
-(void)selectAllSites:(id)sender {
    allSitesSelected = YES;
    if([delegate respondsToSelector:@selector(selectSite:finishedWithSite:)]) {
        [delegate selectSite:self finishedWithSite:nil];
    }
}

-(void)selectSite:(id)sender {
    allSitesSelected = NO;
    if([delegate respondsToSelector:@selector(selectSite:finishedWithSite:)]) {
        TableCellViewController *cell = (TableCellViewController *)sender;
        
        //Is -1 because the first cell is the "All Sites" cell
        self.selectedSite = [allSites objectAtIndex:cell.indexPath.row-1];
        [delegate selectSite:self finishedWithSite:self.selectedSite];
    }
}

#pragma mark - static initializers
+(SelectSiteViewController *)selectSiteViewController {
    SelectSiteViewController *select = [[[SelectSiteViewController alloc] initWithStyle:UITableViewStylePlain] autorelease];
    return select;
}

#pragma mark -
#pragma mark MBProgressHUD Helper Methods
- (void)startHUD
{
	if (HUD) {
		return;
	}
    
    [self setHUD:[MBProgressHUD showHUDAddedTo:self.view animated:YES]];
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

@end
