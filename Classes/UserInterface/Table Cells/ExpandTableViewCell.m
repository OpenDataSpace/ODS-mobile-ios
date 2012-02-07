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
//  ExpandTableViewCell.m
//

#import "ExpandTableViewCell.h"

@implementation ExpandTableViewCell
@synthesize textLabel;
@synthesize imageView;
@synthesize expandView;
@synthesize isExpanded;
@synthesize expandTarget;
@synthesize expandAction;
@synthesize indexPath;

- (void)dealloc {
    [textLabel release];
    [imageView release];
    [expandView release];
    [indexPath release];
    
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    float indentPoints = self.indentationLevel * self.indentationWidth;
    
    self.contentView.frame = CGRectMake(
                                        indentPoints,
                                        self.contentView.frame.origin.y,
                                        self.contentView.frame.size.width - indentPoints, 
                                        self.contentView.frame.size.height
                                        );
}

- (IBAction)expandButtonTap:(id)sender {
    if(![expandView isHidden] && expandTarget) {
        isExpanded = !isExpanded;
        if(expandTarget && [expandTarget respondsToSelector:expandAction]) {
            [expandTarget performSelector:expandAction withObject:self];
        }
    }
}

- (void)setIsExpanded:(BOOL)newExpanded 
{
    isExpanded = newExpanded;
    if(isExpanded) [expandView setImage:[UIImage imageNamed:kTwisterOpenIcon_ImageName] forState:UIControlStateNormal];
    if(!isExpanded) [expandView setImage:[UIImage imageNamed:kTwisterClosedIcon_ImageName] forState:UIControlStateNormal];
}

@end

NSString * const kExpandCellIdentifier = @"ExpandCellIdentifier";
