//
//  IFValueCellController.m
//

#import "IFLocationCellController.h"
#import "LocationViewController.h"

#import "IFGenericTableViewController.h"
#import "IFControlTableViewCell.h"
#import "IFNamedImage.h"

@implementation IFLocationCellController

@synthesize backgroundColor;
@synthesize viewBackgroundColor;
@synthesize selectionStyle;
@synthesize indentationLevel;
@synthesize tableViewController;
@synthesize cellIndexPath;

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
	[viewBackgroundColor release];
	[tableViewController release];
	[cellIndexPath release];
	
	[super dealloc];
}

//
// init
//
// Init methods for the object.
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
		viewBackgroundColor = nil;
		indentationLevel = 0;
		selectionStyle = UITableViewCellSelectionStyleBlue;
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
	self.cellIndexPath = indexPath;
	self.tableViewController = (UITableViewController *)tableView.dataSource;
	
	LocationViewController *controller = [[LocationViewController alloc] init];
	controller.title = label;
	controller.model = model;
	controller.key = key;
	
	((IFGenericTableViewController *)tableViewController).controllerForReturnHandler = self;
	
	[self.tableViewController.navigationController pushViewController:controller animated:YES];
	
	[controller release];
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)popoverControllerDidDismissPopover:(id)popoverController
{
	[[tableViewController tableView] reloadRowsAtIndexPaths:[NSArray arrayWithObject:cellIndexPath] withRowAnimation:UITableViewRowAnimationFade];
}

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"DateDataCell";
	
    IFControlTableViewCell *cell = (IFControlTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
		cell = [[[IFControlTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellIdentifier] autorelease];
		cell.textLabel.font = [UIFont boldSystemFontOfSize:17.0f];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
	
	if (nil != backgroundColor) [cell setBackgroundColor:backgroundColor];
	
	cell.selectionStyle = selectionStyle;
	cell.indentationLevel = indentationLevel;
	
	cell.textLabel.text = label;
	
	// NOTE: The documentation states that the indentation width is 10 "points". It's more like 20
	// pixels and changing the property has no effect on the indentation. We'll use 20.0f here
	// and cross our fingers that this doesn't screw things up in the future.	
	CGSize labelSize = [label sizeWithFont:cell.textLabel.font];
	CGFloat viewWidth = 255.0f - (labelSize.width + (20.0f * indentationLevel));
	UILabel *valueLabel = nil;
	if (nil == cell.view) {
		CGRect frame = CGRectMake(0.0f, 0.0f, viewWidth, 22.0f);
		valueLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
		[valueLabel setFont:[UIFont systemFontOfSize:17.0f]];
		[valueLabel setBackgroundColor:[UIColor whiteColor]];
		[valueLabel setHighlightedTextColor:[UIColor whiteColor]];
		[valueLabel setTextAlignment:UITextAlignmentRight];
		[valueLabel setTextColor:[UIColor colorWithRed:0.20f green:0.31f blue:0.52f alpha:1.0f]];
		if (nil != backgroundColor) {
			[valueLabel setBackgroundColor:backgroundColor];
		}
		cell.view = valueLabel;
	} else {
		valueLabel = (UILabel *)cell.view;
	}
	
	NSString *location = [model objectForKey:key];
	if (nil == location) {
		location = @"";
		[model setObject:location forKey:key];
	}
	[valueLabel setText:location];
	
    return cell;
}

@end
