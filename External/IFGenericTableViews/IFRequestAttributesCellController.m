//
//  IFRequestAttributesCellController.m
//  Denver311
//
//  Created by Jonathan Newell on 10/31/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IFRequestAttributesCellController.h"
#import "IFControlTableViewCell.h"
#import "ViewUtils.h"

@implementation IFRequestAttributesCellController

@synthesize			label;
@synthesize			value;
@synthesize			backgroundColor;
@synthesize			labelTextColor;
@synthesize			valueTextColor;
@synthesize			labelFont;
@synthesize			valueFont;
@synthesize			indentationLevel;
@synthesize			labelPercentAllocation;
@synthesize			inset;
@synthesize			labelValueGap;
@synthesize			labelWidth;


- (void) dealloc {
	
	self.label = nil;
	self.value = nil;
	self.backgroundColor = nil;
	self.labelTextColor = nil;
	self.valueTextColor = nil;
	self.labelFont = nil;
	self.valueFont = nil;
	self.labelPercentAllocation = nil;
	self.inset = nil;
	self.labelValueGap = nil;
	self.labelWidth = nil;
	
	[super dealloc];
}

- (UIColor *) backgroundColor {
	
	if(backgroundColor == nil){
		self.backgroundColor = [UIColor whiteColor];
	}
	
	return backgroundColor;
	
}

- (UIColor *) labelTextColor {
	if(labelTextColor == nil){
		self.labelTextColor = [UIColor blackColor];
	}
	
	return labelTextColor;
}

- (UIColor *) valueTextColor {
	if(valueTextColor == nil){
		self.valueTextColor = [UIColor blackColor];
	}
	
	return valueTextColor;
}

- (UIFont *) labelFont {
	if(labelFont == nil){
		self.labelFont = [UIFont boldSystemFontOfSize:14];
	}
	
	return labelFont;
}

- (UIFont *) valueFont{
	if(valueFont ==  nil){
		self.valueFont = [UIFont systemFontOfSize:14];
	}
	
	return valueFont;
}

- (NSNumber *) labelPercentAllocation {
	if(labelPercentAllocation == nil){
		self.labelPercentAllocation = [NSNumber numberWithFloat:.3f];
	}
	return labelPercentAllocation;
}

- (NSNumber *) inset {
	if(inset == nil){
		self.inset = [NSNumber numberWithFloat:10.0f];
	}
	return inset;
}

- (NSNumber *) labelValueGap {
	if(labelValueGap == nil){
		self.labelValueGap = [NSNumber numberWithFloat:10.0f];
	}
	return labelValueGap;
}


- (id) initWithLabel:(NSString *)cellLabel value:(NSString *)cellValue atIndentationLevel:(NSInteger)level{
	
	if(self = [super init]){
		self.label = cellLabel;
		self.value = cellValue;
		self.indentationLevel = level;
	}
	
	return self;
}

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *cellIdentifier = @"RequestAttributeDataCell";
	
	UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	UILabel *labelLbl = nil;
	UILabel	*valueLbl = nil;
	
	if (cell == nil) {
		
		//NSLog(@"Creating new RequestAttributeDataCell!");
		
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellIdentifier] autorelease];
    
		labelLbl = [[UILabel alloc] initWithFrame:CGRectZero];
		labelLbl.tag = 1;
		[cell.contentView addSubview:labelLbl];
		[labelLbl release];
		
		valueLbl= [[UILabel alloc] initWithFrame:CGRectZero];
		valueLbl.tag = 2;
		[cell.contentView addSubview:valueLbl];
		[valueLbl release];

	} else {
		//NSLog(@"Using dequeued RequestAttributeDataCell!");

		labelLbl = (UILabel *) [cell.contentView viewWithTag:1];
		valueLbl = (UILabel *) [cell.contentView viewWithTag:2];
		
		
	}	
	
	//Get the required details to size the lables appropriately
	float screenWidth = [ViewUtils currentScreenWidth:tableView] - ([self.inset floatValue] * 2) - [self.labelValueGap floatValue];
	
	//Acct for cell insets from the screen edge. I tried using the cell content view but it causes the labels to
	//jump around as layout occurs. I don't know why they (APPLE) render before those values are updated!
	float availWidth = (screenWidth > 480)?screenWidth -80:screenWidth- 20;
	float lblWidth = 0;
	
	if(self.labelWidth == nil) {
		lblWidth = (availWidth * [self.labelPercentAllocation floatValue]);
		//valueWidth = ((1- [self.labelPercentAllocation floatValue]) * availWidth);
	} else {
		lblWidth = ([self.labelWidth floatValue] < availWidth)?[self.labelWidth floatValue]:availWidth;
	}
	
	//I think it is appropriate to never allow the label to take up more than 50% of the view...
	if(lblWidth > availWidth/2) lblWidth = availWidth/2;
	
	float valueWidth = availWidth - lblWidth;

	float height = fmax([self.label sizeWithFont:self.labelFont].height,[self.value sizeWithFont:self.valueFont].height) + 5;

	//NSLog(@"RACC ScreenWidth [%f] AvailWidth [%f] lblWidth [%f] valueWidth [%f] cell inset [%f] cell label gap [%f]",
	//	  screenWidth, availWidth,lblWidth,valueWidth,[self.inset floatValue],[self.labelValueGap floatValue]);
	
	//Can't go off cell view width because it jumps around as you refresh and everything re-lays out...
	//float cellWidth = cell.contentView.frame.size.width - ([self.inset floatValue] * 2) - [self.labelValueGap floatValue];
	//float lblWidth = (cellWidth * [self.labelPercentAllocation floatValue]);
	//float valueWidth = ((1- [self.labelPercentAllocation floatValue]) * cellWidth);
    //float height = fmax([self.label sizeWithFont:self.labelFont].height,[self.value sizeWithFont:self.valueFont].height) + 5;
	
	
	CGRect labelFrame = CGRectMake([self.inset floatValue], height/2, lblWidth, height);
	CGRect valueFrame = CGRectMake(([self.inset floatValue] + lblWidth + [self.labelValueGap floatValue]), height/2,valueWidth, height);
	

	//NSLog(@"LABEL FRAME [%@] VALUE FRAME [%@]",[NSValue valueWithCGRect:labelFrame],[NSValue valueWithCGRect:valueFrame]);
	
	//Just in case there was an orientation change resize the labels...
	[labelLbl setFrame:labelFrame];
	[valueLbl setFrame:valueFrame];
	
	
	cell.backgroundColor = self.backgroundColor;
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.indentationLevel = self.indentationLevel;
	
	
	labelLbl.font = self.labelFont;
	labelLbl.textColor = self.labelTextColor;
	labelLbl.text = self.label;
	labelLbl.textAlignment = UITextAlignmentRight;
	
	valueLbl.font = self.valueFont;
	valueLbl.textColor = self.valueTextColor;
	valueLbl.text = (value == nil)?@"":self.value;
	valueLbl.textAlignment = UITextAlignmentLeft;
	
	[cell.contentView setNeedsLayout];
	[cell.contentView setNeedsDisplay];
	
    return cell;
}



@end
