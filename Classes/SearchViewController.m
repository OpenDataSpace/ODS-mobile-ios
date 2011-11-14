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
//  SearchViewController.m
//

#import "SearchViewController.h"
#import "DocumentViewController.h"
#import "RepositoryItemTableViewCell.h"
#import "Utility.h"
#import "CMISSearchDownload.h"
#import "CMISQueryDownload.h"
#import "RepositoryServices.h"
#import "UIColor+Theme.h"
#import "Theme.h"
#import "NSString+Trimming.h"
#import "SavedDocument.h"
#import "ThemeProperties.h"
#import "IpadSupport.h"
#import "ServiceDocumentRequest.h"
#import "MBProgressHUD.h"
#import "Constants.h"
#import "Utility.h"
#import "SavedDocument.h"
#import "RepositoryServices.h"
#import "RepositoryItem.h"
#import "WhiteGlossGradientView.h"
#import "TableViewHeaderView.h"

@interface SearchViewController (PrivateMethods)
- (void) startHUD;
- (void) stopHUD;
- (void) searchNotAvailableAlert;
@end

@implementation SearchViewController
static CGFloat const kSectionHeaderHeightPadding = 6.0;

@synthesize search;
@synthesize table;
@synthesize results;
@synthesize searchDownload;
@synthesize progressBar;
@synthesize serviceDocumentRequest;
@synthesize HUD;
@synthesize selectedSite;

#pragma mark Memory Management
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
	[search release];
	[table release];
	[results release];
	[searchDownload release];
	[progressBar release];
    [selectedIndex release];
    [willSelectIndex release];
    [serviceDocumentRequest release];
    [HUD release];
    [selectedSite release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    // the DownloadProgressBar listen to a ResignActiveNotification and
    // dismisses the modal automatically
    self.progressBar = nil;
    
    [self.searchDownload cancel];
    self.searchDownload = nil;
}

- (void)viewDidUnload {
	[super viewDidUnload];
    
    self.search = nil;
    self.table = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationRepositoryShouldReload object:nil];
}

#pragma mark View Life Cycle
- (void)viewWillDisappear:(BOOL)animated {
	self.navigationController.navigationBarHidden = NO;
	[super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
	self.navigationController.navigationBarHidden = YES;
	[super viewWillAppear:animated];
    [Theme setThemeForUIViewController:self];
    
    if(IS_IPAD) {
        [table selectRowAtIndexPath:selectedIndex animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    
    [willSelectIndex release];
    willSelectIndex = nil;
    
    if ([[RepositoryServices shared] currentRepositoryInfo] == nil) {
        [self startHUD];
        
        ServiceDocumentRequest *request = [ServiceDocumentRequest httpGETRequest]; 
        [request setDelegate:self];
        [request setDidFinishSelector:@selector(serviceDocumentRequestFinished:)];
        [request setDidFailSelector:@selector(serviceDocumentRequestFailed:)];
        [self setServiceDocumentRequest:request];
        [request startAsynchronous];
    }
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
    [self setTitle:NSLocalizedString(@"searchViewTitle", @"Search Results")];
	
	[Theme setThemeForUIViewController:self];
	[search setTintColor:[ThemeProperties toolbarColor]];
	[table setBackgroundColor:[UIColor clearColor]];
    
    if (! results) {
        [self setResults:[NSMutableArray array]];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(repositoryShouldReload:) name:kNotificationRepositoryShouldReload object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

#pragma mark -
#pragma mark HTTP Request Handling

- (void)serviceDocumentRequestFinished:(ServiceDocumentRequest *)sender
{
	RepositoryInfo *currentRepository = [[RepositoryServices shared] currentRepositoryInfo];
	
	if (!currentRepository) {
		NSLog(@"Search is not available but the user is notified when a search is triggered");
	}
	
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
#pragma mark AsynchronousDownloadDelegate

- (void)asyncDownloadDidComplete:(AsynchonousDownload *)async {
    [results removeAllObjects];
    
	if ([async isKindOfClass:[SearchResultsDownload class]]) {
        [results addObjectsFromArray:[(SearchResultsDownload *)async results]];
	}
	else {
        [results addObjectsFromArray:[(CMISQueryDownload *)async results]];
	}
	
	if ([results count] == 0) {
		RepositoryItem *emptyResult = [[RepositoryItem alloc] init];
		[emptyResult setTitle:NSLocalizedString(@"noSearchResultsMessage", @"No Results Found")];
		[emptyResult setContentLocation:nil];
		[results addObject:emptyResult];
        [emptyResult release];
	}

	[table reloadData];
}

- (void)asyncDownload:(AsynchonousDownload *)async didFailWithError:(NSError *)error 
{
    NSLog(@"Failure: %@", error);	
    
    [results removeAllObjects];
    if (error && [[error domain] isEqualToString:NSHTTPPropertyStatusCodeKey] && ([error code] == 500))
    {
        RepositoryItem *errorResult = [[RepositoryItem alloc] init];
		[errorResult setTitle:NSLocalizedString(@"Too many search results", @"Server Error")];
		[errorResult setContentLocation:nil];
		[results addObject:errorResult];
        [errorResult release];
    }
    [table reloadData];
}

#pragma mark -
#pragma mark UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
}

#pragma mark -
#pragma mark DownloadProgressBarDelegate
- (void)download:(DownloadProgressBar *)down completeWithData:(NSData *)data {
	
	NSString *nibName = @"DocumentViewController";
	DocumentViewController *doc = [[DocumentViewController alloc] initWithNibName:nibName bundle:[NSBundle mainBundle]];
	[doc setCmisObjectId:down.cmisObjectId];
    [doc setFileData:data];
    
    DownloadMetadata *fileMetadata = down.downloadMetadata;
    NSString *filename;
    
    if(fileMetadata.key) {
        filename = fileMetadata.key;
    } else {
        filename = down.filename;
    }
    
    [doc setFileName:filename];
    [doc setFileMetadata:fileMetadata];
    [doc setContentMimeType:down.cmisContentStreamMimeType];
    [doc setHidesBottomBarWhenPushed:YES];
	
    [IpadSupport pushDetailController:doc withNavigation:self.navigationController andSender:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(detailViewControllerChanged:) name:@"detailViewControllerChanged" object:nil];
	[doc release];
    
    [table deselectRowAtIndexPath:willSelectIndex animated:YES];
    [selectedIndex release];
    selectedIndex = willSelectIndex;
    willSelectIndex = nil;
}

- (void) downloadWasCancelled:(DownloadProgressBar *)down {
	[table deselectRowAtIndexPath:willSelectIndex animated:YES];
    
    // We don't want to reselect the previous row in iPhone
    if(IS_IPAD) {
        [table selectRowAtIndexPath:selectedIndex animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
}

#pragma mark -
#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	
    
    if(indexPath.section == 0) {
        UITableViewCell *cell = (UITableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"SelectSiteCellIdentifier"];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SelectSiteCellIdentifier"] autorelease];
            cell.backgroundColor = [UIColor whiteColor];
        }
        
        NSString *siteName = nil;
        if(selectedSite == nil) {
            siteName = NSLocalizedString(@"search.allSites", @"All Sites");
        } else {
            siteName = [selectedSite title];
        }
        
        [cell.textLabel setText:siteName];
        [cell.imageView setImage:nil];
        [cell.detailTextLabel setText:nil];
        [cell setAccessoryType: UITableViewCellAccessoryDisclosureIndicator];
        [cell setSelected:UITableViewCellSelectionStyleBlue];
        return cell;
    }
    
    RepositoryItemTableViewCell *cell = (RepositoryItemTableViewCell *) [tableView dequeueReusableCellWithIdentifier:RepositoryItemCellIdentifier];
    if (cell == nil) {
		NSArray *nibItems = [[NSBundle mainBundle] loadNibNamed:@"RepositoryItemTableViewCell" owner:self options:nil];
		cell = [nibItems objectAtIndex:0];
		NSAssert(nibItems, @"Failed to load object from NIB");
    }
	RepositoryItem *result = [self.results objectAtIndex:[indexPath row]];
	if (([result contentLocation] == nil) && ([results count] == 1)) 
    {
		cell.filename.text = result.title;
        
    
        if ([result.title isEqualToString:NSLocalizedString(@"search.too.many.results", @"Too many search results")]) {
            [[cell details] setText:NSLocalizedString(@"refineSearchTermsMessage", @"refineSearchTermsMessage")];
        } else {
            cell.details.text = NSLocalizedString(@"tryDifferentSearchMessage", @"Please try a different search");
        }
        
		cell.image.image = nil;
		cell.accessoryType = UITableViewCellAccessoryNone;
		[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	}
	else {
		cell.filename.text = result.title;
        BOOL isPrereleaseCmis = [[[RepositoryServices shared] currentRepositoryInfo] isPreReleaseCmis];
        BOOL isAlfresco = [[RepositoryServices shared] isCurrentRepositoryVendorNameEqualTo:kAlfrescoRepositoryVendorName];
        
        if (isAlfresco && isPrereleaseCmis) {
            
            cell.details.text = [[[NSString alloc] initWithFormat:@"%@ | %@", 
                                 [result lastModifiedBy], formatDateTime(result.lastModifiedDate)] autorelease];
            
            //            cell.details.text = [[NSString alloc] initWithFormat:@"%@: %@",
            //                             NSLocalizedString(@"Relevance", @""),
            //                             ((([result.relevance length] == 0) 
            //                               ? NSLocalizedString(@"N/A", @"N/A") 
            //                               : result.relevance))];
        } else {
            cell.details.text = [[[NSString alloc] initWithFormat:@"%@ | %@", 
                                 formatDateTime(result.lastModifiedDate), 
                                 [SavedDocument stringForLongFileSize:[result.contentStreamLength longLongValue]]] autorelease]; // TODO: Externalize to a configurable property?
        }
        
        //        cell.imageView.image = imageForFilename(result.title);
        //        
		cell.image.image = imageForFilename(result.title);
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	
	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0) {
        return 1;
    } 
	return [self.results count];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        SelectSiteViewController *selectSiteController = [SelectSiteViewController selectSiteViewController];
        [selectSiteController setDelegate:self];
        [self.navigationController pushViewController:selectSiteController animated:YES];
        [table deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
	RepositoryItem *result = [self.results objectAtIndex:[indexPath row]];
	if (([result contentLocation] == nil) && ([results count] == 1)) {
		return;
	}
    
	NSString* urlStr = result.contentLocation;
	self.progressBar = [DownloadProgressBar createAndStartWithURL:[NSURL URLWithString:urlStr] 
                                                         delegate:self 
                                                          message:NSLocalizedString(@"Downloading Document", @"Downloading Document") 
                                                         filename:result.title];
    [[self progressBar] setCmisObjectId:[result guid]];
    [[self progressBar] setCmisContentStreamMimeType:[result contentStreamMimeType]];
    [[self progressBar] setRepositoryItem:result];
    
    [willSelectIndex release];
    willSelectIndex = [indexPath retain];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    // TODO: we should check the number of sections in the table view before assuming that there will be a Site Selection
    if (section == 1)
    {
        if ([results count] == 30) { // TODO EXTERNALIZE THIS OR MAKE IT CONFIGURABLE
            return NSLocalizedString(@"searchview.footer.displaying-30-results", 
                                     @"Displaying the first 30 results");
        }
    }
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    NSString *sectionTitle = [self tableView:tableView titleForFooterInSection:section];
	if ((nil == sectionTitle))
		return nil;
    
    //The height gets adjusted if it is less than the needed height
    TableViewHeaderView *headerView = [[[TableViewHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, [tableView bounds].size.width, 10) label:sectionTitle] autorelease];
    [headerView setBackgroundColor:[ThemeProperties browseFooterColor]];
    [headerView.textLabel setTextColor:[ThemeProperties browseFooterTextColor]];
    
	return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	NSString *sectionTitle = [self tableView:tableView titleForFooterInSection:section];
	if ((nil == sectionTitle))
		return 0.0f;
	
	TableViewHeaderView *headerView = [[[TableViewHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, [tableView bounds].size.width, 10) label:sectionTitle] autorelease];
	return headerView.frame.size.height;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0) {
        return NSLocalizedString(@"search.sectionHeader.site", 
                                 @"Search in site");
    } else if(section == 1) {
        return NSLocalizedString(@"search.sectionHeader.results", 
                                 @"Search Results");
    }
    return nil;
}

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

#pragma mark -
#pragma mark SelectSite Delegate
-(void)selectSite:(SelectSiteViewController *)selectSite finishedWithSite:(RepositoryItem *)site {
    if([selectSite allSitesSelected]) {
        self.selectedSite = nil;
    } else {
        self.selectedSite = site;
    }
    
    [self.table reloadData];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	RepositoryInfo *repoInfo = [[RepositoryServices shared] currentRepositoryInfo];
	if (![repoInfo cmisQueryHref]) {
		[self searchNotAvailableAlert];
		
		return;
	}
	
	
	NSString *searchPattern = [[searchBar text] trimWhiteSpace];
    
	AsynchonousDownload *down;
	if ([repoInfo isPreReleaseCmis])
		down = [[SearchResultsDownload alloc] initWithSearchPattern:searchPattern delegate:self];
	else
//		down = [[CMISSearchDownload alloc] initWithSearchPattern:searchPattern delegate:self];
        down = [[CMISSearchDownload alloc] initWIthSearchPattern:searchPattern siteObjectId:[[self selectedSite] guid] delegate:self];

	[self setSearchDownload:down];
    [down setShow500StatusError:NO];
	[down start];
	[down release];
	[search resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	[searchBar resignFirstResponder];
}

- (void) detailViewControllerChanged:(NSNotification *) notification {
    id sender = [notification object];
    
    if(sender && ![sender isEqual:self]) {
        [selectedIndex release];
        selectedIndex = nil;
        
        [table selectRowAtIndexPath:nil animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
}

#pragma mark -
#pragma mark MBProgressHUD Helper Methods
- (void)startHUD
{
	if (HUD) {
		return;
	}
    
    [self setHUD:[MBProgressHUD showHUDAddedTo:self.table animated:YES]];
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

- (void) searchNotAvailableAlert {
    UIAlertView *warningView = [[[UIAlertView alloc]initWithTitle:NSLocalizedString(@"searchUnavailableDialogTitle", @"Search Not Available") 
                                                          message:NSLocalizedString(@"searchUnavailableDialogMessage", @"Search is not available for this repository")  
                                                         delegate:nil 
                                                cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK  button text")
                                                otherButtonTitles:nil] autorelease];
    [warningView show];
}

#pragma mark - NotificationCenter methods

- (void) applicationWillResignActive:(NSNotification *) notification {
    NSLog(@"applicationWillResignActive in SearchViewController");
    [searchDownload cancel];
    [serviceDocumentRequest clearDelegatesAndCancel];
}

-(void) repositoryShouldReload:(NSNotification *)notification {
    [self.navigationController popToRootViewControllerAnimated:YES];
    [self setResults:[NSMutableArray array]];
    [self setSelectedSite:nil];
    [self.table reloadData];
}

@end
