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
 *
 * ***** END LICENSE BLOCK ***** */
//
//  VideoUploadTableViewCell.m
//

#import "VideoUploadTableViewCell.h"

#define kCellOffsetDefault 5.0f
#define kCellVideoWidth .75

@implementation VideoUploadTableViewCell

@synthesize view;
@synthesize cellWidthOffset = _cellWidthOffset;
@synthesize cellHeightOffset = _cellHeightOffset;

- (CGFloat)cellWidthOffset
{
    if (!_cellWidthOffset)
    {
        _cellWidthOffset = kCellOffsetDefault;
    }
    return _cellWidthOffset;
}

- (CGFloat)cellHeightOffset
{
    if (!_cellHeightOffset)
    {
        _cellHeightOffset = 0.0f;
    }
    return _cellHeightOffset;
}

- (void)setView:(UIView *)newView
{
	[view removeFromSuperview];
    
	view = [newView retain];
	[self.contentView addSubview:view];
    maxHeight = view.bounds.size.height;
	
	[self layoutSubviews];
}

- (void)layoutSubviews
{	
	[super layoutSubviews];
    CGRect contentRect = [self.contentView bounds];
	CGRect viewRect = [view bounds];
    
    if(viewRect.size.width > contentRect.size.width * kCellVideoWidth)
    {
        CGFloat ratio = viewRect.size.height / viewRect.size.width;
        CGFloat newWidth = contentRect.size.width * kCellVideoWidth;
        CGFloat newHeight = newWidth * ratio;
        viewRect = CGRectMake(viewRect.origin.x, viewRect.origin.x, newWidth, newHeight);
        [view setFrame:viewRect];
    }
    else
    {
        CGFloat ratio = viewRect.size.width / viewRect.size.height;
        CGFloat newHeight = maxHeight;
        CGFloat newWidth = newHeight * ratio;
        viewRect = CGRectMake(viewRect.origin.x, viewRect.origin.x, newWidth, newHeight);
        [view setFrame:viewRect];
    }
    
	CGRect viewFrame = CGRectMake(contentRect.size.width - viewRect.size.width - [self cellWidthOffset],
                                  floorf((contentRect.size.height - viewRect.size.height - [self cellHeightOffset]) / 2.0f),
                                  viewRect.size.width,
                                  viewRect.size.height);
	view.frame = viewFrame;
}

- (void)dealloc
{
	[view release];
	
    [super dealloc];
}

@end
