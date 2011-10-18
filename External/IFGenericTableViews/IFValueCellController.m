//
//  IFValueCellController.m
//  Thunderbird
//
//	Created by Craig Hockenberry on 1/29/09.
//	Copyright 2009 The Iconfactory. All rights reserved.
//

#import "IFValueCellController.h"

#import "IFControlTableViewCell.h"
#import "IFNamedImage.h"
#import "UIImageUtils.h"

@implementation IFValueCellController

@synthesize backgroundColor;
@synthesize indentationLevel, url, defaultValue;

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
	[url release];
	[defaultValue release];
	
	[super dealloc];
}

//
// init
//
// Init methods for the object.
//
- (id)initWithLabel:(NSString *)newLabel atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel
{
	return [self initWithLabel:newLabel atKey:newKey withURL:nil inModel:newModel];
}

- (id)initWithLabel:(NSString *)newLabel atKey:(NSString *)newKey withURL:(NSURL *)newURL inModel:(id<IFCellModel>)newModel
{
	self = [super init];
	if (self != nil)
	{
		label = [newLabel retain];
		key = [newKey retain];
		model = [newModel retain];
		
		backgroundColor = nil;
		indentationLevel = 0;
		
		url = [newURL retain];
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
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (nil != url) {
		[[UIApplication sharedApplication] openURL:url];
	}
}

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"DataDataCell";

    IFControlTableViewCell *cell = (IFControlTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
		cell = [[[IFControlTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellIdentifier] autorelease];
    }
	
	if (nil != backgroundColor) [cell setBackgroundColor:backgroundColor];
	
	cell.textLabel.font = [UIFont boldSystemFontOfSize:17.0f];
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.indentationLevel = indentationLevel;
		
	cell.textLabel.text = label;

	// NOTE: The documentation states that the indentation width is 10 "points". It's more like 20
	// pixels and changing the property has no effect on the indentation. We'll use 20.0f here
	// and cross our fingers that this doesn't screw things up in the future.	
	CGSize labelSize = [label sizeWithFont:cell.textLabel.font];
	CGFloat viewWidth = 255.0f - (labelSize.width + (20.0f * indentationLevel));
	UILabel *valueLabel = nil;
	
	id value = [model objectForKey:key];
	
		
	if (nil == cell.view) {
		
		
		CGRect frame = CGRectMake(0.0f, 0.0f, viewWidth, 22.0f);
		valueLabel = [[UILabel alloc] initWithFrame:frame];
		[valueLabel setFont:[UIFont systemFontOfSize:17.0f]];
		[valueLabel setBackgroundColor:[UIColor clearColor]]; // !!! BW - don't like this hack but [cell backgroundColor] isn't working for iPad
		[valueLabel setHighlightedTextColor:[UIColor whiteColor]];
		[valueLabel setTextAlignment:UITextAlignmentRight];
		[valueLabel setTextColor:[UIColor colorWithRed:0.20f green:0.31f blue:0.52f alpha:1.0f]];
		if (nil != backgroundColor) {
			[valueLabel setBackgroundColor:backgroundColor];
		}
		cell.view = valueLabel;
		[valueLabel release];
	} else {
		valueLabel = (UILabel *)cell.view;
	}
	
	
	NSString *labelText = @"";
	if (nil == value && nil != defaultValue) {
		labelText = defaultValue;
	}
	else if ([value isKindOfClass:[NSString class]])
	{
		labelText = value;
	}
	else if ([value isKindOfClass:[NSNumber class]])
	{
		labelText = [value stringValue];
	} 
	
	[valueLabel setText:labelText];
	
	
	
	

	if (nil != url) {
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	} else {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
    return cell;
}

@end
