//
//  TaskTableCellController.m
//  FreshDocs
//
//  Created by Tijs Rademakers on 10/08/2012.
//  Copyright (c) 2012 . All rights reserved.
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

- (UITableViewCell *) createCell {
    TaskTableViewCell *cell = [[[TaskTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:[self cellIdentifier]] autorelease];
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.font = [self titleFont];
    
    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.font = [self subTitleFont];
    
    return cell;
}

- (void) populateCell: (UITableViewCell *) cell{    
    cell.textLabel.text = title;
	cell.textLabel.textColor = self.titleTextColor;
    cell.textLabel.highlightedTextColor = [UIColor whiteColor];
	cell.detailTextLabel.text = subtitle;
	cell.detailTextLabel.textColor = self.subtitleTextColor;
    cell.detailTextLabel.highlightedTextColor = [UIColor whiteColor];
    
    TaskTableViewCell *attCell = (TaskTableViewCell *) cell;
    [attCell setTask:self.task];
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
		cell = [self createCell];
	}
	
	if (selectionTarget && [selectionTarget respondsToSelector:selectionAction]) {
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	} 
    
    if (accessoryView) { 
        [cell setAccessoryView:[self makeDetailDisclosureButton]];
    } else {
        [cell setAccessoryView:nil];
        cell.accessoryType = accesoryType;
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
    
    if(accesoryType != UITableViewCellAccessoryNone) {
        maxWidth -= 20.0f;
    }
	
    if (title && ![title isEqualToString:@""])
		titleSize = [title sizeWithFont:[UIFont boldSystemFontOfSize:CONST_textLabelFontSize]
                      constrainedToSize:CGSizeMake(maxWidth, maxHeight) 
                          lineBreakMode:UILineBreakModeWordWrap];
    
	if (subtitle && ![subtitle isEqualToString:@""])
		subtitleSize = [subtitle sizeWithFont:[self subTitleFont] 
							constrainedToSize:CGSizeMake(maxWidth, maxHeight) 
								lineBreakMode:UILineBreakModeWordWrap];
	
	int height = 20 + titleSize.height + subtitleSize.height;
	CGFloat myCellHeight = (height < CONST_Cell_height ? CONST_Cell_height : height);
	if (saving) {
		cellHeight = myCellHeight;
	}
	return myCellHeight;
}

@end
