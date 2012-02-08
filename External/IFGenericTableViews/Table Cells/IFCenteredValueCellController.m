//
//  IFCenteredValueCellController.m
//  Denver311
//
//  Created by Jonathan Newell on 10/31/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
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
		cell = [[[IFControlTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
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
