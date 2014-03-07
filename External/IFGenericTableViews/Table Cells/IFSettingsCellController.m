//
//  IFSettingsCellController.m
//  FreshDocs
//
//  Created by bdt on 3/7/14.
//
//

#import "IFSettingsCellController.h"
#import "IFControlTableViewCell.h"

@implementation IFSettingsCellController
@synthesize backgroundColor;
@synthesize textColor;
@synthesize selectionStyle;
@synthesize accessoryType;
@synthesize action;
@synthesize target;
@synthesize userInfo;
@synthesize label;
@synthesize subLabel;

//
// init
//
// Init method for the object.
//
- (id)initWithLabel:(NSString *)newLabel subLabel:(NSString *)newSubLabel withAction:(SEL)newAction onTarget:(id)newTarget
{
	self = [super init];
	if (self != nil)
	{
        userInfo = nil;
		label = newLabel;
        subLabel = newSubLabel;
		action = newAction;
		target = newTarget;
		
		backgroundColor = nil;
		selectionStyle = UITableViewCellSelectionStyleBlue;
		accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	return self;
}

//
// tableView:didSelectRowAtIndexPath:
//
// Handle row selection
//
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (accessoryType != UITableViewCellAccessoryDetailDisclosureButton)
	{
		if (target && [target respondsToSelector:action])
		{
			[target performSelector:action withObject:self];
		}
		
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
}

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"SettingsDataCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
    }
	
	if (nil != backgroundColor) [cell setBackgroundColor:backgroundColor];
    if (nil != textColor) [cell.textLabel setTextColor:textColor];
	
    cell.textLabel.backgroundColor = [UIColor clearColor];
	cell.textLabel.text = label;
    cell.detailTextLabel.text = subLabel;
	cell.textLabel.font = [UIFont boldSystemFontOfSize:17.0f];
	cell.accessoryType = accessoryType;
	cell.selectionStyle = selectionStyle;
	
    return cell;
}

//
// tableView:accessoryButtonTappedForRowWithIndexPath
//
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	if (target && [target respondsToSelector:action])
	{
		[target performSelector:action];
	}
}

@end
