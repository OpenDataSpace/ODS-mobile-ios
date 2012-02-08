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
//  CommentTableViewCell.m
//

#import "CommentTableViewCell.h"

@implementation CommentTableViewCell

@synthesize createdDateLabel;

- (void)dealloc {
	[createdDateLabel release];
    [super dealloc];
}
         
- (UILabel *) createdDateLabel {
    if(createdDateLabel == nil) {
        createdDateLabel = [[[UILabel alloc] init] retain];
        [self.contentView addSubview:createdDateLabel];
    }
    
    return createdDateLabel;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect cellBounds = [self.contentView bounds];
    CGRect titleBounds = [self.textLabel bounds];
    CGFloat indentation = ([self indentationLevel] + 1) * [self indentationWidth];
    CGSize maximumLabelSize = CGSizeMake(cellBounds.size.width,cellBounds.size.height);
    CGSize expectedLabelSize = [self.createdDateLabel.text sizeWithFont:self.createdDateLabel.font
                                      constrainedToSize:maximumLabelSize 
                                          lineBreakMode:self.createdDateLabel.lineBreakMode];
    
    self.createdDateLabel.frame = CGRectMake(cellBounds.size.width - expectedLabelSize.width - indentation, titleBounds.origin.y + indentation, expectedLabelSize.width, expectedLabelSize.height);
    
    //self.createdDateLabel.frame = titleBounds;

}

- (void)willTransitionToState:(UITableViewCellStateMask)state
{
    [super willTransitionToState:state];
    
    if ((state & UITableViewCellStateDefaultMask) == UITableViewCellStateDefaultMask)
    {
        self.createdDateLabel.hidden = NO;
        
        [UIView beginAnimations:@"anim" context:nil];
        self.createdDateLabel.alpha = 1;
        [UIView commitAnimations];
    }
    
    if ((state & UITableViewCellStateShowingDeleteConfirmationMask) == UITableViewCellStateShowingDeleteConfirmationMask)
    {
        self.createdDateLabel.hidden = YES;
        self.createdDateLabel.alpha = 0;
        
        /*for (UIView *subview in self.subviews)
        {
            if ([NSStringFromClass([subview class]) isEqualToString:@"UITableViewCellDeleteConfirmationControl"])
            {
                subview.hidden = YES;
                subview.alpha = 0;
            }
        }*/
    }
}

- (void)didTransitionToState:(UITableViewCellStateMask)state
{
    [super willTransitionToState:state];
    
    
    
    if ((state & UITableViewCellStateShowingDeleteConfirmationMask) == UITableViewCellStateShowingDeleteConfirmationMask)
    {        
        for (UIView *subview in self.subviews)
        {
            if ([NSStringFromClass([subview class]) isEqualToString:@"UITableViewCellDeleteConfirmationControl"])
            {
                //[subview.subviews setBackgroundColor: [UIColor blueColor]];
            }
        }
    }
}

@end

NSString * const kCommentCellIdentifier = @"CommentCellIdentifier";
