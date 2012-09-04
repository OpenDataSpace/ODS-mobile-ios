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
//  PersonTableViewCell.m
//

#import "PersonTableViewCell.h"
#import <QuartzCore/QuartzCore.h>

#define MARGIN 5

@implementation PersonTableViewCell

@synthesize personImageView = _personImageView;
@synthesize personLabel = _personLabel;

- (void)dealloc
{
    [_personImageView release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil;
    }
    
    self.personImageView = [[[AsyncLoadingUIImageView alloc] init] autorelease];
    [self.personImageView setContentMode:UIViewContentModeScaleAspectFill];
    [self.personImageView.layer setMasksToBounds:YES];
    [self.personImageView.layer setCornerRadius:10];
    self.personImageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.personImageView.layer.borderWidth = 1.0;
    self.personImageView.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.personImageView];
    
    self.personLabel = [[[UILabel alloc] init] autorelease];
    self.personLabel.font = [UIFont boldSystemFontOfSize:18];
    self.personLabel.lineBreakMode = UILineBreakModeWordWrap;
    self.personLabel.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.personLabel];
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    // Picture
    CGSize contentViewSize = self.contentView.frame.size;
    CGFloat pictureSize = contentViewSize.height - (2 * MARGIN);
    CGRect pictureFrame = CGRectMake(MARGIN, MARGIN, pictureSize, pictureSize);
    self.personImageView.frame = pictureFrame;

    CGFloat x = pictureFrame.origin.x + pictureFrame.size.width + 2 * MARGIN;
    
    // Name
    self.personLabel.frame = CGRectMake(x, MARGIN, contentViewSize.width - x - MARGIN, pictureSize);
}


@end
