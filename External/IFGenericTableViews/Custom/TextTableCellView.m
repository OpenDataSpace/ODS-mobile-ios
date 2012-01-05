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
//  TextTableCellView.m
//
// Created to fix the bug in the IFControlTableViewCell using it with the
// IFTextCellController where a resize in the tableView will lead to an
// Incorrect layout (presenting it in an ipad modal view)

#import "TextTableCellView.h"

#define kCellHorizontalOffset 8.0f

@implementation TextTableCellView

- (void)layoutSubviews
{	
	[super layoutSubviews];
    CGRect contentRect = [self.contentView bounds];
	CGRect viewRect = [view bounds];
    
    // NOTE: The documentation states that the indentation width is 10 "points". It's more like 20
	// pixels and changing the property has no effect on the indentation. We'll use 20.0f here
	// and cross our fingers that this doesn't screw things up in the future.
    CGFloat viewWidth;
	if (! self.textLabel.text || [self.textLabel.text length] == 0)
	{
		// there is no label, so use the entire width of the cell
		viewWidth = 280.0f - (20.0f * self.indentationLevel);
	}
	else
	{
        
        CGRect labelRect = [[self textLabel] textRectForBounds:[self.contentView frame] limitedToNumberOfLines:1];
        
		// use about half of the cell (this matches the metrics in the Settings app)
		CGFloat w = [self.contentView frame].size.width;
		if (w <	700.0f) {
			viewWidth = w - labelRect.size.width - 50.0f;
		} else {
			viewWidth = w - labelRect.size.width - 120.0f;
		}
	}
    
	CGRect viewFrame = CGRectMake(contentRect.size.width - viewWidth - kCellHorizontalOffset,
                                  floorf((contentRect.size.height - viewRect.size.height) / 2.0f),
                                  viewWidth,
                                  viewRect.size.height);
	view.frame = viewFrame;
}

@end
