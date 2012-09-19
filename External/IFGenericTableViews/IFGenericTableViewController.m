//
//  IFGenericTableViewController.m
//  Thunderbird
//
//	Created by Craig Hockenberry on 1/29/09.
//	Copyright 2009 The Iconfactory. All rights reserved.
//
//  Based on work created by Matt Gallagher on 27/12/08.
//  Copyright 2008 Matt Gallagher. All rights reserved.
//	For more information: http://cocoawithlove.com/2008/12/heterogeneous-cells-in.html
//

#import "IFGenericTableViewController.h"

#import "IFCellController.h"
#import "IFChoiceCellController.h"
#import "IFTextViewTableView.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
#define IS_IPAD ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
#endif

// NOTE: this code requires iPhone SDK 2.2. If you need to use it with SDK 2.1, you can enable
// it here. The table view resizing isn't very smooth, but at least it works :-)
#define FIRMWARE_21_COMPATIBILITY 0

@implementation IFGenericTableViewController

@synthesize model, controllerForReturnHandler;

#if FIRMWARE_21_COMPATIBILITY
- (void)awakeFromNib
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardShown:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardHidden:) name:UIKeyboardWillHideNotification object:nil];

	[super awakeFromNib];
}
#endif

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	if (IS_IPAD) {
		return YES;
	} else
#endif
		return (interfaceOrientation == UIInterfaceOrientationPortrait);

}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
	[self updateAndRefresh];
}

//
// constructTableGroups
//
// Creates/updates cell data. This method should only be invoked directly if
// a "reloadData" needs to be avoided. Otherwise, updateAndReload should be used.
//
- (void)constructTableGroups
{	
	tableGroups = nil;
	tableHeaders = nil;
	tableFooters = nil;
	addonstartup = NO;
}

- (void)assignFirstResponderHostToCellControllers
{
	if (nil == tableGroups) return;
	
	int section = 0;
	int row = 0;
	int maxSections = [tableGroups count];
	int maxRow = [self tableView: nil numberOfRowsInSection: section];
	NSIndexPath *indexPath = nil;
	NSObject<IFCellController> *cellController = nil;
	
	while (section < maxSections) {
		indexPath = [NSIndexPath indexPathForRow: row inSection: section];
		@try {
			cellController = [self cellControllerForIndexPath: indexPath];
			if (nil != cellController && [cellController conformsToProtocol: @protocol(IFCellControllerFirstResponder)] == YES) {
				[((NSObject<IFCellControllerFirstResponder>*)cellController) assignFirstResponderHost: self];
			}
		} 
		@catch (NSException *ex) {
			NSLog(@"unable to get cell controller from table groups");
		}
		row++;
		if (row == maxRow) {
			row = 0;
			section++;
			if (section < maxSections) {
				maxRow = [self tableView: nil numberOfRowsInSection: section];
			}
		}
	}
}

- (void)resignAllFirstResponders
{
	if (nil == tableGroups) return;
	
	int section = 0;
	int row = 0;
	int maxSections = [tableGroups count];
	int maxRow = [self tableView: nil numberOfRowsInSection: section];
	NSIndexPath *indexPath = nil;
	NSObject<IFCellController> *cellController = nil;
	
	while (section < maxSections) {
		indexPath = [NSIndexPath indexPathForRow: row inSection: section];
		@try {
			cellController = [self cellControllerForIndexPath: indexPath];
			if (nil != cellController && [cellController conformsToProtocol: @protocol(IFCellControllerFirstResponder)] == YES) {
				@try {
					[((NSObject<IFCellControllerFirstResponder>*)cellController) resignFirstResponder];
				}
				@catch (NSException * e) {
					NSLog(@"Error trying to resign first responder");
				}
			}
		} 
		@catch (NSException *ex) {
			NSLog(@"unable to get cell controller from table groups");
		}
		row++;
		if (row == maxRow) {
			row = 0;
			section++;
			if (section < maxSections) {
				maxRow = [self tableView: nil numberOfRowsInSection: section];
			}
		}
	}
}

//
// clearTableGroups
//
// Releases the table group data (it will be recreated when next needed)
//
- (void)clearTableGroups
{	
	[tableHeaders release];
	tableHeaders = nil;
	[tableGroups release];
	tableGroups = nil;
	[tableFooters release];
	tableFooters = nil;
}

//
// updateAndReload
//
// Performs all work needed to refresh the data and the associated display
//
- (void)updateAndReload
{
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(updateAndReload) withObject:nil waitUntilDone:NO];
        return;
    }
    
	[self resignAllFirstResponders];
	[self clearTableGroups];
	[self constructTableGroups];
	[self.tableView reloadData];
}

- (void)updateAndRefresh
{
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(updateAndRefresh) withObject:nil waitUntilDone:NO];
        return;
    }
    
	[self resignAllFirstResponders];
	[self.tableView reloadData];
}

//
// numberOfSectionsInTableView:
//
// Return the number of sections for the table.
//
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if (!tableGroups)
	{
		[self constructTableGroups];
	}
	
	return [tableGroups count];
}

//
// tableView:numberOfRowsInSection:
//
// Returns the number of rows in a given section.
//
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (!tableGroups)
	{
		[self constructTableGroups];
	}
	
	return [[tableGroups objectAtIndex:section] count];
}

//
// tableView:heightForRowAtIndexPath
//
// Returns the height for a given indexPath
//
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (!tableGroups)
	{
		[self constructTableGroups];
	}
	
	NSObject<IFCellController> *cellController = [[tableGroups objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	
	CGFloat height;

	if ([cellController respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {
		height = [cellController tableView:tableView heightForRowAtIndexPath:indexPath];
	} else {
		height = [tableView rowHeight];
	}
		
	return height;
}

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (!tableGroups)
	{
		[self constructTableGroups];
	}
	
	NSUInteger section = indexPath.section;
	NSUInteger row = indexPath.row;
	NSArray *cells = [tableGroups objectAtIndex:section];
	id<IFCellController> controller = [cells objectAtIndex:row];
	
	UITableViewCell *cell = [controller tableView:(UITableView *)tableView cellForRowAtIndexPath:indexPath];
	
	if (addonstartup) {
		NSObject<IFCellController> *cellController =  [self cellControllerForIndexPath: indexPath];
		if ([cellController conformsToProtocol: @protocol(IFCellControllerFirstResponder)]) {
			addonstartup = NO;
			[((id<IFCellControllerFirstResponder>)cellController) becomeFirstResponder];
		}
	}
	
	return cell;
}

//
// tableView:didSelectRowAtIndexPath:
//
// Handle row selection
//
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (!tableGroups)
	{
		[self constructTableGroups];
	}
	
	NSObject<IFCellController> *cellData =
		[[tableGroups objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	if ([cellData respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)])
	{
		[cellData tableView:tableView didSelectRowAtIndexPath:indexPath];
	}
}

//
// tableView:accessoryButtonTappedForRowWithIndexPath:
//
// Handle accessory selection
//
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	if (!tableGroups)
	{
		[self constructTableGroups];
	}
	
	NSObject<IFCellController> *cellData =
		[[tableGroups objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	if ([cellData respondsToSelector:@selector(tableView:accessoryButtonTappedForRowWithIndexPath:)])
	{
		[cellData tableView:tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (!tableGroups)
	{
		[self constructTableGroups];
	}
	
	NSString *title = nil;
	if (tableHeaders)
	{
		id object = [tableHeaders objectAtIndex:section];
		if ([object isKindOfClass:[NSString class]])
		{
			if ([object length] > 0)
			{
				title = object;
			}
		}
	}
	
	return title;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	if (!tableGroups)
	{
		[self constructTableGroups];
	}
	
	NSString *title = nil;
	if (tableFooters)
	{
		id object = [tableFooters objectAtIndex:section];
		if ([object isKindOfClass:[NSString class]])
		{
			if ([object length] > 0)
			{
				title = object;
			}
		}
	}

	return title;
}

//
// didReceiveMemoryWarning
//
// Release any cache data.
//
- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
}

//
// dealloc
//
// Release instance memory
//
- (void)dealloc
{
#if FIRMWARE_21_COMPATIBILITY
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
#endif

	[model release];
	[tableHeaders release];
	[tableGroups release];
	[tableFooters release];
	[super dealloc];
}

- (void)validate:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)loadView
{
#if 1
	// NOTE: This code circumvents the normal loading of the UITableView and replaces it with an instance
	// of IFTextViewTableView (which includes a workaround for the hit testing problems in a UITextField.)
	// Check the header file for IFTextViewTableView to see why this is important.
	//
	// Since there is no style accessor on UITableViewController (to obtain the value passed in with the
	// initWithStyle: method), the value is hard coded for this use case. Too bad.

	self.view = [[[IFTextViewTableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped] autorelease];
	[(IFTextViewTableView *)self.view setDelegate:self];
	[(IFTextViewTableView *)self.view setDataSource:self];
	[self.view setAutoresizesSubviews:YES];
	[self.view setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
#else
	[super loadView];
#endif
}

- (void)viewWillAppear:(BOOL)animated
{
    NSIndexPath *selectedIndex = [[self.tableView indexPathForSelectedRow] copy];
	[super viewWillAppear:animated];
    
	// rows (such as choices) that were updated in child view controllers need to be updated
	[self.tableView reloadData];
    
    // Reloading the table view data causes our selection to disappear
    if(!self.clearsSelectionOnViewWillAppear) {
        [self.tableView selectRowAtIndexPath:selectedIndex animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    [selectedIndex release];
}

- (void)viewDidAppear:(BOOL)animated
{
	if (nil != controllerForReturnHandler) {
		
//		if ([controllerForReturnHandler isKindOfClass:[IFChoiceCellController class]] ||
//			[controllerForReturnHandler isKindOfClass:[IFPhotoCellController class]]) 
    if ([controllerForReturnHandler isKindOfClass:[IFChoiceCellController class]])
		{
			[self performSelector:@selector(advanceToNextResponderFromCellController:) withObject:controllerForReturnHandler afterDelay:0.2];
		}
		
		controllerForReturnHandler = nil;
	}
	
	[super viewDidAppear:animated];
}

#if FIRMWARE_21_COMPATIBILITY

- (void)keyboardShown:(NSNotification *)notification
{
	CGRect keyboardBounds;
	[[[notification userInfo] valueForKey:UIKeyboardBoundsUserInfoKey] getValue:&keyboardBounds];
	
	CGRect tableViewFrame = [self.tableView frame];
	tableViewFrame.size.height -= keyboardBounds.size.height;

	[self.tableView setFrame:tableViewFrame];
}

- (void)keyboardHidden:(NSNotification *)notification
{
	CGRect keyboardBounds;
	[[[notification userInfo] valueForKey:UIKeyboardBoundsUserInfoKey] getValue:&keyboardBounds];
	
	CGRect tableViewFrame = [self.tableView frame];
	tableViewFrame.size.height += keyboardBounds.size.height;

	[self.tableView setFrame:tableViewFrame];
}

#endif

- (NSObject<IFCellController> *)cellControllerForIndexPath: (NSIndexPath *)indexPath
{
	if (nil == indexPath) return nil;
	
	if (!tableGroups)
	{
		[self constructTableGroups];
	}
	
	id cellController = nil;
	@try {
        if (tableGroups.count > indexPath.section)
        {
            id tableGroupObject = [tableGroups objectAtIndex:indexPath.section];
            
            if ([tableGroupObject count] > indexPath.row)
            {
                cellController = [tableGroupObject objectAtIndex:indexPath.row];
            }
        }
	} @catch (NSException *e) {
		NSLog(@"Error getting cell controller: %@", e);
	}
	
	if (nil != cellController && [cellController conformsToProtocol: @protocol(IFCellController)]) {
		return ((NSObject<IFCellController> *)cellController);
	} else {
		return nil;
	}
}

- (NSIndexPath *)indexPathForCellController: (NSObject<IFCellController> *)cellController
{
	if (nil == cellController) return nil;
	int section = 0;
	int row = 0;
	int maxSections = [self numberOfSectionsInTableView: nil];
	if (0 == maxSections) return nil;
	int maxRowsInSection  = [self tableView: nil numberOfRowsInSection: 0];
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection: section];
	
	while (cellController != [self cellControllerForIndexPath: indexPath] && maxSections > section) {
		row++;
		if (maxRowsInSection == row) {
			section++;
			row = 0;
			if (maxSections > section) {
				maxRowsInSection = [self tableView: nil numberOfRowsInSection: section];
			}
		}
		indexPath = [NSIndexPath indexPathForRow: row inSection: section];
	}
	
	if (indexPath.section == maxSections) return nil;
	return indexPath;
}

- (NSIndexPath *)nextValidIndexPathForIndexPath: (NSIndexPath *)indexPath
{
	if (nil == indexPath) return [NSIndexPath indexPathForRow: 0 inSection: 0];
	int maxSections = [self numberOfSectionsInTableView: nil];
	if (0 == maxSections) return nil;
	int section = indexPath.section;
	int row = indexPath.row;
	int maxRowsInSection  = [self tableView: nil numberOfRowsInSection: section];
	
	row++;
	if (maxRowsInSection == row) {
		row = 0;
		section++;
	}
	
	if (section == maxSections) return nil;
	NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:row inSection: section];
	return nextIndexPath;
}

- (void)advanceToNextResponderFromCellController: (NSObject<IFCellController> *)cellController
{
	// if we already have a first responder resign it
	if ( nil != cellController && [cellController conformsToProtocol: @protocol(IFCellControllerFirstResponder)] == YES ) {
		[((NSObject<IFCellControllerFirstResponder> *)cellController) resignFirstResponder];
	}
	
	// attempt to find the next cell that conforms to the IFCellControllerFirstResponder protocol
	NSIndexPath *indexPath = [self indexPathForCellController: cellController];
	indexPath = [self nextValidIndexPathForIndexPath: indexPath];
	NSObject<IFCellController> *nextCellController = [self cellControllerForIndexPath: indexPath];
	while (nil != nextCellController && NO == [nextCellController conformsToProtocol: @protocol(IFCellControllerFirstResponder)]) {
		indexPath = [self nextValidIndexPathForIndexPath: indexPath];
		nextCellController = [self cellControllerForIndexPath: indexPath];
	}
	
	if (nil != nextCellController) {
		[((NSObject<IFCellControllerFirstResponder> *)nextCellController) becomeFirstResponder];
	}
}

- (void)lastResponderIsDone: (NSObject<IFCellController> *)cellController
{
	// if we already have a first responder resign it
	if ( nil != cellController && [cellController conformsToProtocol: @protocol(IFCellControllerFirstResponder)] == YES ) {
		[((NSObject<IFCellControllerFirstResponder> *)cellController) resignFirstResponder];
	}
}

@end

