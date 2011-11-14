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
 * Portions created by the Initial Developer are Copyright (C) 2011
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  VersionHistoryCellController.m
//

#import "VersionHistoryCellController.h"
#import "RepositoryItem.h"

#define kCellHeight 44.0f
#define kTextLabelFontSize 11
#define kDetailLabelFontSize 15

@interface VersionHistoryCellController (private)
    - (UIButton *)makeDetailDisclosureButton;
@end

@implementation VersionHistoryCellController
@synthesize repositoryItem;
@synthesize selectionType;
@synthesize accesoryType;
@synthesize selectionStyle;
@synthesize accessoryView;
@synthesize tag;

- (void)dealloc {
    [super dealloc];
    [repositoryItem release];
    [accessoryView release];
}

-(id)initWithTitle:(NSString *)newTitle subtitle:(NSString *)newSubtitle {
    self = [super initWithTitle:newTitle andSubtitle:newSubtitle inModel:nil];
    if(self) {
        accesoryType = UITableViewCellAccessoryNone;
        selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return self;
}

- (UIFont *) titleFont {
	
	if (titleFont == nil) self.titleFont = [UIFont boldSystemFontOfSize:kDetailLabelFontSize];
	return titleFont;
	
}

- (UIColor *) titleTextColor {
	if(titleTextColor == nil) self.titleTextColor = [UIColor blackColor];
	return titleTextColor;
	
}

- (NSString *) cellIdentifier {
	return @"VersionHistoryCell";
}

- (UITableViewCell *) createCell {
    UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:[self cellIdentifier]] autorelease];
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.font = [self titleFont];
    
    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.font = [self subTitleFont];
    
    return cell;
}

- (CGSize) titleSize:(CGFloat)maxWidth andMaxHeight:(CGFloat)maxHeight {
    CGSize finalSize = {0.0f, 0.0f};
    
    if ([title length] > 0) {
        finalSize = [super titleSize:maxWidth andMaxHeight:maxHeight];
    } 
    
    return finalSize;
}

- (void) populateCell: (UITableViewCell *) cell{
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
    cell.textLabel.text = title;
	cell.textLabel.textColor = self.titleTextColor;
	cell.detailTextLabel.text = subtitle;
	cell.detailTextLabel.textColor = self.subtitleTextColor;
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
    self.selectionType = VersionHistoryRowSelection;
    if (selectionTarget && [selectionTarget respondsToSelector:selectionAction])
    {
        [selectionTarget performSelector:selectionAction withObject:self];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    self.selectionType = VersionHistoryAccessoryTapped;
    if (((accesoryType == UITableViewCellAccessoryDetailDisclosureButton) || accessoryView) 
        && selectionTarget && [selectionTarget respondsToSelector:selectionAction])
    {
        [selectionTarget performSelector:selectionAction withObject:self];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

@end
