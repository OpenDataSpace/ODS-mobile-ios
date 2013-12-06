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
//  RootViewController.m
//

#import "RootViewController.h"
#import "RepositoryNodeViewController.h"
#import "RepositoryItemTableViewCell.h"
#import "Utility.h"
#import "DocumentViewController.h"
#import "MetaDataTableViewController.h"
#import "RepositoryServices.h"
#import "WhiteGlossGradientView.h"
#import "Theme.h"
#import "ThemeProperties.h"
#import "AppProperties.h"
#import "LinkRelationService.h"
#import "NSURL+HTTPURLUtils.h"
#import "FileUtils.h"
#import "IpadSupport.h"
#import "TableViewHeaderView.h"
#import "AccountManager.h"
#import "ServiceDocumentRequest.h"
#import "FileDownloadManager.h"
#import "UITableView+LongPress.h"
#import "AlfrescoUtils.h"

// ** Class Constants
static NSInteger const kDefaultSelectedSegment = 1;

static NSInteger const kAddActionSheetTag = 100;
static NSInteger const kUploadActionSheetTag = 101;
static NSInteger const kDeleteActionSheetTag = 103;
static NSInteger const kOperationActionSheetTag = 104;
static NSInteger const kDeleteFileAlert = 10;
static NSInteger const kRenameFileAlert = 11;


@interface RootViewController (private) 
- (void)startHUD;
- (void)stopHUD;
- (void)clearAllHUDs;
- (void)requestAllSites:(id)sender;
- (void)requestAllSites:(id)sender forceReload:(BOOL)reload;
- (void)hideSegmentedControl;
- (void)showSegmentedControl;
- (FolderItemsHTTPRequest *)companyHomeRequest;
- (void)setupBackButton;
@end

@interface RootViewController ()
@property (nonatomic, retain) NSIndexPath *expandedCellIndexPath;
@property (nonatomic, retain) UIImage *accessoryDownImage;
@property (nonatomic, retain) UIImage *accessoryUpImage;
@property (nonatomic, retain) UIActionSheet *actionSheet;
@property (nonatomic, retain) RepositoryItem *selectedItem;
@end

@implementation RootViewController
@synthesize allSites = _allSites;
@synthesize mySites = _mySites;
@synthesize favSites = _favSites;
@synthesize activeSites = _activeSites;
@synthesize companyHomeItems = _companyHomeItems;
@synthesize itemDownloader = _itemDownloader;
@synthesize companyHomeDownloader = _companyHomeDownloader;
@synthesize progressBar = _progressBar;
@synthesize typeDownloader = _typeDownloader;
@synthesize segmentedControl = _segmentedControl;
@synthesize tableView = _tableView;
@synthesize segmentedControlBkg = _segmentedControlBkg;
@synthesize selectedAccountUUID = _selectedAccountUUID;
@synthesize tenantID = _tenantID;
@synthesize repositoryID = _repositoryID;
@synthesize HUD = _HUD;
@synthesize refreshHeaderView = _refreshHeaderView;
@synthesize lastUpdated = _lastUpdated;
@synthesize selectedSiteType = _selectedSiteType;
@synthesize selectedIndex = _selectedIndex;
@synthesize willSelectIndex = _willSelectIndex;
@synthesize expandedCellIndexPath = _expandedCellIndexPath;
@synthesize accessoryDownImage = _accessoryDownImage;
@synthesize accessoryUpImage = _accessoryUpImage;
@synthesize popover = _popover;
@synthesize actionSheet = _actionSheet;
@synthesize selectedItem = _selectedItem;
@synthesize deleteQueueProgressBar = _deleteQueueProgressBar;
@synthesize renameQueueProgressBar = _renameQueueProgressBar;

static NSArray *siteTypes;

+ (void)initialize
{
    siteTypes = [[NSArray arrayWithObjects:@"root.favsites",@"root.mysites",@"root.allsites", nil] retain];
}

#pragma mark - Memory Management

- (void)dealloc 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[CMISServiceManager sharedManager] removeAllListeners:self];
    [[SitesManagerService sharedInstanceForAccountUUID:self.selectedAccountUUID tenantID:self.tenantID] removeListener:self];
    [self cancelAllHTTPConnections];
    [self.popover dismissPopoverAnimated:NO];
    
	[_allSites release];
    [_mySites release];
    [_favSites release];
    [_activeSites release];
	[_companyHomeItems release];
	[_itemDownloader release];
	[_companyHomeDownloader release];
	[_progressBar release];
	[_typeDownloader release];
    [_segmentedControl release];
    [_tableView release];
    [_segmentedControlBkg release];
    [_selectedAccountUUID release];
    [_tenantID release];
    [_repositoryID release];
	[_HUD release];
    [_refreshHeaderView release];
    [_lastUpdated release];
    [_selectedSiteType release];
    [_selectedIndex release];
    [_willSelectIndex release];
    [_expandedCellIndexPath release];
    [_accessoryDownImage release];
    [_accessoryUpImage release];
    [_actionSheet release];
    [_popover release];

    [super dealloc];
}

- (void)loadView
{
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    
    [tableView setAutoresizesSubviews:YES];
    [tableView setAutoresizingMask:UIViewAutoresizingNone];
    [self setView:tableView];
    [self setTableView:tableView];
    
    if ([tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    [tableView addLongPressRecognizer];
    
    [tableView release];
    
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
}
#pragma mark - View Lifecycle

- (void)viewDidUnload 
{
	[super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kDetailViewControllerChangedNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[Theme setThemeForUIViewController:self]; 
    
    self.selectedIndex = nil;
    self.willSelectIndex = nil;
    if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
   
    [self.navigationItem setHidesBackButton:NO animated:YES]; //force back button display
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
	
	[self stopHUD];
}

- (void)viewDidLoad 
{
	[super viewDidLoad];
    
    // Default selection is "My sites"
    /*[self.segmentedControl setSelectedSegmentIndex:kDefaultSelectedSegment];
    [self.segmentedControl setTitle:NSLocalizedString(@"root.favsites.sectionheader", @"Favorite Sites") forSegmentAtIndex:0];
    [self.segmentedControl setTitle:NSLocalizedString(@"root.mysites.sectionheader", @"My Sites") forSegmentAtIndex:1];
    [self.segmentedControl setTitle:NSLocalizedString(@"root.allsites.sectionheader", @"All Sites") forSegmentAtIndex:2];

    // Apparently the changeSegment action is not executed before the tableview loads its cells
    // It causes incorrect label in the "No sites cell"
    self.selectedSiteType = [siteTypes objectAtIndex:kDefaultSelectedSegment];
    
    [self hideSegmentedControl];
    [self.segmentedControl setTintColor:[ThemeProperties segmentedControlColor]];
    [self.segmentedControl setBackgroundColor:[ThemeProperties segmentedControlBkgColor]];
    [self.segmentedControlBkg setBackgroundColor:[ThemeProperties segmentedControlBkgColor]];
    [self hideSegmentedControl];
    */
    isAlfrescoAccount = [[AccountManager sharedManager] isAlfrescoAccountForAccountUUID:self.selectedAccountUUID];
    
    RepositoryServices *repoService = [RepositoryServices shared];
    RepositoryInfo *repoInfo = [repoService getRepositoryInfoForAccountUUID:self.selectedAccountUUID tenantID:self.tenantID];
    if (repoInfo == nil) 
    {
        [self startHUD];
        
        [NSTimer scheduledTimerWithTimeInterval:0.4 target:self selector:@selector(loadServiceDocument) userInfo:nil repeats:NO];
    } 
    else
    {
        [self requestAllSites:nil];
    }
    
    [self setupBackButton];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAccountListUpdated:) 
                                                 name:kNotificationAccountListUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userPreferencesChanged:) 
                                                 name:kUserPreferencesChangedNotification object:nil];

    [[SitesManagerService sharedInstanceForAccountUUID:self.selectedAccountUUID tenantID:self.tenantID] addListener:self];

	// Pull to Refresh
    self.refreshHeaderView = [[[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)
                                                                arrowImageName:@"pull-to-refresh.png"
                                                                     textColor:[ThemeProperties pullToRefreshTextColor]] autorelease];
    [self.refreshHeaderView setDelegate:self];
    [self setLastUpdated:[NSDate date]];
    [self.refreshHeaderView refreshLastUpdatedDate];
    [self.tableView addSubview:self.refreshHeaderView];

    // Accessory images
    self.accessoryDownImage = [UIImage imageNamed:@"grey-accessory-down"];
    self.accessoryUpImage = [UIImage imageNamed:@"grey-accessory-up"];
    
   // self.view = self.tableView; //if a tableview add into a view, then autoresizing not work.
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.extendedLayoutIncludesOpaqueBars = NO;
        self.modalPresentationCapturesStatusBarAppearance = NO;
    }
#endif
    if ([self canEditDataRoom]) {
        [self.tableView addLongPressRecognizer];
        [self loadRightBarAnimated:YES];
    }
}

- (void)loadServiceDocument
{
    CMISServiceManager *serviceManager = [CMISServiceManager sharedManager];
    [serviceManager addListener:self forAccountUuid:self.selectedAccountUUID];
    [serviceManager loadServiceDocumentForAccountUuid:self.selectedAccountUUID];
}

- (void)setupBackButton
{
    //Retrieve account count
    NSArray *allAccounts = [[AccountManager sharedManager] activeAccounts];
    NSInteger accountCount = [allAccounts count];
    AccountInfo *selectedAccount = [[AccountManager sharedManager] accountInfoForUUID:self.selectedAccountUUID];
    if ((accountCount == 1) && (![selectedAccount isMultitenant])) 
    {
        [self.navigationItem setHidesBackButton:YES];
    }
    else 
    {
        [self.navigationItem setHidesBackButton:NO];
    }
}

- (void)reloadTableViewData
{
    self.expandedCellIndexPath = nil;
    [self.tableView reloadData];
}

//FIXME uncomment the methods once we figure out how are we going to handle non-alfresco repositories
- (void)hideSegmentedControl {
    [self.segmentedControl setHidden:YES];
    [self.segmentedControlBkg setHidden:YES];
    self.tableView.frame = self.view.frame;
}

- (void)showSegmentedControl {
    /*[segmentedControl setHidden:NO];
    [segmentedControlBkg setHidden:NO];
    CGRect tableFrame = self.view.frame;
    tableFrame.size.height = tableFrame.size.height - segmentedControlBkg.frame.size.height;
    tableFrame.origin.y = segmentedControlBkg.frame.size.height;
    self.tableView.frame = tableFrame;*/
}

- (IBAction)segmentedControlChange:(id)sender
{
    NSInteger selectedSegment = self.segmentedControl.selectedSegmentIndex;
    self.selectedSiteType = [siteTypes objectAtIndex:self.segmentedControl.selectedSegmentIndex];
    
    switch(selectedSegment)
    {
        case 0:
            self.activeSites = self.favSites;
            break;
        case 1:
            self.activeSites = self.mySites;
            break;
        default:
            self.activeSites = self.allSites;
            break;
    }
    [self reloadTableViewData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - UITableViewDataSource methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *titleHeader = nil;
	if (isAlfrescoAccount)
    {
        if (section == 1)
        {
            titleHeader = NSLocalizedString(@"rootSectionHeaderCompanyHome", @"Company Home");
        }
    }
    return titleHeader;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	if (isAlfrescoAccount)
    {
		return (userPrefShowCompanyHome() ? 2 : 1);
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	if ((NAN != section) && isAlfrescoAccount)
    {
        if(section == 1)
        {
            return self.companyHomeItems ? [self.companyHomeItems count] : 0;
        }
        else
        {
            if (showSitesOptions)
            {
                return self.activeSites.count != 0 ? self.activeSites.count : 1;
            }
            return self.activeSites ? self.activeSites.count : 0;
        }
    }
    return [self.companyHomeItems count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if (isAlfrescoAccount && (indexPath.section == 0))
	{
        UITableViewCell *tableCell = nil;
        
        // We are in the sites section
        if (self.activeSites.count > 0)
        {
            SiteTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSiteTableViewCellIdentifier];
            if (cell == nil)
            {
                cell = [[[SiteTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kSiteTableViewCellIdentifier] autorelease];
            }

            SitesManagerService *sitesManager = [SitesManagerService sharedInstanceForAccountUUID:self.selectedAccountUUID tenantID:self.tenantID];
            RepositoryItem *site = [self.activeSites objectAtIndex:indexPath.row];
            [site.metadata setObject:[NSNumber numberWithBool:[sitesManager isFavoriteSite:site]] forKey:@"isFavorite"];
            [site.metadata setObject:[NSNumber numberWithBool:[sitesManager isMemberOfSite:site]] forKey:@"isMember"];
            [site.metadata setObject:[NSNumber numberWithBool:[sitesManager isPendingMemberOfSite:site]] forKey:@"isPendingMember"];
            [cell setSite:site];
            [cell setDelegate:self];
            [cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
            [cell setAccessoryView:[self makeSiteDetailDisclosureButton]];
            [(UIButton *)cell.accessoryView addTarget:self action:@selector(siteAccessoryButtonTapped:withEvent:) forControlEvents:UIControlEventTouchUpInside];

            tableCell = cell;
        }
        else if (showSitesOptions)
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NoSitesCell"];
            if (cell == nil)
            {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NoSitesCell"] autorelease];
            }
            NSString *localizedKey = [NSString stringWithFormat:@"%@.nosites",self.selectedSiteType];
            cell.textLabel.text = NSLocalizedString(localizedKey, @"No favorite sites");
            [cell setAccessoryType:UITableViewCellAccessoryNone];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            cell.imageView.image = nil;
            
            tableCell = cell;
        }
        
		return tableCell;
	}
	else
    {
		// We are looking at a child item in the Root Collection
		
		RepositoryItemTableViewCell *cell = (RepositoryItemTableViewCell *) [tableView dequeueReusableCellWithIdentifier:RepositoryItemCellIdentifier];
		if (cell == nil)
        {
			NSArray *nibItems = [[NSBundle mainBundle] loadNibNamed:@"RepositoryItemTableViewCell" owner:self options:nil];
			cell = [nibItems objectAtIndex:0];
			NSAssert(nibItems, @"Failed to load object from NIB");
		}
		
		RepositoryItem *child = [self.companyHomeItems objectAtIndex:[indexPath row]];
		
        NSString *filename = [child.metadata valueForKey:@"cmis:name"];
        if (!filename || ([filename length] == 0)) filename = child.title;
		[cell.filename setText:filename];
        
		if ([child isFolder])
        {
			UIImage *img = [UIImage imageNamed:@"folder.png"];
			cell.imageView.image = img;
            cell.details.text = [[[NSString alloc] initWithFormat:@"%@", formatDocumentDate(child.lastModifiedDate)] autorelease]; // TODO: Externalize to a configurable property?
		}
		else
        {
		    NSString *contentStreamLengthStr = [child.metadata objectForKey:@"cmis:contentStreamLength"];
            cell.details.text = [[[NSString alloc] initWithFormat:@"%@ • %@", formatDocumentDate(child.lastModifiedDate), 
                                 [FileUtils stringForLongFileSize:[contentStreamLengthStr longLongValue]]] autorelease]; // TODO: Externalize to a configurable property?
            cell.imageView.image = imageForFilename(child.title);
		}

        BOOL showMetadataDisclosure = [[AppProperties propertyForKey:kBShowMetadataDisclosure] boolValue];
        if (showMetadataDisclosure)
        {
            [cell setAccessoryView:[self makeDetailDisclosureButton]];
        }

		return cell;
		
	}
}

- (UIButton *)makeDetailDisclosureButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeInfoDark];
    [button addTarget:self action:@selector(accessoryButtonTapped:withEvent:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIButton *)makeSiteDetailDisclosureButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:CGRectMake(0, 0, 30, 44)];
    [button setImage:self.accessoryDownImage forState:UIControlStateNormal];
    [button setAdjustsImageWhenHighlighted:NO];
    return button;
}

- (void)accessoryButtonTapped:(UIControl *)button withEvent:(UIEvent *)event
{
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:[[[event touchesForView:button] anyObject] locationInView:self.tableView]];
    if (indexPath != nil)
    {
        [self.tableView.delegate tableView:self.tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
    }
}

- (void)siteAccessoryButtonTapped:(UIControl *)button withEvent:(UIEvent *)event
{
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:[[[event touchesForView:button] anyObject] locationInView:self.tableView]];
    if (indexPath != nil)
    {
        [self toggleExpandedCellAtIndexPath:indexPath];
    }
}

- (void)toggleExpandedCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *nextSelection = nil;
    BOOL needsUpdate = NO;
    
    if (self.expandedCellIndexPath != nil)
    {
        // We have an expanded cell - collapse it
        SiteTableViewCell *cell = [self siteCellAtIndexPath:self.expandedCellIndexPath];
        if (cell != nil)
        {
            [(UIButton *)cell.accessoryView setImage:self.accessoryDownImage forState:UIControlStateNormal];
            needsUpdate = YES;
        }
    }

    if (![indexPath isEqual:self.expandedCellIndexPath])
    {
        // Check we're tapping on a different cell
        SiteTableViewCell *cell = [self siteCellAtIndexPath:indexPath];
        if (cell != nil)
        {
            [(UIButton *)cell.accessoryView setImage:self.accessoryUpImage forState:UIControlStateNormal];
            nextSelection = indexPath;
            needsUpdate = YES;
        }
    }

    self.expandedCellIndexPath = nextSelection;
    
    if (needsUpdate)
    {
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
    }
}

- (SiteTableViewCell *)siteCellAtIndexPath:(NSIndexPath *)indexPath
{
    id cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if ([cell isKindOfClass:SiteTableViewCell.class])
    {
        return cell;
    }
    return nil;
}

#pragma mark - UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
    TableViewHeaderView *headerView = nil;

	if (sectionTitle != nil)
    {
        // The height gets adjusted if it is less than the needed height
        headerView = [[[TableViewHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, [tableView bounds].size.width, 10) label:sectionTitle] autorelease];
        [headerView setBackgroundColor:[ThemeProperties browseHeaderColor]];
        [headerView.textLabel setTextColor:[ThemeProperties browseHeaderTextColor]];
    }
    
	return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) //for fix tableview frame
    {
        if (IS_IPAD) {
            return 80.0f;
        }
        return 44.0f;
    }
#endif
    return 0.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
    CGFloat height = 0.0f;
	if (sectionTitle != nil)
    {
        TableViewHeaderView *headerView = [[[TableViewHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, [tableView bounds].size.width, 10) label:sectionTitle] autorelease];
        height = headerView.frame.size.height;
    }
	return height;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    // Zero-height UIView removes trailing empty cells, which look strange if the last UITableViewCell is expanded
    return [[[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 0)] autorelease];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 60.0f;
    
	if (isAlfrescoAccount && ([indexPath section] == 0))
    {
        height = kSiteTableViewCellUnexpandedHeight;
        if ([indexPath isEqual:self.expandedCellIndexPath])
        {
            height = kSiteTableViewCellExpandedHeight;
        }
        
    }
    return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Selected a "No sites" cell?
   /* if (indexPath.section == 0)
    {
        if ([self.activeSites count] <= 0)
        {
            return;
        }
    }*/
        
	[self cancelAllHTTPConnections];
    
	if (isAlfrescoAccount && ([indexPath section] == 0))
	{
		// Alfresco Sites, special case
        
        // Any cell expanded?
        if (self.expandedCellIndexPath != nil)
        {
            [self toggleExpandedCellAtIndexPath:self.expandedCellIndexPath];
        }
        
		// get the site information associated with this row
		RepositoryItem *site = [self.activeSites objectAtIndex:[indexPath row]];
		
		// start loading the list of top-level items for this site
        [self startHUD];
        FolderItemsHTTPRequest *down = [[FolderItemsHTTPRequest alloc] initWithNode:[site node] withAccountUUID:self.selectedAccountUUID];
        [down setTenantID:self.tenantID];
        [down setDelegate:self];
        [down setDidFinishSelector:@selector(folderItemsRequestFinished:)];
        [down setDidFailSelector:@selector(folderItemsRequestFailed:)];
        [down setItem:site];
        [down setParentTitle:site.title];
        [down setContext:@"topLevel"];
        [down startAsynchronous];
        
        [self setItemDownloader:down];
        [down release];
	}
	else 
    {
        // Root Collection Child
		// get the document/folder information associated with this row
		RepositoryItem *item = [self.companyHomeItems objectAtIndex:[indexPath row]];
		
		if ([item isFolder]) 
        {
            [self startHUD];
			NSDictionary *optionalArguments = [[LinkRelationService shared] defaultOptionalArgumentsForFolderChildrenCollection];											   
			NSURL *getChildrenURL = [[LinkRelationService shared] getChildrenURLForCMISFolder:item withOptionalArguments:optionalArguments];
			FolderItemsHTTPRequest *down = [[FolderItemsHTTPRequest alloc] initWithURL:getChildrenURL accountUUID:self.selectedAccountUUID];
			[down setDelegate:self];
            [down setDidFinishSelector:@selector(folderItemsRequestFinished:)];
            [down setDidFailSelector:@selector(folderItemsRequestFailed:)];
			[down setItem:item];
            [down setParentTitle:item.title];
            [down setContext:@"childFolder"];
            [self setItemDownloader:down];
            [down startAsynchronous];
			[down release];
		}
		else 
        {
			NSString* urlStr = item.contentLocation;
			self.progressBar = [DownloadProgressBar createAndStartWithURL:[NSURL URLWithString:urlStr] delegate:self 
																  message:NSLocalizedString(@"Downloading Document", @"Downloading Document") 
                                                                 filename:item.title
                                                              accountUUID:self.selectedAccountUUID
                                                                 tenantID:self.tenantID];
            [[self progressBar] setCmisObjectId:[item guid]];
            [[self progressBar] setCmisContentStreamMimeType:[[item metadata] objectForKey:@"cmis:contentStreamMimeType"]];
            [[self progressBar] setRepositoryItem:item];
            
            self.willSelectIndex = indexPath;
		}
	}
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath 
{	
	[self cancelAllHTTPConnections];
    
    // get the document/folder information associated with this row
    RepositoryItem *item = [self.companyHomeItems objectAtIndex:[indexPath row]];
	
	if (isAlfrescoAccount && ([indexPath section] == 0))
	{
        // Handled by specific button handler elsewhere
	}
	else
    {
		// Root Collection Child Item Case
		[self startHUD];
        
		CMISTypeDefinitionHTTPRequest *down = [[CMISTypeDefinitionHTTPRequest alloc] initWithURL:[NSURL URLWithString:item.describedByURL] 
                                                                                     accountUUID:self.selectedAccountUUID];
        [down setTenantID:self.tenantID];
        [down setDelegate:self];
        [down setRepositoryItem:item];
		[down startAsynchronous];
		[down release];
	}	
}

- (void)tableView:(UITableView *)tableView didRecognizeLongPressOnRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = (UITableViewCell*) [tableView cellForRowAtIndexPath:indexPath];
   _selectedItem = [self.companyHomeItems objectAtIndex:[indexPath row]];
    /*if (IS_IPAD)
    {
		[self dismissPopover];
	}*/
    
    UIActionSheet *sheet = [[UIActionSheet alloc]
                            initWithTitle:NSLocalizedString(@"operation.pop.menu.title", @"Operations")
                            delegate:self
                            cancelButtonTitle:nil
                            destructiveButtonTitle:nil
                            otherButtonTitles: nil];
    
    [sheet addButtonWithTitle:NSLocalizedString(@"operation.pop.menu.delete", @"Delete")];
    [sheet addButtonWithTitle:NSLocalizedString(@"operation.pop.menu.rename", @"Rename")];
    
    [sheet setCancelButtonIndex:[sheet addButtonWithTitle:NSLocalizedString(@"add.actionsheet.cancel", @"Cancel")]];
    
    if (IS_IPAD)
    {
        //[self setActionSheetSenderControl:sender];
        [sheet setActionSheetStyle:UIActionSheetStyleDefault];
        
        //UIBarButtonItem *actionButton = (UIBarButtonItem *)sender;
        
        CGRect actionButtonRect = cell.frame;
        actionButtonRect.size.height = actionButtonRect.size.height/2;
        if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]))
        {
            actionButtonRect.origin.y = 10;
            [sheet showFromRect:actionButtonRect inView:cell animated:YES];
        }
        else
        {
            // iOS 5.1 bug workaround
            actionButtonRect.origin.y += 70;
            NSLog(@"UIDeviceOrientationPortraitUpsideDown:%d ==== %d",[[UIDevice currentDevice] orientation],UIDeviceOrientationPortraitUpsideDown);
            if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationPortraitUpsideDown
                || [[UIDevice currentDevice] orientation] == UIDeviceOrientationFaceUp) {
                NSLog(@"UIDeviceOrientationPortraitUpsideDown");
            }
            [sheet showFromRect:actionButtonRect inView:self.view.window animated:YES];
            
        }
    }
    else
    {
        [sheet showInView:[[self tabBarController] view]];
    }
	
    [sheet setTag:kOperationActionSheetTag];
    [self setActionSheet:sheet];
	[sheet release];
}

#pragma mark - DownloadProgressBarDelegate

- (void)download:(DownloadProgressBar *)down completeWithPath:(NSString *)filePath
{
	DocumentViewController *doc = [[DocumentViewController alloc] initWithNibName:kFDDocumentViewController_NibName bundle:[NSBundle mainBundle]];
    if (down.cmisObjectId)
    {
        [doc setCmisObjectId:down.cmisObjectId];
    }
    [doc setCanEditDocument:[down.repositoryItem canSetContentStream]];
    [doc setContentMimeType:[down cmisContentStreamMimeType]];
    [doc setHidesBottomBarWhenPushed:YES];
    [doc setSelectedAccountUUID:[down selectedAccountUUID]];
    [doc setTenantID:[down tenantID]];
    [doc setShowReviewButton:YES];
    
    DownloadMetadata *fileMetadata = down.downloadMetadata;
    NSString *filename = (fileMetadata.key) ? fileMetadata.key : down.filename;
    [doc setFileName:filename];
    [doc setFilePath:filePath];
    [doc setFileMetadata:fileMetadata];
    [doc setIsRestrictedDocument:[[AlfrescoMDMLite sharedInstance] isRestrictedDocument:fileMetadata]];
 
    [[FileDownloadManager sharedInstance] setDownload:fileMetadata.downloadInfo forKey:filename];
	
    [IpadSupport pushDetailController:doc withNavigation:self.navigationController andSender:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(detailViewControllerChanged:) name:kDetailViewControllerChangedNotification object:nil];
	[doc release];
    
    self.selectedIndex = self.willSelectIndex;
    self.willSelectIndex = nil;
}

- (void)downloadWasCancelled:(DownloadProgressBar *)down
{
	[self.tableView deselectRowAtIndexPath:self.willSelectIndex animated:YES];
    
    // We don't want to reselect the previous row in iPhone
    if (IS_IPAD)
    {
        if (self.selectedIndex.section < [self.tableView numberOfSections])
        {
            if (self.selectedIndex.row < [self.tableView numberOfRowsInSection:self.selectedIndex.section])
            {
                [self.tableView selectRowAtIndexPath:self.selectedIndex animated:YES scrollPosition:UITableViewScrollPositionNone];
            }
        } 
    }
}

#pragma mark - FolderItemsHTTPRequest delegate methods

- (void)folderItemsRequestFinished:(ASIHTTPRequest *)request 
{    
    [self stopHUD];
	// if we're being told that a list of folder items is ready
	if ([request isKindOfClass:[FolderItemsHTTPRequest class]])
    {
		FolderItemsHTTPRequest *fid = (FolderItemsHTTPRequest *) request;
		
		// if we got back a list of top-level items, find the document library item
		if ([fid.context isEqualToString:@"topLevel"])
        {
			BOOL docLibAvailable = NO;
			for (RepositoryItem *item in self.itemDownloader.children)
            {
				if (NSOrderedSame == [item.title caseInsensitiveCompare:@"documentLibrary"])
                {
					// this item is the doc library; find its children
					[self startHUD];
					docLibAvailable = YES;
					NSDictionary *optionalArguments = [[LinkRelationService shared] defaultOptionalArgumentsForFolderChildrenCollection];											   
					NSURL *getChildrenURL = [[LinkRelationService shared] getChildrenURLForCMISFolder:item withOptionalArguments:optionalArguments];
					FolderItemsHTTPRequest *down = [[FolderItemsHTTPRequest alloc] initWithURL:getChildrenURL accountUUID:self.selectedAccountUUID];
                    [down setDelegate:self];
                    [down setDidFinishSelector:@selector(folderItemsRequestFinished:)];
                    [down setDidFailSelector:@selector(folderItemsRequestFailed:)];
					[down setItem:item];
                    [self setItemDownloader:down];
                    [down setParentTitle:fid.parentTitle];
					[down startAsynchronous];
					[down release];
                    
					break;
				}
			}
			
			if (NO == docLibAvailable)
            {
				// create a new view controller for the list of repository items (documents and folders)
				RepositoryNodeViewController *vc = [[RepositoryNodeViewController alloc] initWithStyle:UITableViewStylePlain];
                [vc setFolderItems:fid];
                [vc setTitle:[fid parentTitle]];
				[vc setGuid:[[fid item] guid]];
                [vc setSelectedAccountUUID:self.selectedAccountUUID];
                [vc setTenantID:self.tenantID];
				
				// push that view onto the nav controller's stack
				[self.navigationController pushViewController:vc animated:YES];
				[vc release];
			}
            else
            {
                [self dataSourceFinishedLoadingWithSuccess:YES];
            }
		}
		else if ([fid.context isEqualToString:@"rootCollection"]) 
        {
            //Since this request is concurrent with the sites request, we don't want to hide
            //the HUD unless it already finished
            if (![[SitesManagerService sharedInstanceForAccountUUID:self.selectedAccountUUID tenantID:self.tenantID] isExecuting])
            {
                [self dataSourceFinishedLoadingWithSuccess:YES];
                [self stopHUD];
            }
            // did we get back the items in "company home"?
            [self setCompanyHomeItems:[self.companyHomeDownloader children]];
			[self reloadTableViewData];
		}
		
		// if it's not a list of top-level items, it's the items in the doc library
		else
        {
            [self stopHUD];
			// create a new view controller for the list of repository items (documents and folders)
			RepositoryNodeViewController *vc = [[RepositoryNodeViewController alloc] initWithStyle:UITableViewStylePlain];
			[vc setFolderItems:fid];
            [vc setTitle:[fid parentTitle]];
            [vc setGuid:[[fid item] guid]];
            [vc setSelectedAccountUUID:self.selectedAccountUUID];
            [vc setTenantID:self.tenantID];
            

			// push that view onto the nav controller's stack
			[self.navigationController pushViewController:vc animated:YES];
			[vc release];
		}
    }
}

- (void)folderItemsRequestFailed:(ASIHTTPRequest *)request
{
    [self dataSourceFinishedLoadingWithSuccess:NO];
    [self clearAllHUDs];
    AlfrescoLogDebug(@"FAILURE %@", [request error]);
}

- (void)requestFinished:(ASIHTTPRequest *)request 
{
    [self stopHUD];
    
    // if we've got back the type description
	if ([request isKindOfClass:[CMISTypeDefinitionHTTPRequest class]])
    {
		CMISTypeDefinitionHTTPRequest *tdd = (CMISTypeDefinitionHTTPRequest *)request;
		
		// create a new view controller for the list of repository items (documents and folders)
        MetaDataTableViewController *viewController = [[MetaDataTableViewController alloc] initWithStyle:UITableViewStylePlain 
                                                                                              cmisObject:[tdd repositoryItem] 
                                                                                             accountUUID:self.selectedAccountUUID 
                                                                                                tenantID:self.tenantID];
        [viewController setCmisObjectId:tdd.repositoryItem.guid];
        [viewController setMetadata:tdd.repositoryItem.metadata];
        [viewController setPropertyInfo:tdd.properties];
        [viewController setSelectedAccountUUID:self.selectedAccountUUID];
        [viewController setTenantID:self.tenantID];
        
        [IpadSupport pushDetailController:viewController withNavigation:self.navigationController andSender:self];
        
        [viewController release];
	}
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    [self clearAllHUDs];
    AlfrescoLogDebug(@"FAILURE %@", [request error]);
}


#pragma mark - Instance Methods

-(void)refreshViewData
{
    [self metaDataChanged];
}

-(void)metaDataChanged
{
    // If a request is active we should not try to reload
    if (!self.HUD)
    {
        [self requestAllSites:nil forceReload:YES];
    }
}

- (void)cancelAllHTTPConnections
{
    [self stopHUD];
	
    [self.companyHomeDownloader clearDelegatesAndCancel];
    [self.itemDownloader clearDelegatesAndCancel];
    [self.progressBar.httpRequest clearDelegatesAndCancel];
    [self.typeDownloader clearDelegatesAndCancel];
}

- (void)dataSourceFinishedLoadingWithSuccess:(BOOL) wasSuccessful
{
    if (wasSuccessful)
    {
        [self setLastUpdated:[NSDate date]];
        [self.refreshHeaderView refreshLastUpdatedDate];
    }
    [self.refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
}

#pragma mark - ServiceManagerListener methods

-(void)serviceDocumentRequestFinished:(ServiceDocumentRequest *)serviceRequest
{
    [self stopHUD];
    if([[RepositoryServices shared] getRepositoryInfoForAccountUUID:self.selectedAccountUUID tenantID:self.tenantID]) 
    {
        [self requestAllSites:nil];
        
        // We have the Service Document for the current tenant, so ok to clear listeners
        [[CMISServiceManager sharedManager] removeListener:self forAccountUuid:self.selectedAccountUUID];
    }
}

- (void)serviceDocumentRequestFailed:(ServiceDocumentRequest *)serviceRequest 
{
    AlfrescoLogDebug(@"ServiceDocument Request Failure \n\tErrorDescription: %@ \n\tErrorFailureReason:%@ \n\tErrorObject:%@", 
          [serviceRequest.error description], [[serviceRequest error] localizedFailureReason],[serviceRequest error]);
    
#if defined (TARGET_ALFRESCO)
    showSitesOptions = YES;
#endif
    [self reloadTableViewData];
    
    [[CMISServiceManager sharedManager] removeListener:self forAccountUuid:self.selectedAccountUUID];
    
	[self clearAllHUDs];
}

#pragma mark - HTTP Request Handling

- (void)requestAllSites:(id)sender
{
    [self requestAllSites:sender forceReload:NO];
}

- (void)requestAllSites:(id)sender forceReload:(BOOL)reload
{
    showSitesOptions = isAlfrescoAccount;
    
    self.expandedCellIndexPath = nil;

    if (showSitesOptions)
    {
        // We build a queue with favorites, all sites, my sites and company home (if enabled)
        [self showSegmentedControl];
        SitesManagerService *sitesService = [SitesManagerService sharedInstanceForAccountUUID:self.selectedAccountUUID tenantID:self.tenantID];
        if (!reload && [sitesService hasResults])
        {
            [self siteManagerFinished:sitesService];
        }
        else
        {
            [self startHUD];
            [sitesService startOperations];
        }
    }
    else
    {
        // Normal CompanyHome request
        [self hideSegmentedControl];
    }
    
    // Show Root Collection, hide if user only wants to see Alfresco Sites
	if (!(isAlfrescoAccount) || (YES == userPrefShowCompanyHome()))
	{
        [self startHUD];
        [self.companyHomeDownloader clearDelegatesAndCancel];
        [self setCompanyHomeDownloader:[self companyHomeRequest]];
        [self.companyHomeDownloader startAsynchronous];
	}
}

- (FolderItemsHTTPRequest *)companyHomeRequest 
{
    RepositoryInfo *currentRepository = [[RepositoryServices shared] getRepositoryInfoForAccountUUID:self.selectedAccountUUID tenantID:self.tenantID];
    NSString *folder = [currentRepository rootFolderHref];
    if (!folder) // FIXME: handle me gracefully here
    {
        return nil;
    }
    
    NSDictionary *defaultParamsDictionary = [[LinkRelationService shared] defaultOptionalArgumentsForFolderChildrenCollection]; 
    NSURL *folderChildrenCollectionURL = [[NSURL URLWithString:folder] URLByAppendingParameterDictionary:defaultParamsDictionary];
    
    // find the items in the "Company Home" folder
    // start loading the list of top-level items for this site
    FolderItemsHTTPRequest *down = [[[FolderItemsHTTPRequest alloc] initWithURL:folderChildrenCollectionURL accountUUID:self.selectedAccountUUID] autorelease];
    [down setDelegate:self];
    [down setDidFinishSelector:@selector(folderItemsRequestFinished:)];
    [down setDidFailSelector:@selector(folderItemsRequestFailed:)];
    [down setParentTitle:[[self navigationItem] title]];
    [down setContext:@"rootCollection"];
    [down setTenantID:self.tenantID];
    
    return down;
}

#pragma mark - SitesManagerDelegate methods

- (void)siteManagerFinished:(SitesManagerService *)siteManager
{
    [self dataSourceFinishedLoadingWithSuccess:YES];
    self.allSites = [siteManager allSites];
    self.mySites = [siteManager mySites];
    self.favSites = [siteManager favoriteSites];
    
    [self segmentedControlChange:self.segmentedControl];
    [[self tableView] setNeedsDisplay];
	[self clearAllHUDs];
}

- (void)siteManagerFailed:(SitesManagerService *)siteManager
{
    [self dataSourceFinishedLoadingWithSuccess:NO];
    self.allSites = nil;
    self.mySites = nil;
    self.favSites = nil;

    [self segmentedControlChange:self.segmentedControl];
    [self reloadTableViewData];
    [self stopHUD];
}

#pragma mark - DetailViewController event

- (void)detailViewControllerChanged:(NSNotification *) notification
{
    id sender = [notification object];
    
    if (sender && ![sender isEqual:self])
    {
        self.selectedIndex = nil;
        
        [self.tableView selectRowAtIndexPath:nil animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
}

#pragma mark - MBProgressHUD Helper Methods

- (void)hudWasHidden:(MBProgressHUD *)hud
{
	[self stopHUD];
}

- (void)startHUD
{
	if (!self.HUD)
    {
        self.HUD = createAndShowProgressHUDForView(self.navigationController.view);
        [self.HUD setDelegate:self];
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

- (void)clearAllHUDs
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
        for (UIView *view in [self.navigationController.view subviews])
        {
            if ([view class] == [MBProgressHUD class])
            {
                stopProgressHUD((MBProgressHUD*)view);
            }
        }
		self.HUD = nil;
    });
}

#pragma mark - Global notifications

- (void)applicationWillResignActive:(NSNotification *) notification
{
    AlfrescoLogDebug(@"applicationWillResignActive in RootViewController");
    
    [self cancelAllHTTPConnections];
}

- (void)handleAccountListUpdated:(NSNotification *)notification 
{
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(handleAccountListUpdated:) withObject:notification waitUntilDone:NO];
        return;
    }
    
    if (![[AccountManager sharedManager] accountInfoForUUID:self.selectedAccountUUID])
    {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    
    [self setupBackButton];
}

- (void)userPreferencesChanged:(NSNotification *)notification 
{
    [self.navigationController popToViewController:self animated:NO];
    [self metaDataChanged];
}

#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self.refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}

#pragma mark - EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view
{
    [self refreshViewData];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view
{
	return (self.HUD != nil);
}

- (NSDate *)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view
{
	return [self lastUpdated];
}

#pragma mark - SiteTableViewCellDelegate methods

- (void)tableCell:(SiteTableViewCell *)tableCell siteAction:(NSDictionary *)actionInfo
{
    NSString *actionId = [actionInfo objectForKey:@"id"];
    RepositoryItem *site = tableCell.site;
    SitesManagerService *sitesManager = [SitesManagerService sharedInstanceForAccountUUID:self.selectedAccountUUID tenantID:self.tenantID];
    [sitesManager performAction:actionId onSite:site completionBlock:^(NSError *error) {
        if (error)
        {
            NSString *errorKey = [NSString stringWithFormat:@"site.action.%@.error", actionId];

            // Notify user...
            displayErrorMessageWithTitle([NSString stringWithFormat:NSLocalizedString(errorKey, @"Action-specific error"), site.title], NSLocalizedString(@"site.action.error.title", @"Site Error"));
        }
        else
        {
            NSString *successKey = [NSString stringWithFormat:@"site.action.%@.success", actionId];
            displayInformationMessage(NSLocalizedString(successKey, @"Action-specific success message"));

            self.mySites = [sitesManager mySites];
            self.favSites = [sitesManager favoriteSites];

            [site.metadata setObject:[NSNumber numberWithBool:[sitesManager isFavoriteSite:site]] forKey:@"isFavorite"];
            [site.metadata setObject:[NSNumber numberWithBool:[sitesManager isMemberOfSite:site]] forKey:@"isMember"];
            [site.metadata setObject:[NSNumber numberWithBool:[sitesManager isPendingMemberOfSite:site]] forKey:@"isPendingMember"];

            NSInteger selectedSegment = self.segmentedControl.selectedSegmentIndex;
            if (selectedSegment == 0 && ([actionId isEqualToString:@"favorite"] || [actionId isEqualToString:@"unfavorite"]))
            {
                self.activeSites = self.favSites;
                self.expandedCellIndexPath = nil;
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            }
            else if (selectedSegment == 1 && ([actionId isEqualToString:@"join"] || [actionId isEqualToString:@"leave"]))
            {
                self.activeSites = self.mySites;
                self.expandedCellIndexPath = nil;
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
            }
            else
            {
                [self.tableView beginUpdates];
                [self.tableView endUpdates];
            }
        }
        [tableCell setSite:site];
    }];
}

- (void)loadRightBarAnimated:(BOOL)animated
{
    // We only show the second button if any option is going to be displayed
    NSMutableArray *rightBarButtons = [NSMutableArray array];
        
    
    UIBarButtonItem *addButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                    target:self
                                                                                    action:@selector(performAddAction:event:)] autorelease];
        addButton.style = UIBarButtonItemStyleBordered;
        [rightBarButtons addObject:addButton];
    
    [self.navigationItem setRightBarButtonItems:rightBarButtons animated:animated];

}

- (void)performAddAction:(id)sender event:(UIEvent *)event
{
    RepositoryItem *item = [[RepositoryItem alloc] init];
    item.identLink = [NSString stringWithFormat:@"%@/%@/children?id=%@",[[[AlfrescoUtils sharedInstanceForAccountUUID:self.selectedAccountUUID] serviceDocumentURL] absoluteString], self.repositoryID, self.repositoryID];
    CreateFolderViewController *createFolder = [[[CreateFolderViewController alloc] initWithParentItem:item accountUUID:self.selectedAccountUUID] autorelease];
    createFolder.delegate = self;
    [createFolder setModalPresentationStyle:UIModalPresentationFormSheet];
    [IpadSupport presentModalViewController:createFolder withNavigation:self.navigationController];
}

- (void) dismissPopover
{
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSString *buttonLabel = nil;
    [actionSheet dismissWithClickedButtonIndex:0 animated:YES];
    [self setActionSheet:nil];
    
    if (buttonIndex > -1)
    {
        buttonLabel = [actionSheet buttonTitleAtIndex:buttonIndex];
    }
    
	if (buttonIndex != [actionSheet cancelButtonIndex])
    {
        switch ([actionSheet tag])
        {
            case kOperationActionSheetTag:
                [self processOperationsActionSheetWithButtonTitle:buttonLabel];
                break;
            default:
                break;
        }
    }
}

- (void)processOperationsActionSheetWithButtonTitle:(NSString *)buttonLabel
{
    if ([buttonLabel isEqualToString:NSLocalizedString(@"operation.pop.menu.delete", @"Delete")])
    {
        [self showDeleteItemPrompt];
    }
    else if ([buttonLabel isEqualToString:NSLocalizedString(@"operation.pop.menu.rename", @"Rename")])
    {
        [self showRenameItemPrompt];
    }
}

#pragma mark - Create Folder Delegate
- (void)createFolder:(CreateFolderViewController *)createFolder succeededForName:(NSString *)folderName {
    displayInformationMessage([NSString stringWithFormat:NSLocalizedString(@"create-folder.success", @"Created folder"), folderName]);
    [self refreshViewData];
}

- (void)createFolder:(CreateFolderViewController *)createFolder failedForName:(NSString *)folderName {
    displayInformationMessage([NSString stringWithFormat:NSLocalizedString(@"create-folder.failure", @"Created folder"), folderName]);
}

- (void)createFolderCancelled:(CreateFolderViewController *)createFolder {
    
}

#pragma mark  - Operations Prompt method

- (void)showDeleteItemPrompt
{
    if (_selectedItem) {
        NSString  *fileName = _selectedItem.title;
        UIAlertView *deleteItemPrompt = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"confirm.delete.prompt.title", @"")
                                                                    message:[NSString stringWithFormat:NSLocalizedString(@"confirm.delete.prompt.message", @"Are you sure to delete file %@?"), fileName]
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"confirm.delete.prompt.cancel", @"Cancel")
                                                          otherButtonTitles:NSLocalizedString(@"confirm.delete.prompt.ok", @"Delete"), nil] autorelease];
        [deleteItemPrompt setTag:kDeleteFileAlert];
        [deleteItemPrompt show];
    }
}

- (void) showRenameItemPrompt
{
    if (_selectedItem) {
        NSString  *fileName = _selectedItem.title;
        UIAlertView *renameItemPrompt = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"confirm.rename.prompt.title", @"")
                                                                    message:[NSString stringWithFormat:NSLocalizedString(@"confirm.rename.prompt.message", @"")]
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"confirm.rename.prompt.cancel", @"Cancel")
                                                          otherButtonTitles:NSLocalizedString(@"confirm.rename.prompt.ok", @"Ok"), nil] autorelease];
        renameItemPrompt.alertViewStyle = UIAlertViewStylePlainTextInput;
        UITextField *inputTextField = [renameItemPrompt textFieldAtIndex:0];
        inputTextField.text = fileName;
        
        [renameItemPrompt setTag:kRenameFileAlert];
        [renameItemPrompt show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kDeleteFileAlert)
    {
        if (buttonIndex != alertView.cancelButtonIndex && _selectedItem)
        {
            self.deleteQueueProgressBar = [DeleteQueueProgressBar createWithItems:[NSArray arrayWithObjects:_selectedItem,nil] delegate:self andMessage:NSLocalizedString(@"Deleting Item", @"Deleting Item")];
            [self.deleteQueueProgressBar setSelectedUUID:self.selectedAccountUUID];
            [self.deleteQueueProgressBar setTenantID:self.tenantID];
            [self.deleteQueueProgressBar startDeleting];
        }
        _selectedItem = nil;
    }
    else if (alertView.tag == kRenameFileAlert)
    {
        if (buttonIndex != alertView.cancelButtonIndex && _selectedItem)
        {
            UITextField *inputTextField = [alertView textFieldAtIndex:0];
            NSString  *fileName = _selectedItem.title;
            NSString  *newFilename = inputTextField.text;
            if ((newFilename && [newFilename length] > 0) && ![fileName isEqualToString:newFilename]) {  //not nil and not equal to old file name
                [self renameItem:newFilename];
            }
        }
        _selectedItem = nil;
    }
    return;
}

#pragma mark - Rename File & Folder
- (void) renameItem:(NSString*) newFileName
{
    if (_selectedItem && newFileName) {
        self.renameQueueProgressBar = [RenameQueueProgressBar createWithItem:[NSDictionary dictionaryWithObjectsAndKeys:_selectedItem, @"Item", newFileName, @"NewFileName",nil] delegate:self andMessage:NSLocalizedString(@"Rrename.progressbar.message", @"Renaming Item")];
        [self.renameQueueProgressBar setSelectedUUID:self.selectedAccountUUID];
        [self.renameQueueProgressBar setTenantID:self.tenantID];
        [self.renameQueueProgressBar startRenaming];
    }
}

#pragma mark - RenameQueueProgressBar Delegate Methods

- (void)renameQueue:(RenameQueueProgressBar *)renameQueueProgressBar completedRename:(id)renamedItem
{
    RepositoryItem *item =  [renamedItem objectForKey:@"Item"];
    if (IS_IPAD && [item.guid isEqualToString:[IpadSupport getCurrentDetailViewControllerObjectID]]) {
        
        [IpadSupport clearDetailController];
    }
    
    [self.tableView setAllowsMultipleSelectionDuringEditing:NO];
    [self.tableView setEditing:NO animated:YES];
    [[self refreshHeaderView] setHidden:NO];
    [self refreshViewData];
}

- (void)renameQueueWasCancelled:(RenameQueueProgressBar *)renameQueueProgressBar
{
    self.renameQueueProgressBar = nil;
    [self setEditing:NO];
}

#pragma mark - DeleteQueueProgressBar Delegate Methods

- (void)deleteQueue:(DeleteQueueProgressBar *)deleteQueueProgressBar completedDeletes:(NSArray *)deletedItems
{
    [self refreshViewData];
}

- (void)deleteQueueWasCancelled:(DeleteQueueProgressBar *)deleteQueueProgressBar
{
    self.deleteQueueProgressBar = nil;
    [self setEditing:NO];
}

- (BOOL) canEditDataRoom
{
    return YES;  //TODO:how to know the data room can be operated.
}
@end
