//
//  IFNibCellController.m
//  Denver311
//
//  Created by Gi Hyun Lee on 9/1/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

#import "IFNibCellController.h"
#import "IconBadgeTableViewCell.h"

@implementation IFNibCellController
@synthesize nibName;
@synthesize nibCell;
@synthesize cellIndexPath;
@synthesize tableController;


#pragma mark Memory management
- (void)dealloc {
		
	self.nibName = nil;
	self.nibCell = nil;
	self.cellIndexPath = nil;
	self.tableController = nil;
	
    [super dealloc];
}

#pragma mark init Methods
- (id)initWithCellNibName:(NSString *)name
{
	if (self = [super init]) {
		self.nibName = name;
	}
	return self;
}

#pragma mark -
#pragma mark IFCellController Methods
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.tableController = (UITableViewController *)[tableView dataSource];
	self.cellIndexPath = indexPath;
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nibName]; // identifier value set in nib using IB
	if (nil == cell) {
		NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:nibName owner:self options:nil];
		
		id objectOne = [nibArray objectAtIndex:0];
		if ([objectOne isKindOfClass:[UITableViewCell class]]) {
			cell = objectOne;			
		}
		else {
			
			cell = [nibArray objectAtIndex:1];
		}
	} else {

		//Without this dequeued cells were never getting retained...loading from the nib manages it for the initial
		//cell. But after that things get flaky.
		self.nibCell = cell;
		
	}

	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
/*
	CGFloat rowHeight;
	if (nibCell) {
		// TODO: Determine Height from measuring items
		rowHeight = 80.0;
	}
	else {
		rowHeight = [tableView rowHeight];
	}
	return rowHeight;
 */
	return 80.0f;
}

#pragma mark Helper Methods
- (void)reloadCell
{
	[[tableController tableView] reloadRowsAtIndexPaths:[NSArray arrayWithObject:cellIndexPath] 
									   withRowAnimation:UITableViewRowAnimationFade];
}

@end

