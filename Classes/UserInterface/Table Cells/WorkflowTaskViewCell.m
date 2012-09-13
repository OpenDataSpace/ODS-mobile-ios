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

#define MARGIN_ASSIGNEE_PICTURE 10.0
#define MARGIN_ASSIGNEE_NAME 5.0

@interface WorkflowTaskViewCell ()

@property (nonatomic, retain) UILabel *dueDateFieldLabel;
@property (nonatomic, retain) UILabel *commentFieldLabel;

@end


@implementation WorkflowTaskViewCell

@synthesize assigneePicture = _assigneePicture;
@synthesize assigneeFullName = _assigneeFullName;
@synthesize taskTitleLabel = _taskTitleLabel;
@synthesize dueDateLabel = _dueDateLabel;
@synthesize commentTextView = _commentTextView;
@synthesize dueDateFieldLabel = _dueDateFieldLabel;
@synthesize commentFieldLabel = _commentFieldLabel;


- (void)dealloc
{
    [_assigneePicture release];
    [_assigneeFullName release];
    [_taskTitleLabel release];
    [_dueDateLabel release];
    [_commentTextView release];
    [_dueDateFieldLabel release];
    [_commentFieldLabel release];
    [super dealloc];
}


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.backgroundColor = [UIColor whiteColor];

        // Assignee picture
        AsyncLoadingUIImageView *assigneeImageView = [[AsyncLoadingUIImageView alloc] init];
        [assigneeImageView setContentMode:UIViewContentModeScaleToFill];
        [assigneeImageView.layer setMasksToBounds:YES];
        [assigneeImageView.layer setCornerRadius:10];
        assigneeImageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        assigneeImageView.layer.borderWidth = 1.0;
        self.assigneePicture = assigneeImageView;
        [self.contentView addSubview:self.assigneePicture];
        [assigneeImageView release];

        // Assignee name
        UITextView *assigneeName = [[UITextView alloc] init];
        assigneeName.font = [UIFont systemFontOfSize:12];
        assigneeName.textColor = [UIColor darkGrayColor];
        assigneeName.textAlignment = UITextAlignmentCenter;
        assigneeName.editable = NO;
        self.assigneeFullName = assigneeName;
        [self.contentView addSubview:self.assigneeFullName];
        [assigneeName release];

        // Task name
        UILabel *taskTitleLabel = [[UILabel alloc] init];
        taskTitleLabel.font = [UIFont systemFontOfSize:20];
        self.taskTitleLabel = taskTitleLabel;
        [self.contentView addSubview:self.taskTitleLabel];
        [taskTitleLabel release];

        // Due date
        UILabel *dueDateFieldLabel = [[UILabel alloc] init];
        dueDateFieldLabel.text = NSLocalizedString(@"workflow.task.duedate", nil);
        dueDateFieldLabel.font = [UIFont boldSystemFontOfSize:12];
        self.dueDateFieldLabel = dueDateFieldLabel;
        [self.contentView addSubview:self.dueDateFieldLabel];
        [dueDateFieldLabel release];

        UILabel *dueDateLabel = [[UILabel alloc] init];
        dueDateLabel.font = [UIFont systemFontOfSize:12];
        self.dueDateLabel = dueDateLabel;
        [self.contentView addSubview:self.dueDateLabel];
        [dueDateLabel release];

        // Comment
        UILabel *commentFieldLabel = [[UILabel alloc] init];
        commentFieldLabel.font = [UIFont boldSystemFontOfSize:12];
        commentFieldLabel.text = NSLocalizedString(@"workflow.task.comment", nil);
        self.commentFieldLabel = commentFieldLabel;
        [self.contentView addSubview:self.commentFieldLabel];
        [commentFieldLabel release];

        UITextView *commentTextView = [[UITextView alloc] init];
        commentTextView.font = [UIFont systemFontOfSize:12];
        commentTextView.editable = NO;
        self.commentTextView = commentTextView;
        [self.contentView addSubview:self.commentTextView];
        [commentTextView release];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect assigneePictureFrame = CGRectMake(MARGIN_ASSIGNEE_PICTURE, MARGIN_ASSIGNEE_PICTURE, 60, 60);
    self.assigneePicture.frame = assigneePictureFrame;

    CGRect assigneeNameFrame = CGRectMake(MARGIN_ASSIGNEE_NAME,
            assigneePictureFrame.origin.y + assigneePictureFrame.size.height + 1,
            assigneePictureFrame.size.width + (2 *(MARGIN_ASSIGNEE_PICTURE - MARGIN_ASSIGNEE_NAME)), 40);
    self.assigneeFullName.frame = assigneeNameFrame;
    self.assigneeFullName.backgroundColor = [UIColor blueColor];

    CGFloat taskTitleX = assigneeNameFrame.origin.x + assigneeNameFrame.size.width + 10;
    CGRect taskTitleFrame = CGRectMake(taskTitleX,assigneePictureFrame.origin.y,
            self.contentView.frame.size.width - taskTitleX - 20, 20);
    self.taskTitleLabel.frame = taskTitleFrame;
    [self.taskTitleLabel appendDotsIfTextDoesNotFit];

    CGSize dueDateFieldSize = [self.dueDateFieldLabel.text sizeWithFont:self.dueDateFieldLabel.font];
    CGRect dueDateFieldFrame = CGRectMake(taskTitleX, taskTitleFrame.origin.y + taskTitleFrame.size.height + 5,
            dueDateFieldSize.width, dueDateFieldSize.height);
    self.dueDateFieldLabel.frame = dueDateFieldFrame;

    CGFloat dueDateX = dueDateFieldFrame.origin.x + dueDateFieldFrame.size.width + 2;
    CGRect dueDateFrame = CGRectMake(dueDateX, dueDateFieldFrame.origin.y,
            self.contentView.frame.size.width - dueDateX, dueDateFieldSize.height);
    self.dueDateLabel.frame = dueDateFrame;

    CGSize commentFieldSize = [self.commentFieldLabel.text sizeWithFont:self.commentFieldLabel.font];
    CGRect commentFieldFrame = CGRectMake(taskTitleX, dueDateFieldFrame.origin.y + dueDateFieldFrame.size.height + 2,
            commentFieldSize.width, commentFieldSize.height);
    self.commentFieldLabel.frame = commentFieldFrame;

    CGFloat commentTextX = commentFieldFrame.origin.x + commentFieldFrame.size.width;
    CGRect commentTextFrame = CGRectMake(commentTextX, commentFieldFrame.origin.y,
            self.contentView.frame.size.width - commentTextX - 20, 40);
    self.commentTextView.frame = commentTextFrame;
}


@end
