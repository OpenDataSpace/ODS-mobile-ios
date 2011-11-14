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
 * Portions created by the Initial Developer are Copyright (C) 2011
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  IFSegmentedCellController.h
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
