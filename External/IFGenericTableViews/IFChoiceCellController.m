//
//  IFChoiceRowCellController.m
//  Thunderbird
//
//	Created by Craig Hockenberry on 1/29/09.
//	Copyright 2009 The Iconfactory. All rights reserved.
//

#import "IFChoiceCellController.h"

#import "IFGenericTableViewController.h"
#import "IFControlTableViewCell.h"
#import "IFNamedImage.h"
#import "IFLabelValuePair.h"
#import "IFTemporaryModel.h"

@implementation IFChoiceCellController

@synthesize choices;
@synthesize refreshTarget, refreshAction;
@synthesize updateTarget, updateAction;
@synthesize footerNote;
@synthesize indentationLevel;
@synthesize cellControllerFirstResponderHost, tableController, cellIndexPath;
@synthesize selectionOptional, separator;
@synthesize showSelectedValueAsLabel;
@synthesize backgroundColor;
@synthesize viewBackgroundColor;
@synthesize selectionStyle;

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
	[viewBackgroundColor release];
	
	[footerNote release];
	
	[tableController release];
	[cellIndexPath release];
	
	[separator release];
	
	[super dealloc];
}

//
// init
//
// Init method for the object.
//
- (id)initWithLabel:(NSString *)newLabel andChoices:(NSArray *)newChoices atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel;
{
	self = [super init];
	if (self != nil)
	{
		label = [newLabel retain];
		[self setChoices:newChoices];
		key = [newKey retain];
		model = [newModel retain];

		backgroundColor = nil;
		viewBackgroundColor = nil;
		footerNote = nil;
		
		indentationLevel = 0;
		
		selectionOptional = NO;
		autoAdvance = NO;
		showSelectedValueAsLabel = NO;
		
		if ((choices != nil) && ([choices count] >= 1))
			selectionStyle = UITableViewCellSelectionStyleBlue;
		else {
			selectionStyle = UITableViewCellSelectionStyleNone;
		}
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
	if (selectionStyle == UITableViewCellSelectionStyleNone) {
		NSLog(@"WARNING: no values were available for attribute %@", [(IFTemporaryModel *)model dictionary]);
		return;	
	}
	
	if (refreshTarget && [refreshTarget respondsToSelector:refreshAction])
	{
		[refreshTarget performSelector:refreshAction withObject:self];
	}
	
	UITableViewController *tableViewController = (UITableViewController *)tableView.dataSource;
	
	IFChoiceTableViewController *choiceTableViewController = [[IFChoiceTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
	choiceTableViewController.title = label;
	choiceTableViewController.choices = choices;
	choiceTableViewController.model = model;
	choiceTableViewController.key = key;
	choiceTableViewController.updateTarget = updateTarget;
	choiceTableViewController.updateAction = updateAction;
	choiceTableViewController.footerNote = footerNote;
	choiceTableViewController.selectionOptional = selectionOptional;
	choiceTableViewController.separator = separator;
	choiceTableViewController.backgroundColor = viewBackgroundColor;
	choiceTableViewController.selectionStyle = selectionStyle;
	
	if (autoAdvance) {
		((IFGenericTableViewController *)tableViewController).controllerForReturnHandler = self;
		autoAdvance = NO;
	}

	[tableViewController.navigationController pushViewController:choiceTableViewController animated:YES];
	[choiceTableViewController release];

	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)labelForChoice:(id)choice
{
	NSString *l = nil;
	if ([choice isKindOfClass:[NSString class]]) {
		l = choice;
	} else if ([choice isKindOfClass:[IFNamedImage class]]) {
		l = [choice name];
	} else if ([choice isKindOfClass:[IFLabelValuePair class]]) {
		l = [choice pairLabel];
	}
	if (nil != l) {
		l = [l stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	}
	return l;
}

- (NSString *)valueForChoice:(id)choice
{
	NSString *value = nil;
	if ([choice isKindOfClass:[NSString class]]) {
		value = choice;
	} else if ([choice isKindOfClass:[IFNamedImage class]]) {
		value = [choice name];
	} else if ([choice isKindOfClass:[IFLabelValuePair class]]) {
		value = [choice pairValue];
	}
	if (nil != value) {
		value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	}
	return value;	
}

- (NSString *)labelForValue:(NSString *)value
{
	if (nil == value) return @"";
	
	if (showSelectedValueAsLabel) {
		return value;
	}
	
	NSArray *values = nil;
	if (nil != separator) values = [value componentsSeparatedByString:separator];
	if (nil != separator && [values count] > 1) {
		NSMutableString *choicesLabel = [NSMutableString string];
		for (NSString *val in values) {
			if ([choicesLabel length] > 0) {
				[choicesLabel appendString:separator];
			}
			[choicesLabel appendString:[self labelForValue:val]];
		}
		return choicesLabel;
	}
	
	for (id choice in choices) {
		NSString *choiceValue = [self valueForChoice:choice];
		NSString *choiceLabel = [self labelForChoice:choice];
		if ([choiceValue isEqualToString:value]) return choiceLabel;
	}
	
	return @"";
}

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.cellIndexPath = indexPath;
	self.tableController = (UITableViewController *)tableView.dataSource;
	
	static NSString *cellIdentifier = @"ChoiceDataCell";

    IFControlTableViewCell *cell = (IFControlTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
		cell = [[[IFControlTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellIdentifier] autorelease];
		
    }

	if (nil != backgroundColor) [cell setBackgroundColor:backgroundColor];

	cell.textLabel.font = [UIFont boldSystemFontOfSize:17.0f];
	cell.accessoryType = ((selectionStyle != UITableViewCellSelectionStyleNone) ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone);
	cell.indentationLevel = indentationLevel;
	cell.selectionStyle = selectionStyle;
	
	// NOTE: The documentation states that the indentation width is 10 "points". It's more like 20
	// pixels and changing the property has no effect on the indentation. We'll use 20.0f here
	// and cross our fingers that this doesn't screw things up in the future.
	
	// choice is subview in cell
	cell.textLabel.text = label;
	
	CGSize labelSize = [label sizeWithFont:cell.textLabel.font];
	CGFloat viewWidth = 255.0f - (labelSize.width + (20.0f * indentationLevel));
	
	NSString *modelValue = [[model objectForKey:key] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

	// if we don't have a choice stored in the model
	// and selection is not optional then we simply
	// add the first choice into the model.
//	if (nil == modelValue && !selectionOptional)
//	{
//		modelValue = [self valueForChoice:[choices objectAtIndex: 0]];
//		[model setObject:modelValue forKey:key];
//	}
	// if there is no selection then we don't want to
	// show anything in the selected value area
	if (nil == modelValue) {
		cell.view = nil;
	}
	
	// otherwise based on the type of selection we determine
	// what to show
	else {
		NSString *choiceLabelText = [self labelForValue:modelValue];
		CGRect frame = CGRectMake(0.0f, 0.0f, viewWidth, 22.0f);
		UILabel *choiceLabel = [[UILabel alloc] initWithFrame:frame];
		[choiceLabel setText:choiceLabelText];
		[choiceLabel setFont:[UIFont systemFontOfSize:17.0f]];
		[choiceLabel setBackgroundColor:[UIColor clearColor]];
		[choiceLabel setHighlightedTextColor:[UIColor whiteColor]];
		//[choiceLabel setTextAlignment:UITextAlignmentLeft];
		[choiceLabel setTextAlignment:UITextAlignmentRight];
		[choiceLabel setTextColor:[UIColor colorWithRed:0.20f green:0.31f blue:0.52f alpha:1.0f]];
		
		if (nil != backgroundColor) 
			[choiceLabel setBackgroundColor:backgroundColor];

		cell.view = choiceLabel;
		[choiceLabel release];
	}
	
    return cell;
}

#pragma mark IFCellControllerFirstResponder
-(void)assignFirstResponderHost: (NSObject<IFCellControllerFirstResponderHost> *)hostIn
{
	[self setCellControllerFirstResponderHost: hostIn];
}

-(void)becomeFirstResponder
{
	@try {
		autoAdvance = YES;
		[self tableView:(UITableView *)tableController.view didSelectRowAtIndexPath: self.cellIndexPath];
	}
	@catch (NSException *ex) {
		NSLog(@"unable to become first responder");
	}
}

-(void)resignFirstResponder
{

	NSLog(@"resign first responder is noop for choice cells");
}

@end
