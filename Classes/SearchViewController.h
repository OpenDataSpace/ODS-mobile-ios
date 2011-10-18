//
//  SearchViewController.h
//  Alfresco
//
//  Created by Michael Muller on 10/5/09.
//  Copyright 2009 Zia Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DownloadProgressBar.h"
#import "SearchResultsDownload.h"


@interface SearchViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, 
													UISearchBarDelegate, DownloadProgressBarDelegate, AsynchronousDownloadDelegate> {
@private
	IBOutlet UISearchBar *search;
	IBOutlet UITableView *table;
	NSMutableArray *results;
	DownloadProgressBar *progressBar;
	AsynchonousDownload *searchDownload;
}	

@property (nonatomic, retain) UISearchBar *search;
@property (nonatomic, retain) UITableView *table;
@property (nonatomic, retain) NSMutableArray *results;
@property (nonatomic, retain) DownloadProgressBar *progressBar;
@property (nonatomic, retain) AsynchonousDownload *searchDownload;

//- (void) asyncDownloadDidComplete:(AsynchonousDownload *)async;
//- (void) asyncDownload:(AsynchonousDownload *)async didFailWithError:(NSError *)error;
//- (IBAction)searchBarSearchButtonClicked:(UISearchBar *)searchBar;
///- (IBAction)searchBarCancelButtonClicked:(UISearchBar *)searchBar;

@end
