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
//  TaskTableCellController.m
//

#import "TaskTableCellController.h"
#import "TaskTableViewCell.h"
#import "TTTAttributedLabel.h"

NSString * const kTaskCellRowSelection = @"row";
NSString * const kTaskCellDisclosureSelection = @"disclosure";

#define CONST_Cell_height 44.0f
#define CONST_textLabelFontSize 17
#define CONST_detailLabelFontSize 15

@implementation TaskTableCellController

@synthesize task;
@synthesize accesoryType;
@synthesize selectionType;
@synthesize selectionStyle;
@synthesize accessoryView;

- (void) dealloc {
    [task release];
    [selectionType release];
    [accessoryView release];
    [super dealloc];
}

- (id)init {
    self = [super init];
    if(self) {
        accesoryType = UITableViewCellAccessoryNone;
        selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return self;
}

- (id)initWithTitle:(NSString *)newTitle andSubtitle:(NSString *)newSubtitle inModel:(id<IFCellModel>)newModel {
    self = [super initWithTitle:newTitle andSubtitle:newSubtitle inModel:newModel];
    if(self) {
        accesoryType = UITableViewCellAccessoryNone;
        selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return self;
}

- (void) populateCell: (UITableViewCell *) cell{    
    TaskTableViewCell *attCell = (TaskTableViewCell *) cell;
    [attCell setTask:self.task];
    attCell.titleLabel.highlightedTextColor = [UIColor whiteColor];
    attCell.summaryLabel.textColor = self.titleTextColor;
    attCell.summaryLabel.highlightedTextColor = [UIColor whiteColor];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.tableController = (UITableViewController *)tableView.dataSource;
	self.cellIndexPath = indexPath;
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[self cellIdentifier]];
	if (cell == nil)
	{
		cell = [[[TaskTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:[self cellIdentifier]] autorelease];
	}
    
    cell.selectionStyle = selectionStyle;
	cell.backgroundColor = self.backgroundColor;
    
	[self populateCell:cell];	
	CGFloat testHeight = [self heightForSelfSavingHieght:NO withMaxWidth:tableView.frame.size.width];
	
	if (cellHeight != testHeight) {
		[self performSelector:@selector(reloadCell) withObject:nil afterDelay:0.1f];
	}
    
    return cell;
}

- (UIButton *)makeDetailDisclosureButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeInfoDark];
    [button addTarget:self action:@selector(accessoryButtonTapped:withEvent:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)accessoryButtonTapped:(UIControl *)button withEvent:(UIEvent *)event
{
    NSIndexPath * indexPath = [self.tableController.tableView indexPathForRowAtPoint:[[[event touchesForView:button] anyObject] locationInView:self.tableController.tableView]];
    if ( indexPath == nil )
        return;
    [self tableView:self.tableController.tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectionType = kTaskCellRowSelection;
    if (selectionTarget && [selectionTarget respondsToSelector:selectionAction])
    {
        [selectionTarget performSelector:selectionAction withObject:self withObject:self.selectionType];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    self.selectionType = kTaskCellDisclosureSelection;
    if (((accesoryType == UITableViewCellAccessoryDetailDisclosureButton) || accessoryView) 
        && selectionTarget && [selectionTarget respondsToSelector:selectionAction])
    {
        [selectionTarget performSelector:selectionAction withObject:self withObject:self.selectionType];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (NSString *) cellIdentifier {
    return @"TasksTableCellController";
}

- (CGFloat)heightForSelfSavingHieght:(BOOL)saving withMaxWidth: (CGFloat) maxWidth
{
	CGFloat maxHeight = 4000;
    
    //Remove padding, etc
    maxWidth -= 80.0f;
	
	CGSize titleSize    = {0.0f, 0.0f};
	CGSize subtitleSize = {0.0f, 0.0f};
    
    
    if (title && ![title isEqualToString:@""])
		titleSize = [title sizeWithFont:[UIFont boldSystemFontOfSize:CONST_textLabelFontSize]
                      constrainedToSize:CGSizeMake(maxWidth, maxHeight) 
                          lineBreakMode:UILineBreakModeWordWrap];
    
	if (subtitle && ![subtitle isEqualToString:@""])
		subtitleSize = [subtitle sizeWithFont:[self subTitleFont] 
							constrainedToSize:CGSizeMake(maxWidth, maxHeight) 
								lineBreakMode:UILineBreakModeWordWrap];
	
	int height = 40 + titleSize.height + subtitleSize.height;
	CGFloat myCellHeight = (height < CONST_Cell_height ? CONST_Cell_height : height);
	if (saving) {
		cellHeight = myCellHeight;
	}
	return myCellHeight;
}

@end
