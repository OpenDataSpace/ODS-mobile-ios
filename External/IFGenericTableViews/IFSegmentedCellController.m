//
//  IFSegmentedCellController.h
//  Thunderbird
//
//	Created by Bindu Wavell from Craig's Switch and Choice code
//  Copyright 2010 Zia Consulting, Inc. All rights reserved.
//

#import "IFSegmentedCellController.h"

#import	"IFControlTableViewCell.h"

@implementation IFSegmentedCellController

@synthesize backgroundColor;
@synthesize updateTarget, updateAction;

//
// dealloc
//
// Releases instance memory.
//
- (void)dealloc
{
	[label release];
	[choices release];
	[key release];
	[model release];
	[backgroundColor release];
	
	[super dealloc];
}

//
// init
//
// Init method for the object.
//
- (id)initWithLabel:(NSString *)newLabel andChoices:(NSArray *)newChoices atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel
{
	self = [super init];
	if (self != nil)
	{
		label = [newLabel retain];
		choices = [newChoices retain];
		key = [newKey retain];
		model = [newModel retain];
		
		backgroundColor = nil;
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
	static NSString *cellIdentifier = @"SwitchDataCell";
	
    IFControlTableViewCell *cell = (IFControlTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
		cell = [[[IFControlTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellIdentifier] autorelease];		
    }
	
	if (nil != backgroundColor) [cell setBackgroundColor:backgroundColor];
	
	cell.textLabel.font = [UIFont boldSystemFontOfSize:17.0f];
	cell.textLabel.text = label;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
	NSString *modelValue = [model objectForKey:key];
	UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:choices];
	NSUInteger idx = [choices indexOfObject:modelValue];
	if (idx == NSNotFound) {
		idx = 0;
		NSString *choice = [choices objectAtIndex:idx];
		[model setObject:choice forKey:key];
	}
	[segmentedControl setSelectedSegmentIndex:idx];
	[segmentedControl setSegmentedControlStyle:UISegmentedControlStyleBar];
	[segmentedControl setTintColor:[UIColor lightGrayColor]];
	// select appropriate segment based on model value
	[segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
	cell.view = segmentedControl;
	[segmentedControl release];

    return cell;
}

- (void)segmentAction:(id)sender
{
	if ([sender isKindOfClass:[UISegmentedControl class]]) {
		UISegmentedControl *segmentedControl = ((UISegmentedControl *)sender);
		NSString *choice = [choices objectAtIndex:[segmentedControl selectedSegmentIndex]];
		
		[model setObject:choice forKey:key];

		if (updateTarget && [updateTarget respondsToSelector:updateAction])
		{
			[updateTarget performSelector:updateAction withObject:sender];
		}
	}
}

@end
