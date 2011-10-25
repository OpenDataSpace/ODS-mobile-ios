//
//  ***** BEGIN LICENSE BLOCK *****
//  Version: MPL 1.1
//
//  The contents of this file are subject to the Mozilla Public License Version
//  1.1 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS" basis,
//  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
//  for the specific language governing rights and limitations under the
//  License.
//
//  The Original Code is the Alfresco Mobile App.
//  The Initial Developer of the Original Code is Zia Consulting, Inc.
//  Portions created by the Initial Developer are Copyright (C) 2011
//  the Initial Developer. All Rights Reserved.
//
//
//  ***** END LICENSE BLOCK *****
//
//
//  SearchViewController.m
//

#import "SearchViewController.h"
#import "DocumentViewController.h"
#import "RepositoryItemTableViewCell.h"
#import "Utility.h"
#import "SearchResult.h"
#import "CMISSearchDownload.h"
#import "CMISQueryDownload.h"
#import "RepositoryServices.h"
#import "UIColor+Theme.h"
#import "Theme.h"
#import "NSString+Trimming.h"
#import "SavedDocument.h"
#import "Utility.h"
#import "SavedDocument.h"
#import "RepositoryServices.h"

@implementation SearchViewController

@synthesize search;
@synthesize table;
@synthesize results;
@synthesize searchDownload;
@synthesize progressBar;

#pragma mark Memory Management
- (void)dealloc {
	[search release];
	[table release];
	[results release];
	[searchDownload release];
	[progressBar release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	[super viewDidUnload];
}

#pragma mark View Life Cycle
- (void)viewWillDisappear:(BOOL)animated {
	self.navigationController.navigationBarHidden = NO;
	[super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
	self.navigationController.navigationBarHidden = YES;
	[super viewWillAppear:animated];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
    [self setTitle:NSLocalizedString(@"searchViewTitle", @"Search Results")];
	
	[Theme setThemeForUIViewController:self];
	[search setTintColor:[UIColor ziaThemeRedColor]];
	[table setBackgroundColor:[UIColor clearColor]];
    
    if (! results) {
        [self setResults:[NSMutableArray array]];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
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
		SearchResult *emptyResult = [[SearchResult alloc] init];
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
        SearchResult *errorResult = [[SearchResult alloc] init];
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
    [doc setFileName:down.filename];
    [doc setContentMimeType:down.cmisContentStreamMimeType];
    [doc setHidesBottomBarWhenPushed:YES];
	
	[self.navigationController pushViewController:doc animated:YES];
	[doc release];
}

#pragma mark -
#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	RepositoryItemTableViewCell *cell = (RepositoryItemTableViewCell *) [tableView dequeueReusableCellWithIdentifier:RepositoryItemCellIdentifier];
    if (cell == nil) {
		NSArray *nibItems = [[NSBundle mainBundle] loadNibNamed:@"RepositoryItemTableViewCell" owner:self options:nil];
		cell = [nibItems objectAtIndex:0];
		NSAssert(nibItems, @"Failed to load object from NIB");
    }
    
	SearchResult *result = [self.results objectAtIndex:[indexPath row]];
	if (([result contentLocation] == nil) && ([results count] == 1)) 
    {
		cell.filename.text = result.title;
    
        if ([result.title isEqualToString:@"Too many search results"]) {
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
            
            cell.details.text = [[NSString alloc] initWithFormat:@"%@ | %@", 
                                 [result contentAuthor], formatDateTime(result.updated)];
        } else {
            cell.details.text = [[NSString alloc] initWithFormat:@"%@ | %@", 
                                 formatDateTime(result.lastModifiedDateStr), 
                                 [SavedDocument stringForLongFileSize:[result.contentStreamLength longLongValue]]]; // TODO: Externalize to a configurable property?
        }
        
		cell.image.image = imageForFilename(result.title);
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	
	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.results count];
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	SearchResult *result = [self.results objectAtIndex:[indexPath row]];
	if (([result contentLocation] == nil) && ([results count] == 1)) {
//        [tableView deselectRowAtIndexPath:indexPath animated:YES];
		return;
	}
    
	NSString* urlStr = result.contentLocation;
	self.progressBar = [DownloadProgressBar createAndStartWithURL:[NSURL URLWithString:urlStr] 
                                                         delegate:self 
                                                          message:NSLocalizedString(@"Downloading Document", @"Downloading Document") 
                                                         filename:result.title];
    [[self progressBar] setCmisObjectId:[result cmisObjectId]];
    [[self progressBar] setCmisContentStreamMimeType:[result contentStreamMimeType]];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if ([results count] == 30) { // TODO EXTERNALIZE THIS OR MAKE IT CONFIGURABLE
        return NSLocalizedString(@"Displaying the first 30 results", @"Displaying the first 30 results (search view footer)");
    }
    return nil;
}

#pragma mark -
#pragma mark UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	RepositoryInfo *repoInfo = [[RepositoryServices shared] currentRepositoryInfo];
	if (![repoInfo cmisQueryHref]) {
		
		UIAlertView *warningView = [[[UIAlertView alloc]initWithTitle:NSLocalizedString(@"searchUnavailableDialogTitle", @"Search Not Available") 
															  message:NSLocalizedString(@"searchUnavailableDialogMessage", @"Search is not available for this repository")  
															 delegate:nil 
													cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK  button text")
													otherButtonTitles:nil] autorelease];
		[warningView show];
		
		return;
	}
	
	
	NSString *searchPattern = [[searchBar text] trimWhiteSpace];
	AsynchonousDownload *down;
	if ([repoInfo isPreReleaseCmis])
		down = [[SearchResultsDownload alloc] initWithSearchPattern:searchPattern delegate:self];
	else
		down = [[CMISSearchDownload alloc] initWithSearchPattern:searchPattern delegate:self];
    down.show500StatusError = NO;
    
	[self setSearchDownload:down];
	[down start];
	[down release];
	[search resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	[searchBar resignFirstResponder];
}

@end
