//
//  RootViewController.m
//  Alfresco
//
//  Created by Michael Muller on 9/1/09.
//  Copyright Zia Consulting 2009. All rights reserved.
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
#import "LinkRelationService.h"
#import "NSURL+HTTPURLUtils.h"
#import "SavedDocument.h"


// ** Class Constants
static CGFloat const kSectionHeaderHeightPadding = 6.0;


@implementation RootViewController
@synthesize siteInfo;
@synthesize companyHomeItems;
@synthesize cmisSitesQuery;
@synthesize itemDownloader;
@synthesize companyHomeDownloader;
@synthesize progressBar;
@synthesize typeDownloader;
@synthesize currentRepositoryInfo;
@synthesize HUD;
@synthesize serviceDocumentRequest;

#pragma mark Memory Management

- (void)dealloc {
	[siteInfo release];
	[companyHomeItems release];
	[cmisSitesQuery release];
	[itemDownloader release];
	[companyHomeDownloader release];
	[progressBar release];
	[typeDownloader release];
	[currentRepositoryInfo release];
	[HUD release];
    [serviceDocumentRequest release];
	
    [super dealloc];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	
	[self cancelAllHTTPConnections];
	
	if (self.HUD)
		[HUD hide:YES];
	[self setHUD:nil];
}

#pragma View Lifecycle

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[Theme setThemeForUITableViewController:self];
}

- (void)viewDidLoad {
	[super viewDidLoad];
    
    [self.navigationItem setTitle:NSLocalizedString(@"root.view.title", @"root view title")];
	
    BOOL isFirstLaunch = NO;
    
    if ( !isFirstLaunch && ([[RepositoryServices shared] currentRepositoryInfo] == nil)) {
        ServiceDocumentRequest *request = [ServiceDocumentRequest httpGETRequest]; 
        [request setDelegate:self];
        [request setDidFinishSelector:@selector(serviceDocumentRequestFinished:)];
        [request setDidFailSelector:@selector(serviceDocumentRequestFailed:)];
        [self setServiceDocumentRequest:request];
        [request startAsynchronous];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

#pragma mark -
#pragma mark UITableViewDataSource methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if ([[RepositoryServices shared] isCurrentRepositoryVendorNameEqualTo:kAlfrescoRepositoryVendorName])
		return ((section == 1) 
                ? NSLocalizedString(@"rootSectionHeaderCompanyHome", @"Company Home") 
                : NSLocalizedString(@"rootSectionHeaderSites", @"Sites"));
	else 
		return nil;
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
		return (section == 1) ? (companyHomeItems?[companyHomeItems count]:0) : (siteInfo?[siteInfo count]:0);
	else
		return [companyHomeItems count];
}

static NSString *kCellIdentifier = @"Cell";
static NSString *kFolder_Icon = @"folder.png";
static NSString *kSite_Icon = @"site.png";
static NSString *kRepositoryItemTableViewCell_NibName = @"RepositoryItemTableViewCell";

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if ([[RepositoryServices shared] isCurrentRepositoryVendorNameEqualTo:kAlfrescoRepositoryVendorName] && ([indexPath section] == 0))
	{
		// We are in the sites section
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier] autorelease];
		}
		
        NSString *folderImageName = kFolder_Icon;
        folderImageName = ( ([indexPath section] == 0) ? kSite_Icon : kFolder_Icon);
        
		NSArray *collection = ([indexPath section] == 1) ? self.companyHomeItems : self.siteInfo;
		cell.textLabel.text = [[collection objectAtIndex:[indexPath row]] title];
        cell.imageView.image = [UIImage imageNamed:folderImageName];
		
		[cell setAccessoryType:UITableViewCellAccessoryNone];
		return cell;
	}
	else {
		
		// We are looking at a child item in the Root Collection
		
		RepositoryItemTableViewCell *cell = (RepositoryItemTableViewCell *) [tableView dequeueReusableCellWithIdentifier:RepositoryItemCellIdentifier];
		if (cell == nil) {
			NSArray *nibItems = [[NSBundle mainBundle] loadNibNamed:kRepositoryItemTableViewCell_NibName owner:self options:nil];
			cell = [nibItems objectAtIndex:0];
			NSAssert(nibItems, @"Failed to load object from NIB");
		}
		
		RepositoryItem *child = [self.companyHomeItems objectAtIndex:[indexPath row]];

        // work around for those cmis producers that aren't compliant and do not
        // include all required attributes, for this case, cmis:name.  Will use the atom title instead
        NSString *fileName = [child.metadata valueForKey:@"cmis:name"];
        if (!fileName || ([fileName length] == 0)) {
            fileName = child.title;
        }
        [cell.filename setText:fileName];
        
        
        
		if ([child isFolder]) {
            UIImage * img = [UIImage imageNamed:kFolder_Icon];
			cell.imageView.image  = img;
            cell.details.text = [[NSString alloc] initWithFormat:@"%@", formatDateTime(child.lastModifiedDate)]; // TODO: Externalize to a configurable property?
        }
        else {
            NSString *contentStreamLengthStr = [child.metadata objectForKey:@"cmis:contentStreamLength"];
            if (contentStreamLengthStr == nil || [contentStreamLengthStr length] == 0) {
                contentStreamLengthStr = [child contentStreamLengthString];
            }
            cell.details.text = [[NSString alloc] initWithFormat:@"%@ | %@", formatDateTime(child.lastModifiedDate), [SavedDocument stringForLongFileSize:[contentStreamLengthStr longLongValue]]]; // TODO: Externalize to a configurable property?
            
            cell.imageView.image = imageForFilename(child.title);
        }
        
        
		[cell setAccessoryType:(([[[RepositoryServices shared] currentRepositoryInfo] isPreReleaseCmis])
								? UITableViewCellAccessoryNone
								: UITableViewCellAccessoryDetailDisclosureButton)];
        
		return cell;
		
	}
}

#pragma mark -
#pragma mark UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
	if ((nil == sectionTitle) && ([[self tableView] numberOfSections] == 1))
		return nil;

	CGSize sectionTitleSize = [sectionTitle sizeWithFont:[UIFont boldSystemFontOfSize:20.0f]];
	CGFloat headerHeight = sectionTitleSize.height + kSectionHeaderHeightPadding;
	
	// TODO: Move this block of code into the theme class
	WhiteGlossGradientView *headerView = [[[WhiteGlossGradientView alloc] 
										   initWithFrame:CGRectMake(0.0, 0.0, [tableView bounds].size.width, headerHeight)] autorelease];
#if defined (TARGET_ALFRESCO)
    [headerView setBackgroundColor:[UIColor colorWIthHexRed:127.0f green:127.0f blue:130.0f alphaTransparency:1.0f]];
#else
    [headerView setBackgroundColor:[UIColor blackColor]];
#endif

	
	UILabel *sectionTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 0.0, tableView.bounds.size.width, headerHeight)];
	[sectionTitleLabel setFont:[UIFont boldSystemFontOfSize:20.0f]];
	[sectionTitleLabel setText:sectionTitle];
    [sectionTitleLabel setTextColor:[UIColor whiteColor]];
    [sectionTitleLabel setBackgroundColor:[UIColor clearColor]]; // FIXME: Not optimal!!!
	[headerView addSubview:sectionTitleLabel];
	return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	NSString *sectionTitle = [self tableView:tableView titleForHeaderInSection:section];
	if ((nil == sectionTitle) && ([[self tableView] numberOfSections] == 1))
		return 0.0f;
	
	CGSize sectionTitleSize = [sectionTitle sizeWithFont:[UIFont boldSystemFontOfSize:20.0f]];
	CGFloat headerHeight = sectionTitleSize.height + kSectionHeaderHeightPadding;
	return headerHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[self cancelAllHTTPConnections];
	
	if ([[RepositoryServices shared] isCurrentRepositoryVendorNameEqualTo:kAlfrescoRepositoryVendorName] && ([indexPath section] == 0))
	{
		// Alfresco Sites, special case
		// get the site information associated with this row
		RepositoryItem *site = [self.siteInfo objectAtIndex:[indexPath row]];
		
		// start loading the list of top-level items for this site
		FolderItemsDownload *down = [[FolderItemsDownload alloc] initWithNode:[site node] delegate:self];		
        [down setItem:site];
		down.context = @"topLevel";
		down.parentTitle = site.title;
		self.itemDownloader = down;
		[down start];
		[down release];
		
	}
	else { // Root Collection Child
		
		// get the document/folder information associated with this row
		RepositoryItem *item = [self.companyHomeItems objectAtIndex:[indexPath row]];
		
		if ([item isFolder]) {
			NSDictionary *optionalArguments = [[LinkRelationService shared] defaultOptionalArgumentsForFolderChildrenCollection];											   
			NSURL *getChildrenURL = [[LinkRelationService shared] getChildrenURLForCMISFolder:item withOptionalArguments:optionalArguments];
			FolderItemsDownload *down = [[FolderItemsDownload alloc] initWithURL:getChildrenURL delegate:self];
			
			down.item = item;
			down.context = @"companyHomeItems";
			down.parentTitle = item.title;
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
        //
        // Currently do nothing
        //
	}
	else {
		// Root Collection Child Item Case
		
		CMISTypeDefinitionDownload *down = [[CMISTypeDefinitionDownload alloc] initWithURL:[NSURL URLWithString:item.describedByURL] delegate:self];
		down.repositoryItem = item;
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
    [doc setFileName:[down filename]];
    [doc setHidesBottomBarWhenPushed:YES];
	
	[self.navigationController pushViewController:doc animated:YES];
	[doc release];
}

#pragma mark -
#pragma mark AsynchronousDownloadDelegate

- (void) asyncDownloadDidComplete:(AsynchonousDownload *)async {
	
	// if we're being notified that a list of sites is ready
	if ([[RepositoryServices shared] isCurrentRepositoryVendorNameEqualTo:kAlfrescoRepositoryVendorName]) {
		NSArray *array = nil;
		if ([async isKindOfClass:[CMISGetSites class]])
			array = [(CMISGetSites *)[self cmisSitesQuery] results];
		else if ([async isKindOfClass:[SiteListDownload class]])
			array = [(SiteListDownload *)[self cmisSitesQuery] results];
		
		if (array && ([array count] >= 1)) {
			[self setSiteInfo:array];
			[[self tableView] reloadData];
		}
	}
	
	// if we're being told that a list of folder items is ready
	if ([async isKindOfClass:[FolderItemsDownload class]]) {
		
		FolderItemsDownload *fid = (FolderItemsDownload *) async;
		
		// if we got back a list of top-level items, find the document library item
		if ([fid.context isEqualToString:@"topLevel"]) {
			
			BOOL docLibAvailable = NO;
			for (RepositoryItem *item in self.itemDownloader.children) {
				
				if ([item.title isEqualToString:@"documentLibrary"]) {
					
					// this item is the doc library; find its children
					
					docLibAvailable = YES;
					NSDictionary *optionalArguments = [[LinkRelationService shared] defaultOptionalArgumentsForFolderChildrenCollection];											   
					NSURL *getChildrenURL = [[LinkRelationService shared] getChildrenURLForCMISFolder:item withOptionalArguments:optionalArguments];
					FolderItemsDownload *down = [[FolderItemsDownload alloc] initWithURL:getChildrenURL delegate:self];

					[down setItem:item];
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
		
		// did we get back the items in "company home"?
		else if ([fid.context isEqualToString:@"companyHome"]) {
			self.companyHomeItems = self.companyHomeDownloader.children;
			[(UITableView *) self.view reloadData];
		}
		
		// if it's not a list of top-level items, it's the items in the doc library
		else {
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
        MetaDataTableViewController *viewController = [[MetaDataTableViewController alloc] initWithStyle:UITableViewStylePlain];
        [viewController setCmisObjectId:tdd.repositoryItem.guid];
        [viewController setMetadata:tdd.repositoryItem.metadata];
        [viewController setPropertyInfo:tdd.properties];
        [self.navigationController pushViewController:viewController animated:YES];
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

-(void)metaDataChanged
{
	// FIXME: Optimize this step.  Currently it redownloads the entire collection, but we should instead just download and update the object that was updated.
	
	RepositoryInfo *RepositoryInfo = [[RepositoryServices shared] currentRepositoryInfo];
	NSString *folder = [RepositoryInfo rootFolderHref];
	NSLog(@"root folder: %@", folder);
	if (!folder) { // FIXME: handle me gracefully here
		return;
	}
	// make sure we get security back
	NSDictionary *defaultParamsDictionary = [[LinkRelationService shared] defaultOptionalArgumentsForFolderChildrenCollection]; 
	NSURL *folderChildrenCollectionURL = [[NSURL URLWithString:folder] URLByAppendingParameterDictionary:defaultParamsDictionary];
	
	// refresh the root collection.
	FolderItemsDownload *down = [[FolderItemsDownload alloc] initWithURL:folderChildrenCollectionURL delegate:self];
	[down setContext:@"companyHome"];
	[down setParentTitle:NSLocalizedString(@"Top", @"Name of 'Top' or Root Repository Folder")];
	[self setCompanyHomeDownloader:down];
	
	[down start];
	[down release];
}

- (void)cancelAllHTTPConnections
{
	if (HUD) {
		[self.HUD hide:YES];
	}
	
	[self.cmisSitesQuery cancel];
	[self.itemDownloader cancel];
	[self.companyHomeDownloader cancel];
	[self.typeDownloader cancel];
    [[self serviceDocumentRequest] clearDelegatesAndCancel];
}

#pragma mark -
#pragma mark HTTP Request Handling

- (void)serviceDocumentRequestFinished:(ServiceDocumentRequest *)sender
{
	RepositoryInfo *currentRepository = [[RepositoryServices shared] currentRepositoryInfo];
	
	// Create Sites and load if connected to an Alfresco Repository
	if (currentRepository && ([[RepositoryServices shared] isCurrentRepositoryVendorNameEqualTo:kAlfrescoRepositoryVendorName])) {
		// start loading the list of sites
        AsynchonousDownload *query = [[[SiteListDownload alloc] initWithDelegate:self] autorelease];
		
		[self setCmisSitesQuery:query];
		[query start];
	}
	
	// Show Root Collection, hide if user only wants to see Alfresco Sites
	if (!([[RepositoryServices shared] isCurrentRepositoryVendorNameEqualTo:kAlfrescoRepositoryVendorName]) || (YES == userPrefShowCompanyHome()))
	{
		NSString *folder = [currentRepository rootFolderHref];
		if (!folder) { // FIXME: handle me gracefully here
			return;
		}
		
		NSDictionary *defaultParamsDictionary = [[LinkRelationService shared] defaultOptionalArgumentsForFolderChildrenCollection]; 
		NSURL *folderChildrenCollectionURL = [[NSURL URLWithString:folder] URLByAppendingParameterDictionary:defaultParamsDictionary];
		
		// find the items in the "Company Home" folder
		FolderItemsDownload *down = [[FolderItemsDownload alloc] initWithURL:folderChildrenCollectionURL delegate:self];
		self.companyHomeDownloader = down;
        [down setContext:@"companyHome"];
        [down setParentTitle:NSLocalizedString(@"Top", @"Name of 'Top' or Root Repository Folder")];
		[down start];
		[down release];
	}
	
    [sender cancel];
	[self.HUD hide:YES];
	[self.tableView reloadData];
}

- (void)serviceDocumentRequestFailed:(ServiceDocumentRequest *)sender
{
	NSLog(@"ServiceDocument Request Failure \n\tErrorDescription: %@ \n\tErrorFailureReason:%@ \n\tErrorObject:%@", 
          [[sender error] description], [[sender error] localizedFailureReason],[sender error]);

	[self.HUD hide:YES];
    
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

@end
