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
//  AccountTableViewCell.m
//

#import "AccountTableViewCell.h"

CGFloat const kAccountWarningWidth = 22.0f;
CGFloat const kAccountWarningHeight = 23.0f;
CGFloat const kAccountWarningPadding = 4.0f;
//That's the approximate padding in the edges, between the cell image and the textLabel, etc.
CGFloat const kAccountCellPadding = 20.0f;

@implementation AccountTableViewCell
@synthesize warningView = _warningView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        UIImageView *warningView = [[[UIImageView alloc] initWithImage:nil] autorelease];
        [warningView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin];
        CGRect cellRect = [self.contentView frame];
        CGFloat yCenter = cellRect.size.height / 2 - kAccountWarningHeight / 2;
        [warningView setFrame:CGRectMake(cellRect.size.width - kAccountWarningWidth - kAccountWarningPadding, yCenter, kAccountWarningWidth, kAccountWarningHeight)];
        [self.contentView addSubview:warningView];
        [self setWarningView:warningView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect contentRect = [self.contentView frame];
    CGRect textFrame = [self.textLabel frame];
    CGFloat maxTextWidth = contentRect.size.width - kAccountWarningWidth - kAccountWarningPadding - self.imageView.frame.size.width - kAccountCellPadding;
    // No need to resize if the textLabel is within the max width of the textLabel
    if(maxTextWidth < textFrame.size.width)
    {
        textFrame.size.width = maxTextWidth;
        [self.textLabel setFrame:textFrame];
    }
}

@end
