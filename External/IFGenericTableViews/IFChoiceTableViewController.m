//
//  IFChoiceTableViewController.m
//  Thunderbird
//
//  Created by Craig Hockenberry on 1/29/09.
//  Copyright 2009 The Iconfactory. All rights reserved.
//

#import "IFChoiceTableViewController.h"

#import "IFNamedImage.h"
#import "IFLabelValuePair.h"

@implementation IFChoiceTableViewController

@synthesize updateAction;
@synthesize updateTarget;
@synthesize footerNote;
@synthesize choices;
@synthesize model, key;
@synthesize selectionOptional, separator;
@synthesize backgroundColor;
@synthesize selectionStyle;

- (void)dealloc
{
	[choices release];
	[model release];
	[key release];
	
	[footerNote release];
	
	[separator release];
	
	[backgroundColor release];
	
    [super dealloc];
}

- (id)initWithStyle:(UITableViewStyle)style {
	selectionStyle = UITableViewCellSelectionStyleBlue;
	return [super initWithStyle:style];
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

- (BOOL)isChoiceValueSelected:(id)choice
{
	if (nil == choice) return NO;
	NSString *modelValue = [[model objectForKey:key] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	if (nil == modelValue || 0 == [modelValue length]) return NO;
	NSString *valueForChoice = [self valueForChoice:choice];
	if (nil == valueForChoice || 0 == [valueForChoice length]) return NO;
	
	if (nil != separator) {
		for (NSString *modelItem in [modelValue componentsSeparatedByString:separator]) {
			if ([modelItem isEqualToString:valueForChoice]) return YES;
		}
	} else if ([modelValue isEqualToString:valueForChoice]) {
		return YES;
	}
	
	return NO;
}

- (void)deselectChoice:(id)choice
{
	if (nil == choice) return;
	NSString *modelValue = [[model objectForKey:key] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	if (nil == modelValue || 0 == [modelValue length]) return;
	
	if (nil != separator) {
		NSString *valueForChoice = [self valueForChoice:choice];
		if (nil == valueForChoice || 0 == [valueForChoice length]) return;
		NSString *sep = @"";
		NSMutableString *selectedChoices = [NSMutableString string];
		for (NSString *modelItem in [modelValue componentsSeparatedByString:separator]) {
			if (![modelItem isEqualToString:valueForChoice] && ![[modelItem stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]) {
				[selectedChoices appendString:sep];
				[selectedChoices appendString:modelItem];
				sep = separator;
			}
		}
		
		if ([selectedChoices length] > 0) {
			[model setObject:((NSString *)selectedChoices) forKey:key];
		} else {
			[model setObject:nil forKey:key];
		}
	} else {
		[model setObject:nil forKey:key];
	}

}
		
- (void)selectChoice:(id)choice
{
	if (nil == choice) return;
	NSString *modelValue = [[model objectForKey:key] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	if (nil == modelValue) modelValue = @"";
	NSString *valueForChoice = [self valueForChoice:choice];
	BOOL choiceSelected = NO;
	
	if (nil != separator) {
		NSString *sep = @"";
		NSMutableString *selectedChoices = [NSMutableString string];
		for (NSString *modelItem in [modelValue componentsSeparatedByString:separator]) {
			if (![[modelItem stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]) {
				if ([modelItem isEqualToString:valueForChoice]) {
					choiceSelected = YES;
				}
				[selectedChoices appendString:sep];
				[selectedChoices appendString:modelItem];
				sep = separator;
			}
		}
		
		if (!choiceSelected) {
			[selectedChoices appendString:sep];
			[selectedChoices appendString:valueForChoice];
		}
		
		if ([selectedChoices length] > 0) {
			[model setObject:((NSString *)selectedChoices) forKey:key];
		} else {
			[model setObject:nil forKey:key];
		}
	} else {
		[model setObject:valueForChoice forKey:key];
	}
	
}

- (void)viewDidLoad {
    [super viewDidLoad];


	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [choices count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat result = 44.0f;
	
	NSUInteger row = [indexPath row];
	id choice = [choices objectAtIndex:row];
	if ([choice isKindOfClass:[IFNamedImage class]])
	{
		CGSize imageSize = [[choice image] size];
		if (imageSize.height < 44.0f)
		{
			result = 44.0f;
		}
		else
		{
			result = imageSize.height + 20.0f + 1.0f;
		}
	}

	return result;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	return footerNote;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"ChoiceSelectionCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
	{
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }
    
	[cell setSelectionStyle:selectionStyle];
	
	id choiceValue = [choices objectAtIndex:[indexPath row]];

	if ([choiceValue isKindOfClass:[NSString class]])
	{
		cell.textLabel.text = choiceValue;
		cell.imageView.image = nil;
	}
	else if ([choiceValue isKindOfClass:[IFNamedImage class]])
	{
		UIImage *image = [choiceValue image];
		CGSize imageSize = [image size];
		
		cell.imageView.image = image;
		if (imageSize.width < 44.0f)
		{
			cell.textLabel.text = [choiceValue name];
		}
		else
		{
			cell.textLabel.text = nil;
		}
	}
	else if ([choiceValue isKindOfClass:[IFLabelValuePair class]])
	{
		cell.textLabel.text = [choiceValue pairLabel];
		cell.imageView.image = nil;
	}
	else
	{
		cell.imageView.image = nil;
		cell.textLabel.text = nil;
	}
	
	if ([self isChoiceValueSelected: choiceValue])
	{
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
	else
	{
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger row = [indexPath row];
	id choice = [choices objectAtIndex: row];
	
	if (selectionOptional && [self isChoiceValueSelected:choice]) {
		[self deselectChoice:choice];
	} else {
		[self selectChoice:choice];
	}

	if (updateTarget && [updateTarget respondsToSelector:updateAction])
	{
		[updateTarget performSelector:updateAction withObject:tableView];
	}

	for (NSIndexPath *visibleIndexPath in [tableView indexPathsForVisibleRows])
	{
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:visibleIndexPath];
		NSUInteger visibleRow = [visibleIndexPath row];
		id choice = [choices objectAtIndex:visibleRow];

		if ([self isChoiceValueSelected:choice])
		{
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		}
		else
		{
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (nil == separator) {
		UITableViewController *tableViewController = (UITableViewController *)tableView.dataSource;
		[tableViewController.navigationController popViewControllerAnimated:YES];
	}
}

@end

