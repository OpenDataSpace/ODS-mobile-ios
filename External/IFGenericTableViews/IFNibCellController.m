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
//  IFNibCellController.m
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

