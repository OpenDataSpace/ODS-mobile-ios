//
//  IFSwitchCellController.h
//  Thunderbird
//
//	Created by Craig Hockenberry on 1/29/09.
//	Copyright 2009 The Iconfactory. All rights reserved.
//

#import "IFSwitchCellController.h"

#import	"FDControlTableViewCell.h"
#import "NSNotificationCenter+CustomNotification.h"

@implementation IFSwitchCellController

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
	
    FDControlTableViewCell *cell = (FDControlTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
        cell = [[[FDControlTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
        [cell.textLabel setAdjustsFontSizeToFitWidth:YES];
    }
	
	if (nil != backgroundColor) [cell setBackgroundColor:backgroundColor];
	
	cell.textLabel.font = [UIFont boldSystemFontOfSize:17.0f];
	cell.textLabel.text = label;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
	CGRect frame = CGRectMake(0.0, 0.0, 94.0, 27.0);
	UISwitch *switchControl = [[UISwitch alloc] initWithFrame:frame];
	[switchControl addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
	NSNumber *value = [model objectForKey:key];
	[switchControl setOn:[value boolValue]];
	cell.view = switchControl;
	[switchControl release];

    return cell;
}

- (void)switchAction:(id)sender
{
	// update the model with the switch change

	NSNumber *oldValue = [model objectForKey:key];
	NSNumber *newValue = [NSNumber numberWithBool:! [oldValue boolValue]];

	[model setObject:newValue forKey:key];
    
    if ([key isEqualToString:@"SyncDocs"]) {
        
        [[NSNotificationCenter defaultCenter] postSyncPreferenceChangedNotification];
    }

	if (updateTarget && [updateTarget respondsToSelector:updateAction])
	{
		[updateTarget performSelector:updateAction withObject:sender];
	}
}

@end
