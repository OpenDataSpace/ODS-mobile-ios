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
//  FDChoiceCellController.m
//

#import "FDChoiceCellController.h"

@implementation FDChoiceCellController
@synthesize customAction = _customAction;
@synthesize target = _target;
@synthesize action = _action;

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
    
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
        [cell.textLabel setBackgroundColor:[UIColor clearColor]];
        CGRect frame = CGRectMake(0.0f, 0.0f, 0, 22.0f);
		UILabel *choiceLabel = [[UILabel alloc] initWithFrame:frame];
		[choiceLabel setFont:[UIFont systemFontOfSize:17.0f]];
		[choiceLabel setBackgroundColor:[UIColor clearColor]];
		[choiceLabel setHighlightedTextColor:[UIColor whiteColor]];
        [choiceLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
		//[choiceLabel setTextAlignment:UITextAlignmentLeft];
		[choiceLabel setTextAlignment:UITextAlignmentRight];
		[choiceLabel setTextColor:[UIColor colorWithRed:0.20f green:0.31f blue:0.52f alpha:1.0f]];
        [choiceLabel setTag:100];
		
		//if (nil != backgroundColor)
		//	[choiceLabel setBackgroundColor:backgroundColor];
        

        [cell.contentView addSubview:choiceLabel];
        [cell.contentView bringSubviewToFront:choiceLabel];
		[choiceLabel release];		
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
    UILabel *choiceLabel = (UILabel *)[cell.contentView viewWithTag:100];
	if (nil == modelValue) {
		[choiceLabel setText:nil];
	}
	
	// otherwise based on the type of selection we determine
	// what to show
	else {
        NSString *choiceLabelText = [self labelForValue:modelValue];
        [choiceLabel setText:choiceLabelText];
	}
    
    CGRect valueFrame = choiceLabel.frame;
    
    // Getting the title label size
    CGSize labelSize = [label sizeWithFont:cell.textLabel.font];
    CGFloat tableviewWidth = tableView.frame.size.width;
    CGFloat groupedMargin = tableView.style == UITableViewStyleGrouped ? [self groupedCellMarginWithTableWidth:tableviewWidth] : 0;
    CGFloat cellWidth = cell.contentView.frame.size.width;
    CGFloat viewWidth = cellWidth - (labelSize.width + (0.0f * indentationLevel) + (groupedMargin * 2));
    
    valueFrame.size.width = viewWidth;
    valueFrame.origin.x = cellWidth - viewWidth - 8.0f;
    valueFrame.origin.y = floorf((cell.contentView.frame.size.height - valueFrame.size.height) / 2.0f);
    [choiceLabel setFrame:valueFrame];
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.customAction && [self.target respondsToSelector:self.action])
    {
        [self.target performSelector:self.action withObject:self];
    }
    else
    {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

//From: http://stackoverflow.com/questions/4708085/how-to-determine-margin-of-a-grouped-uitableview-or-better-how-to-set-it
- (float)groupedCellMarginWithTableWidth:(float)tableViewWidth
{
    float marginWidth;
    if(tableViewWidth > 20)
    {
        if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone || tableViewWidth < 400)
        {
            marginWidth = 10;
        }
        else
        {
            marginWidth = MAX(31, MIN(45, tableViewWidth*0.06));
        }
    }
    else
    {
        marginWidth = tableViewWidth - 10;
    }
    return marginWidth;
}

@end
