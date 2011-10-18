//
//  FavoritesViewController.m
//  Alfresco
//
//  Created by Michael Muller on 10/7/09.
//  Copyright 2009 Zia Consulting. All rights reserved.
//

#import "FavoritesViewController.h"
#import "SavedDocument.h"
#import "DocumentViewController.h"
#import "Utility.h"
#import "UIColor+Theme.h"
#import "Theme.h"
#import "DirectoryWatcher.h"
#import "FolderTableViewDataSource.h"

@interface FavoritesViewController (Private)
- (NSString *)applicationDocumentsDirectory;
@end


@implementation FavoritesViewController
@synthesize dirWatcher;

#pragma mark Memory Management
- (void)dealloc {
	[dirWatcher release];
	
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	[self setDirWatcher:nil];
}

#pragma mark View Life Cycle
/*
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}
*/
- (void)viewDidLoad {
    [super viewDidLoad];
	[self setTitle:NSLocalizedString(@"Favorites", @"Favorites View Title")];
	
	NSURL *applicationDocumentsDirectoryURL = [NSURL fileURLWithPath:[self applicationDocumentsDirectory] isDirectory:YES];
	FolderTableViewDataSource *dataSource = [[FolderTableViewDataSource alloc] initWithURL:applicationDocumentsDirectoryURL];
	[[self tableView] setDataSource:dataSource];
    
	[[self tableView] reloadData];
    
	
	// start monitoring the document directory…
	[self setDirWatcher:[DirectoryWatcher watchFolderWithPath:[self applicationDocumentsDirectory] 
													 delegate:self]];
		
	[Theme setThemeForUITableViewController:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}


#pragma mark -
#pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSURL *fileURL = [(FolderTableViewDataSource *)[tableView dataSource] cellDataObjectForIndexPath:indexPath];
	NSString *fileName = [[fileURL path] lastPathComponent];
	
	NSString *nibName = @"DocumentViewController";
	DocumentViewController *viewController = [[DocumentViewController alloc] 
											  initWithNibName:nibName bundle:[NSBundle mainBundle]];
	[viewController setFileName:fileName];
	[viewController setFileData:[NSData dataWithContentsOfFile:[SavedDocument pathToSavedFile:fileName]]];
	[viewController setHidesBottomBarWhenPushed:YES];
	[self.navigationController pushViewController:viewController animated:YES];
	[viewController release];
}


#pragma mark -
#pragma mark DirectoryWatcherDelegate methods

- (void)directoryDidChange:(DirectoryWatcher *)folderWatcher
{
	[(FolderTableViewDataSource *)[self.tableView dataSource] refreshData];
	[self.tableView reloadData];
}


#pragma mark -
#pragma mark File system support

- (NSString *)applicationDocumentsDirectory
{
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}


@end

