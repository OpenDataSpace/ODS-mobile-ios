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
// WorkflowTaskViewCell 
//
#import <QuartzCore/QuartzCore.h>
#import "WorkflowTaskViewCell.h"
#import "AsyncLoadingUIImageView.h"
#import "UILabel+Utils.h"
#import "TTTAttributedLabel.h"

#define MARGIN_ASSIGNEE_PICTURE 20.0

@interface WorkflowTaskViewCell ()

@property (nonatomic, retain) UIView *background;

@end


@implementation WorkflowTaskViewCell

@synthesize assigneePicture = _assigneePicture;
@synthesize taskTextLabel = _taskTextLabel;
@synthesize iconImageView = _iconImageView;
@synthesize background = _background;


- (void)dealloc
{
    [_assigneePicture release];
    [_taskTextLabel release];
    [_iconImageView release];
    [_background release];
    [super dealloc];
}


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.backgroundColor = [UIColor whiteColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        // Background
        UIView *background = [[UIView alloc] init];
        background.layer.cornerRadius = 10.0;
        background.layer.masksToBounds = YES;
        background.layer.borderColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.4].CGColor;
        background.layer.borderWidth = 1.0;
        self.background = background;
        [background release];
        [self.contentView addSubview:self.background];

        // Assignee picture
        AsyncLoadingUIImageView *assigneeImageView = [[AsyncLoadingUIImageView alloc] init];
        [assigneeImageView setContentMode:UIViewContentModeScaleToFill];
        [assigneeImageView.layer setMasksToBounds:YES];
        [assigneeImageView.layer setCornerRadius:10.0];
        assigneeImageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        assigneeImageView.layer.borderWidth = 1.0;
        self.assigneePicture = assigneeImageView;
        [self.contentView addSubview:self.assigneePicture];
        [assigneeImageView release];

        // Task text
        TTTAttributedLabel *taskTextLabel = [[TTTAttributedLabel alloc] init];
        taskTextLabel.font = [UIFont systemFontOfSize:13];
        taskTextLabel.lineBreakMode = UILineBreakModeWordWrap;
        taskTextLabel.numberOfLines = 0;
        taskTextLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentCenter;
        self.taskTextLabel = taskTextLabel;
        [self.contentView addSubview:self.taskTextLabel];
        [taskTextLabel release];

        // Icon
        UIImageView *icon = [[UIImageView alloc] init];
        self.iconImageView = icon;
        [self.contentView addSubview:self.iconImageView];
        [icon release];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    // Background
    self.background.frame = CGRectMake(10, 10, self.contentView.frame.size.width - 30, self.contentView.frame.size.height - 20);

    // Assignee
    CGFloat picSize = 60.0;
    CGRect assigneePictureFrame = CGRectMake(MARGIN_ASSIGNEE_PICTURE, (self.contentView.frame.size.height - picSize) / 2, picSize, picSize);
    self.assigneePicture.frame = assigneePictureFrame;

    // Icon
    if (self.iconImageView.image)
    {
        self.iconImageView.frame = CGRectMake(assigneePictureFrame.origin.x + assigneePictureFrame.size.width + 5,
                assigneePictureFrame.origin.y + ((assigneePictureFrame.size.height - self.iconImageView.image.size.height) / 2) ,
                self.iconImageView.image.size.width, self.iconImageView.image.size.height);
    }

    // Text
    CGFloat textX = assigneePictureFrame.origin.x + assigneePictureFrame.size.width + 40;
    CGRect textFrame = CGRectMake(textX, assigneePictureFrame.origin.y,
            self.contentView.frame.size.width - textX - 40, assigneePictureFrame.size.height);
    self.taskTextLabel.frame = textFrame;

}

@end
