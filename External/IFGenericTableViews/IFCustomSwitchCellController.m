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
//  IFCustomSwitchCellController.m
//

#import "IFCustomSwitchCellController.h"
#import "IFControlTableViewCell.h"


@implementation IFCustomSwitchCellController
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
- (id)initWithLabel:(NSString *)newLabel atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel
{
	self = [super init];
	if (self != nil)
	{
		label = [newLabel retain];
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
	
//	CGRect frame = CGRectMake(0.0, 0.0, 94.0, 27.0);
	BOOL storedValue = (NSOrderedSame == [[model objectForKey:key] caseInsensitiveCompare:@"Yes"]);
	
	CSCustomSwitch *switchControl = [CSCustomSwitch switchWithLeftText:@"Yes" andRight:@"No"];
	[switchControl addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
	[switchControl setOn:storedValue];
	cell.view = switchControl;
	[switchControl release];
	
    return cell;
}

- (void)switchAction:(id)sender
{
	// update the model with the switch change
	CSCustomSwitch *switchControl = (CSCustomSwitch *)sender;
	
	switch ([switchControl isOn]) {
		case YES:
			[model setObject:@"Yes" forKey:key];
			break;
		default:
			[model setObject:@"No" forKey:key];
			break;
	}
	
//	NSString *oldValue = [model objectForKey:key];
//	NSNumber *newValue = [NSNumber numberWithBool:! [oldValue boolValue]];
//	
//	[model setObject:newValue forKey:key];
//	
	if (updateTarget && [updateTarget respondsToSelector:updateAction])
	{
		[updateTarget performSelector:updateAction withObject:sender];
	}
}

- (BOOL)equalToYes:(NSString *)value
{
	if (nil == value) return NO;
	
	return ([value caseInsensitiveCompare:@"Yes"] == NSOrderedSame);
}

@end
