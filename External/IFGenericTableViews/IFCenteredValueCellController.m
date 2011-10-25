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
//  IFCenteredValueCellController.m
//

#import "IFCenteredValueCellController.h"
#import "IFControlTableViewCell.h"


@implementation IFCenteredValueCellController

@synthesize backgroundColor;
@synthesize value;
@synthesize	cellFont;
@synthesize cellTextColor;


- (void) dealloc {
	
	self.backgroundColor = nil;
	self.value = nil;
	self.cellFont = nil;
	self.cellTextColor = nil;
		
	[super dealloc];
}

- (UIColor *) backgroundColor {
	
	if(backgroundColor == nil) {
		self.backgroundColor = [UIColor whiteColor];
	}
	
	return backgroundColor;	
}

- (UIFont *) cellFont {
	
	if(cellFont == nil){
		self.cellFont = [UIFont boldSystemFontOfSize:18];
	}
	
	return cellFont;
}

- (UIColor *) cellTextColor {
	if(cellTextColor == nil) {
		self.cellTextColor = [UIColor blackColor];
	}
	
	return cellTextColor;
}


- (id) initWithValue:(NSString *)cellValue {
	
	if((self = [super init])) {
		self.value = cellValue;
	}
	
	return self;
	
}

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"CenterValueCell";
	
    IFControlTableViewCell *cell = (IFControlTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
		cell = [[[IFControlTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellIdentifier] autorelease];
    }
	
	[cell setBackgroundColor:self.backgroundColor];
	cell.textLabel.font = self.cellFont;
	cell.textLabel.textColor = self.cellTextColor;
	cell.textLabel.text = self.value;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.textLabel.textAlignment = UITextAlignmentCenter;
	
	return cell;
}






@end
