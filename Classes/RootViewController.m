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
//  RootViewController.m
//

#import "RootViewController.h"
#import "RepositoryNodeViewController.h"
#import "RepositoryItem.h"
#import "RepositoryItemTableViewCell.h"
#import "Utility.h"
#import "DocumentViewController.h"
#import "MetaDataTableViewController.h"
#import "ServiceInfo.h"
#import "RepositoryServices.h"
#import "RepositoryItem.h"
#import "UIColor+Theme.h"
#import "WhiteGlossGradientView.h"
#import "Theme.h"
#import "ThemeProperties.h"
#import "AppProperties.h"
#import "LinkRelationService.h"
#import "NSURL+HTTPURLUtils.h"
#import "SimpleSettingsViewController.h"
#import "SavedDocument.h"
#import "IpadSupport.h"
#import "AlfrescoAppDelegate.h"
#import "Constants.h"
#import "FavoritesSitesHttpRequest.h"
#import "TableViewHeaderView.h"

// ** Class Constants
static NSInteger const kDefaultSelectedSegment = 2;

@interface RootViewController (private) 
-(void)startHUD;
-(void)stopHUD;
-(void)requestAllSites: (id)sender;
-(void)hideSegmentedControl;
-(void)showSegmentedControl;
-(FolderItemsDownload *)companyHomeRequest;
@end

@implementation RootViewController
@synthesize allSites;
@synthesize mySites;
@synthesize favSites;
@synthesize activeSites;
@synthesize companyHomeItems;
@synthesize itemDownloader;
@synthesize companyHomeDownloader;
@synthesize progressBar;
@synthesize typeDownloader;
@synthesize serviceDocumentRequest;
@synthesize currentRepositoryInfo;
@synthesize segmentedControl;
@synthesize tableView = _tableView;
@synthesize segmentedControlBkg;

@synthesize HUD;

static NSArray *siteTypes;

+ (void) initialize {
    siteTypes = [[NSArray arrayWithObjects:@"root.favsites",@"root.mysites",@"root.allsites", nil] retain];
}

#pragma mark Memory Management

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
	[allSites release];
    [mySites release];
    [favSites release];
    [activeSites release];
	[companyHomeItems release];
	[itemDownloader release];
	[companyHomeDownloader release];
	[progressBar release];
	[typeDownloader release];
    [serviceDocumentRequest release];
	[currentRepositoryInfo release];
    [segmentedControl release];
    [_tableView release];
    [segmentedControlBkg release];
    
	[HUD release];
    
    [selectedIndex release];
    [willSelectIndex release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
	
	// TODO: Should cancel all HTTP requests and notify user?
//    [self cancelAllHTTPConnections];
}

- (void)viewDidUnload {
	[super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"detailViewControllerChanged" object:nil];
	
	[self cancelAllHTTPConnections];
	
	[self stopHUD];
    
    //Release all the views that get loaded on viewDidLoad
    self.tableView = nil;
    
    NSLog(@"viewWillDisappear called");
}

#pragma View Lifecycle

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[Theme setThemeForUIViewController:self]; 
    
    [selectedIndex release];
    [willSelectIndex release];
    selectedIndex = nil;
    willSelectIndex = nil;
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSLog(@"viewWillDisappear called");
}

- (void)viewDidLoad {
	[super viewDidLoad];
    
    [self.navigationItem setTitle:NSLocalizedString(@"rootview.title", @"root view title")];
    //Default selection is "All sites"
    [self.segmentedControl setSelectedSegmentIndex:kDefaultSelectedSegment];
    //Apparently the changeSegment action is not executed before the tableview loads its cells
    //It causes incorrect label in the "No sites cell"
    selectedSiteType = [siteTypes objectAtIndex:kDefaultSelectedSegment];
    
    [self hideSegmentedControl];
    [self.segmentedControl setTintColor:[ThemeProperties segmentedControlColor]];
    [self.segmentedControl setBackgroundColor:[ThemeProperties segmentedControlBkgColor]];
    [self.segmentedControlBkg setBackgroundColor:[ThemeProperties segmentedControlBkgColor]];
	
    BOOL isFirstLaunch = NO;
    BOOL showSettings = [[AppProperties propertyForKey:kBShowSettingsButton] boolValue];
    
    if(showSettings) {
        UIImage *settingsGear = [UIImage imageNamed:@"whitegear.png"];
        UIBarButtonItem *loginCredentialsButton = [[UIBarButtonItem alloc] initWithImage:settingsGear 
                                                                                   style:UIBarButtonItemStylePlain 
                                                                                  target:self 
                                                                                  action:@selector(showLoginCredentialsView:)];
        [self.navigationItem setRightBarButtonItem:loginCredentialsButton];
        [loginCredentialsButton release];
        
        isFirstLaunch = ([[NSUserDefaults standardUserDefaults] objectForKey:@"isFirstLaunch"] == nil);
        if ( isFirstLaunch ) {
            [self showLoginCredentialsView:nil];
        }
    }
    
    [self hideSegmentedControl];
    
    if ( !isFirstLaunch && ([[RepositoryServices shared] currentRepositoryInfo] == nil)) {
        [self startHUD];
        
        ServiceDocumentRequest *request = [ServiceDocumentRequest httpGETRequest]; 
        [request setDelegate:self];
        [request setDidFinishSelector:@selector(requestAllSites:)];
        [request setDidFailSelector:@selector(serviceDocumentRequestFailed:)];
        [self setServiceDocumentRequest:request];
        [request startAsynchronous];
    } else if(!isFirstLaunch && ([[RepositoryServices shared] currentRepositoryInfo] != nil)) {
        [self requestAllSites:nil];
    }
    
    UIBarButtonItem *reloadButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshViewData)] autorelease];
    [self.navigationItem setRightBarButtonItem:reloadButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(repositoryShouldReload:) name:kNotificationRepositoryShouldReload object:nil];
}

//FIXME uncomment the methods once we figure out how are we going to handle non-alfresco repositories
- (void)hideSegmentedControl {
    /*[segmentedControl setHidden:YES];
    [segmentedControlBkg setHidden:YES];
    self.tableView.frame = self.view.frame;*/
}

- (void)showSegmentedControl {
    /*[segmentedControl setHidden:NO];
    [segmentedControlBkg setHidden:NO];
    CGRect tableFrame = self.view.frame;
    tableFrame.size.height = tableFrame.size.height - segmentedControlBkg.frame.size.height;
    tableFrame.origin.y = segmentedControlBkg.frame.size.height;
    self.tableView.frame = tableFrame;*/
}

- (IBAction)segmentedControlChange:(id)sender {
    NSInteger selectedSegment = segmentedControl.selectedSegmentIndex;
    selectedSiteType = [siteTypes objectAtIndex:segmentedControl.selectedSegmentIndex];
    
    switch(selectedSegment) {
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
    [self.tableView reloadData];
}

- (IBAction)showLoginCredentialsView:(id)sender {
    
    SimpleSettingsViewController *viewController = [[SimpleSettingsViewController alloc] initWithStyle:UITableViewStylePlain];
    [viewController setDelegate:self];
    
    
    UINavigationController *flipsideNavController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [viewController release];
    
    [self.navigationController setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
    [self.navigationController presentModalViewController:flipsideNavController animated:YES];
    [flipsideNavController release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

#pragma mark -
#pragma mark UITableViewDataSource methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if ([[RepositoryServices shared] isCurrentRepositoryVendorNameEqualTo:kAlfrescoRepositoryVendorName]) {
        NSString *titleHeader = nil;
        if(section == 1) {
            titleHeader = NSLocalizedString(@"rootSectionHeaderCompanyHome", @"Company Home");
        } else {
            // Remove the section header as requested by Alfresco
            // TODO: Remove localized strings once certain that this is expected behavior.
//            NSString *localizedKey = [NSString stringWithFormat:@"%@.sectionheader",selectedSiteType];
//            titleHeader = showSitesOptions? NSLocalizedString(localizedKey, @"Favorite Sites") : NSLocalizedString(@"rootSectionHeaderSites", @"Sites");
            
            return nil;
        }
		return titleHeader;
    } else { 
		return nil;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if ([[RepositoryServices shared] isCurrentRepositoryVendorNameEqualTo:kAlfrescoRepositoryVendorName])
		return (userPrefShowCompanyHome() ? 2 : 1);
	else {
		return 1;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
 
	if ((NAN != section) && [[RepositoryServices shared] isCurrentRepositoryVendorNameEqualTo:kAlfrescoRepositoryVendorName])
        if(section == 1) {
            return companyHomeItems?[companyHomeItems count]:0;
        } else {
            if(showSitesOptions) {
                return [activeSites count] != 0?[activeSites count]:1;
            } else {
                return activeSites?[activeSites count]:0;
            }
        }
	else
		return [companyHomeItems count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if ([[RepositoryServices shared] isCurrentRepositoryVendorNameEqualTo:kAlfrescoRepositoryVendorName] && ([indexPath section] == 0))
	{
		// We are in the sites section
		static NSString *CellIdentifier = @"Cell";		
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		}
		
        NSString *folderImageName = ( ([indexPath section] == 0) ? @"site.png" : @"folder.png");
		NSArray *collection = ([indexPath section] == 1) ? self.companyHomeItems : self.activeSites;
        
        if([collection count] > 0) {
            cell.textLabel.text = [[collection objectAtIndex:[indexPath row]] title];
            cell.imageView.image = [UIImage imageNamed:folderImageName];
            [cell setAccessoryType:UITableViewCellAccessoryNone];
            [cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
        } else if(showSitesOptions) {
            NSString *localizedKey = [NSString stringWithFormat:@"%@.nosites",selectedSiteType];
            cell.textLabel.text = NSLocalizedString(localizedKey, @"No favorite sites");
            [cell setAccessoryType:UITableViewCellAccessoryNone];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            cell.imageView.image = nil;
        }
        
		return cell;
	}
	else {
		
		// We are looking at a child item in the Root Collection
		
		RepositoryItemTableViewCell *cell = (RepositoryItemTableViewCell *) [tableView dequeueReusableCellWithIdentifier:RepositoryItemCellIdentifier];
		if (cell == nil) {
			NSArray *nibItems = [[NSBundle mainBundle] loadNibNamed:@"RepositoryItemTableViewCell" owner:self options:nil];
			cell = [nibItems objectAtIndex:0];
			NSAssert(nibItems, @"Failed to load object from NIB");
		}
		
		RepositoryItem *child = [self.companyHomeItems objectAtIndex:[indexPath row]];
		
        NSString *filename = [child.metadata valueForKey:@"cmis:name"];
        if (!filename || ([filename length] == 0)) filename = child.title;
		[cell.filename setText:filename];
        
		if ([child isFolder]) {
			UIImage * img = [UIImage imageNamed:@"folder.png"];
			cell.imageView.image  = img;

			//		cell.details.text = [[NSString alloc] initWithFormat:@"%@ %@", child.lastModifiedBy, formatDateTime(child.lastModifiedDate)];
            // cell.details.text = [[NSString alloc] initWithFormat:@"%@", formatDateTime(child.lastModifiedDate)]; // TODO: Externalize to a configurable property?
            cell.details.text = [[[NSString alloc] initWithFormat:@"%@", formatDocumentDate(child.lastModifiedDate)] autorelease]; // TODO: Externalize to a configurable property?
		}
		else {
		    NSString *contentStreamLengthStr = [child.metadata objectForKey:@"cmis:contentStreamLength"];
            cell.details.text = [[[NSString alloc] initWithFormat:@"%@ | %@", formatDocumentDate(child.lastModifiedDate), 
                                 [SavedDocument stringForLongFileSize:[contentStreamLengthStr longLongValue]]] autorelease]; // TODO: Externalize to a configurable property?
            cell.imageView.image = imageForFilename(child.title);
		}

        BOOL showMetadataDisclosure = [[AppProperties propertyForKey:kBShowMetadataDisclosure] 
                                       boolValue];
        
        if(showMetadataDisclosure && [[[RepositoryServices shared] currentRepositoryInfo] isPreReleaseCmis]) {
            [cell setAccessoryView:[self makeDetailDisclosureButton]];
        } else {
            [cell setAccessoryType:UITableViewCellAccessoryNone];
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

- (void)accessoryButtonTapped:(UIControl *)button withEvent:(UIEvent *)event
{
    NSIndexPath * indexPath = [self.tableView indexPathForRowAtPoint:[[[event touchesForView:button] anyObject] locationInView:self.tableView]];
    if ( indexPath == nil )
        return;
    
    [self.tableView.delegate tableView:self.tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
}

#pragma mark -
#pragma mark UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
	if ((nil == sectionTitle))
		return nil;
    
    //The height gets adjusted if it is less than the needed height
    TableViewHeaderView *headerView = [[[TableViewHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, [tableView bounds].size.width, 10) label:sectionTitle] autorelease];
    [headerView setBackgroundColor:[ThemeProperties browseHeaderColor]];
    [headerView.textLabel setTextColor:[ThemeProperties browseHeaderTextColor]];
    
	return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
	if ((nil == sectionTitle))
		return 0.0f;
	
	TableViewHeaderView *headerView = [[[TableViewHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, [tableView bounds].size.width, 10) label:sectionTitle] autorelease];
	return headerView.frame.size.height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    //Selected a "No sites" cell
    if([self.activeSites count] <= 0) {
        return;
    }
	[self cancelAllHTTPConnections];
	
	if ([[RepositoryServices shared] isCurrentRepositoryVendorNameEqualTo:kAlfrescoRepositoryVendorName] && ([indexPath section] == 0))
	{
        [self startHUD];
		// Alfresco Sites, special case
		// get the site information associated with this row
		RepositoryItem *site = [self.activeSites objectAtIndex:[indexPath row]];
		
		// start loading the list of top-level items for this site
		FolderItemsDownload *down = [[FolderItemsDownload alloc] initWithNode:[site node] delegate:self];		
        [down setItem:site];
		down.context = @"topLevel";
		down.parentTitle = site.title;
		self.itemDownloader = down;
        down.showHUD = NO;
		[down start];
		[down release];
		
	}
	else { // Root Collection Child
//		[self startHUD];
		// get the document/folder information associated with this row
		RepositoryItem *item = [self.companyHomeItems objectAtIndex:[indexPath row]];
		
		if ([item isFolder]) {
			NSDictionary *optionalArguments = [[LinkRelationService shared] defaultOptionalArgumentsForFolderChildrenCollection];											   
			NSURL *getChildrenURL = [[LinkRelationService shared] getChildrenURLForCMISFolder:item withOptionalArguments:optionalArguments];
			FolderItemsDownload *down = [[FolderItemsDownload alloc] initWithURL:getChildrenURL delegate:self];
			
			down.item = item;
			down.context = @"childFolder";
			down.parentTitle = item.title;
            down.showHUD = NO;
			self.itemDownloader = down;
			[down start];
			[down release];
		}
		else {
			NSString* urlStr = item.contentLocation;
			self.progressBar = [DownloadProgressBar createAndStartWithURL:[NSURL URLWithString:urlStr] delegate:self 
																  message:NSLocalizedString(@"Downloading Document", @"Downloading Document") 
                                                                 filename:item.title];
            [[self progressBar] setCmisObjectId:[item guid]];
            [[self progressBar] setCmisContentStreamMimeType:[[item metadata] objectForKey:@"cmis:contentStreamMimeType"]];
            [[self progressBar] setRepositoryItem:item];
            
            [willSelectIndex release];
            willSelectIndex = [indexPath retain];
		}
	}
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	
	[self cancelAllHTTPConnections];
    
    // get the document/folder information associated with this row
    RepositoryItem *item = [self.companyHomeItems objectAtIndex:[indexPath row]];
	
	if ([[RepositoryServices shared] isCurrentRepositoryVendorNameEqualTo:kAlfrescoRepositoryVendorName] && ([indexPath section] == 0))
	{
		// Alfresco Sites, special case
		
		// get the site information associated with this row
		// Site *s = [self.siteInfo objectAtIndex:[indexPath row]];
		// TODO: implement view/edit metadata on sites 
	}
	else {
		// Root Collection Child Item Case
		[self startHUD];
        
		CMISTypeDefinitionDownload *down = [[CMISTypeDefinitionDownload alloc] initWithURL:[NSURL URLWithString:item.describedByURL] delegate:self];
		down.repositoryItem = item;
        down.showHUD = NO;
		[down start];
		[down release];
	}	
}

#pragma mark -
#pragma mark DownloadProgressBarDelegate

- (void)download:(DownloadProgressBar *)down completeWithData:(NSData *)data
{
	NSString *nibName = @"DocumentViewController";
	DocumentViewController *doc = [[DocumentViewController alloc] initWithNibName:nibName bundle:[NSBundle mainBundle]];
    if (down.cmisObjectId) {
        [doc setCmisObjectId:down.cmisObjectId];
    }
    [doc setContentMimeType:[down cmisContentStreamMimeType]];
    [doc setFileData:data];
    [doc setHidesBottomBarWhenPushed:YES];
    
    DownloadMetadata *fileMetadata = down.downloadMetadata;
    NSString *filename;
    
    if(fileMetadata.key) {
        filename = fileMetadata.key;
    } else {
        filename = down.filename;
    }
    
    [doc setFileName:filename];
    [doc setFileMetadata:fileMetadata];
	
    [IpadSupport pushDetailController:doc withNavigation:self.navigationController andSender:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(detailViewControllerChanged:) name:@"detailViewControllerChanged" object:nil];
	[doc release];
    
    [selectedIndex release];
    selectedIndex = willSelectIndex;
    willSelectIndex = nil;
}

- (void) downloadWasCancelled:(DownloadProgressBar *)down {
	[self.tableView deselectRowAtIndexPath:willSelectIndex animated:YES];
    
    // We don't want to reselect the previous row in iPhone
    if(IS_IPAD) {
        [self.tableView selectRowAtIndexPath:selectedIndex animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
}

#pragma mark -
#pragma mark AsynchronousDownloadDelegate

- (void) asyncDownloadDidComplete:(AsynchonousDownload *)async {
    
	
	// if we're being told that a list of folder items is ready
	if ([async isKindOfClass:[FolderItemsDownload class]]) {
		[self stopHUD];
		FolderItemsDownload *fid = (FolderItemsDownload *) async;
		
		// if we got back a list of top-level items, find the document library item
		if ([fid.context isEqualToString:@"topLevel"]) {
			
			BOOL docLibAvailable = NO;
			for (RepositoryItem *item in self.itemDownloader.children) {
				
				if ([item.title isEqualToString:@"documentLibrary"]) {
					
					// this item is the doc library; find its children
					[self startHUD];
					docLibAvailable = YES;
					NSDictionary *optionalArguments = [[LinkRelationService shared] defaultOptionalArgumentsForFolderChildrenCollection];											   
					NSURL *getChildrenURL = [[LinkRelationService shared] getChildrenURLForCMISFolder:item withOptionalArguments:optionalArguments];
					FolderItemsDownload *down = [[FolderItemsDownload alloc] initWithURL:getChildrenURL delegate:self];

					[down setItem:item];
                    down.showHUD = NO;
					self.itemDownloader = down;
					down.parentTitle = fid.parentTitle;
					[down start];
					[down release];
                    
					break;
				}
			}
			
			if (NO == docLibAvailable) {
				// create a new view controller for the list of repository items (documents and folders)
				RepositoryNodeViewController *vc = [[RepositoryNodeViewController alloc] initWithNibName:nil bundle:nil];
				vc.folderItems = fid;
				vc.title = fid.parentTitle;
				[vc setGuid:[[fid item] guid]];
				
				// push that view onto the nav controller's stack
				[self.navigationController pushViewController:vc animated:YES];
				[vc release];
			}
		}
		else if ([fid.context isEqualToString:@"rootCollection"]) 
        {
            //Since this request is concurrent with the sites reques, we don't want to hide
            //the HUD unless it already finished
            if(![[SitesManagerService sharedInstance] isExecuting]) {
                [self stopHUD];
            }
            // did we get back the items in "company home"?
            [self setCompanyHomeItems:[companyHomeDownloader children]];
			[self.tableView reloadData];
		}
		
		// if it's not a list of top-level items, it's the items in the doc library
		else {
            [self stopHUD];
			// create a new view controller for the list of repository items (documents and folders)
			RepositoryNodeViewController *vc = [[RepositoryNodeViewController alloc] initWithNibName:nil bundle:nil];
			
			vc.folderItems = fid;
			vc.title = fid.parentTitle;
			
			// push that view onto the nav controller's stack
			[self.navigationController pushViewController:vc animated:YES];
			[vc release];
		}
	}
	
	// if we've got back the type description
	else if ([async isKindOfClass:[CMISTypeDefinitionDownload class]]) {
		
		CMISTypeDefinitionDownload *tdd = (CMISTypeDefinitionDownload *) async;
		
		// create a new view controller for the list of repository items (documents and folders)
        MetaDataTableViewController *viewController = [[MetaDataTableViewController alloc] initWithStyle:UITableViewStylePlain 
                                                                                              cmisObject:[tdd repositoryItem]];
        [viewController setCmisObjectId:tdd.repositoryItem.guid];
        [viewController setMetadata:tdd.repositoryItem.metadata];
        [viewController setPropertyInfo:tdd.properties];

        [IpadSupport pushDetailController:viewController withNavigation:self.navigationController andSender:self];
        
        [viewController release];
//		[m setDocumentURL:[NSURL URLWithString:[[LinkRelationService shared] hrefForLinkRelation:kSelfLinkRelation 
//																					onCMISObject:tdd.repositoryItem]]];
		//		m.documentURL = [NSURL URLWithString:tdd.repositoryItem.selfURL];
//		[m setUpdateAction:@selector(metaDataChanged)];
//		[m setUpdateTarget:self];
		
		// push that view onto the nav controller's stack
//		[self.navigationController pushViewController:m animated:YES];
//		[m release];
	}
}

- (void)asyncDownload:(AsynchonousDownload *)async didFailWithError:(NSError *)error {
    [self stopHUD];
    NSLog(@"FAILURE %@", error);
}

#pragma mark -
#pragma mark MBProgressHUDDelegate

- (void)hudWasHidden
{
	[self.HUD removeFromSuperview];
	[self setHUD:nil];
}

#pragma mark -
#pragma mark Instance Methods

// If metaDataChanged is optimized to just update the latest object, the current logic
// to redownload the entire collection should be copied to this method
-(void)refreshViewData {
    shouldForceReload = YES;
    [self metaDataChanged];
}

-(void)metaDataChanged
{
    // A request is active we should not try to reload
    if(HUD) {
        return;
    }
    
    /*
	// FIXME: Optimize this step.  Currently it redownloads the entire collection, but we should instead just download and update the object that was updated.
	RepositoryInfo *RepositoryInfo = [[RepositoryServices shared] currentRepositoryInfo];
	NSString *folder = [RepositoryInfo rootFolderHref];
	NSLog(@"root folder: %@", folder);
	if (!folder) { // FIXME: handle me gracefully here
		return;
	}*/
    [self startHUD];
	
    ServiceDocumentRequest *request = [ServiceDocumentRequest httpGETRequest]; 
    [request setDelegate:self];
    [request setDidFinishSelector:@selector(requestAllSites:)];
    [request setDidFailSelector:@selector(serviceDocumentRequestFailed:)];
    [self setServiceDocumentRequest:request];
    
    if(shouldForceReload) {
        [request setCachePolicy:ASIAskServerIfModifiedCachePolicy];
    }
    [request startAsynchronous];
}

- (void)cancelAllHTTPConnections
{
	if (HUD) {
		[self.HUD hide:YES];
	}
	
	[self.itemDownloader cancel];
	[self.companyHomeDownloader cancel];
	[self.typeDownloader cancel];
    [[self serviceDocumentRequest] clearDelegatesAndCancel];
}

#pragma mark -
#pragma mark HTTP Request Handling

-(void)requestAllSites: (id)sender {
    showSitesOptions = [[RepositoryServices shared] isCurrentRepositoryVendorNameEqualTo:kAlfrescoRepositoryVendorName];
    
    if(showSitesOptions) {
        //We build a queue with favorites, all sites, my sites and company home (if enabled)
        [self showSegmentedControl];
        SitesManagerService *sitesService = [SitesManagerService sharedInstance];
        if([sitesService hasResults]) {
            [self siteManagerFinished:sitesService];
        } else {
            [self startHUD];
            [sitesService addListener:self];
            [sitesService startOperations];
        }
    } else {
        //Normal CompanyHome request
        [self hideSegmentedControl];
    }
    
    [self serviceDocumentRequestFinished:sender];
}

- (void)serviceDocumentRequestFinished:(ASIHTTPRequest *)sender
{
	// Show Root Collection, hide if user only wants to see Alfresco Sites
	if (!([[RepositoryServices shared] isCurrentRepositoryVendorNameEqualTo:kAlfrescoRepositoryVendorName]) || (YES == userPrefShowCompanyHome()))
	{
		self.companyHomeDownloader = [self companyHomeRequest];;
		[self.companyHomeDownloader  start];
        [self startHUD];
	}
    
    shouldForceReload = NO;
	
    [sender cancel];
}

- (FolderItemsDownload *) companyHomeRequest {
    RepositoryInfo *currentRepository = [[RepositoryServices shared] currentRepositoryInfo];
    NSString *folder = [currentRepository rootFolderHref];
    if (!folder) { // FIXME: handle me gracefully here
        return nil;
    }
    
    NSDictionary *defaultParamsDictionary = [[LinkRelationService shared] defaultOptionalArgumentsForFolderChildrenCollection]; 
    NSURL *folderChildrenCollectionURL = [[NSURL URLWithString:folder] URLByAppendingParameterDictionary:defaultParamsDictionary];
    
    //        NSURL *folderChildrenCollectionURL = [NSURL URLWithString:folder];
    
    // find the items in the "Company Home" folder
    FolderItemsDownload *down = [[FolderItemsDownload alloc] initWithURL:folderChildrenCollectionURL delegate:self];
    [down setContext:@"rootCollection"];
    [down setParentTitle:NSLocalizedString(@"Top", @"Name of 'Top' or Root Repository Folder")];
    down.showHUD = NO;
    if(shouldForceReload) {
        [down.httpRequest setCachePolicy:ASIAskServerIfModifiedCachePolicy];
    }
    
    [down autorelease];
    
    return down;
}

- (void)serviceDocumentRequestFailed:(ASIHTTPRequest *)sender
{
	NSLog(@"ServiceDocument Request Failure \n\tErrorDescription: %@ \n\tErrorFailureReason:%@ \n\tErrorObject:%@", 
          [[sender error] description], [[sender error] localizedFailureReason],[sender error]);

	[self stopHUD];
    shouldForceReload = NO;
    
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
#pragma mark SitesManagerDelegate methods

-(void)siteManagerFinished:(SitesManagerService *)siteManager {
    [self stopHUD];
    self.allSites = [siteManager allSites];
    self.mySites = [siteManager mySites];
    self.favSites = [siteManager favoriteSites];
    
    [self segmentedControlChange:segmentedControl];
    [[self tableView] reloadData];
    [[SitesManagerService sharedInstance] removeListener:self];
}

-(void)siteManagerFailed:(SitesManagerService *)siteManager {
    [self stopHUD];
    [[SitesManagerService sharedInstance] removeListener:self];
    //Request error already logged
}

#pragma mark -
#pragma SimpleSettingsViewDelegate
- (void)simpleSettingsViewDidFinish:(SimpleSettingsViewController *)controller settingsDidChange:(BOOL)settingsDidChange {
    
    [self startHUD];
    
    ServiceDocumentRequest *request = [ServiceDocumentRequest httpGETRequest];
    [request setDelegate:self];
    [request setDidFinishSelector:@selector(requestAllSites:)];
    [request setDidFailSelector:@selector(serviceDocumentRequestFailed:)];
    [request startAsynchronous];
        
    [self dismissModalViewControllerAnimated:YES];
    
}

- (void) detailViewControllerChanged:(NSNotification *) notification {
    id sender = [notification object];
    
    if(sender && ![sender isEqual:self]) {
        [selectedIndex release];
        selectedIndex = nil;
        
        [self.tableView selectRowAtIndexPath:nil animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
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

#pragma mark -
#pragma Global notifications
- (void) applicationWillResignActive:(NSNotification *) notification {
    NSLog(@"applicationWillResignActive in RootViewController");
    
    [self cancelAllHTTPConnections];
}

-(void) repositoryShouldReload:(NSNotification *)notification {
    //we want to err on the side of safety and restart the navigation in case the
    //user changed the repository
    // userDefaults are synchronized by the AppDelegate in the applicationWillEnterForeground method
    [self.navigationController popToRootViewControllerAnimated:YES];
    
    //ViewDidLoad reloads the respository. We don't want to make the request twice
    if([self isViewLoaded]) {
        //Default selection is "All sites"
        [self.segmentedControl setSelectedSegmentIndex:kDefaultSelectedSegment];
        [self requestAllSites:nil];
    }
}
@end
