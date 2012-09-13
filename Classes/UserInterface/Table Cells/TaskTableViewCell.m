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
//  TaskTableViewCell.m
//

#import "TaskTableViewCell.h"
#import "TTTAttributedLabel.h"
#import "TaskItem.h"
#import "Utility.h"
#import "ReadUnreadManager.h"
#import "UILabel+Utils.h"

static CGFloat const kTextFontSize = 15;
static CGFloat const maxWidth = 240;
static CGFloat const maxHeight = 40;

@interface TaskTableViewCell ()

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) NSString *dueDateString;
@property (nonatomic, retain) UIImageView *readStatusView;

@end

@implementation TaskTableViewCell

@synthesize task = _task;
@synthesize title = _title;
@synthesize description = _description;
@synthesize readStatusView = _readStatusView;
@synthesize dueDateString = _dueDateString;
@synthesize titleLabel = _titleLabel;
@synthesize summaryLabel = _summaryLabel;
@synthesize dueDateLabel = _dueDateLabel;
@synthesize priorityView = _priorityView;

- (void)dealloc
{
    [_titleLabel release];
    [_summaryLabel release];
    [_dueDateLabel release];
    [_priorityView release];
    [_readStatusView release];
    [_task release];
    [_title release];
    [_description release];
    [_dueDateString release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self)
    {
        return nil; 
    }
    
    self.readStatusView = [[[UIImageView alloc] initWithFrame:CGRectZero] autorelease];
    self.readStatusView.image = [UIImage imageNamed:@"UnreadTask.png"];
    [self.contentView addSubview:self.readStatusView];
    
    self.summaryLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    self.summaryLabel.font = [UIFont systemFontOfSize:kTextFontSize];
    self.summaryLabel.lineBreakMode = UILineBreakModeWordWrap;
    self.summaryLabel.numberOfLines = 2;
    self.summaryLabel.shadowColor = [UIColor colorWithWhite:0.87 alpha:1.0];
    self.summaryLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
    [self.contentView addSubview:self.summaryLabel];
    
    self.priorityView = [[[UIImageView alloc] initWithFrame:CGRectZero] autorelease];
    [self.contentView addSubview:self.priorityView];
    
    self.dueDateLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    self.dueDateLabel.font = [UIFont systemFontOfSize:kTextFontSize];
    [self.contentView addSubview:self.dueDateLabel];
    
    self.titleLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:kTextFontSize];
    [self.contentView addSubview:self.titleLabel];
    
    return self;
}

- (void)setTask:(TaskItem *)task
{
    if (task.workflowType == WORKFLOW_TYPE_TODO)
    {
        self.title = NSLocalizedString(@"task.list.todo", nil);
    }
    else 
    {
        self.title = NSLocalizedString(@"task.list.review", nil);
    }
    self.description = task.description;
    if (task.dueDate != nil)
    {
        // test if due date is not in the future
        if ([task.dueDate compare:[NSDate date]] != NSOrderedDescending)
        {
            [self.dueDateLabel setTextColor:[UIColor redColor]];
        }
        else 
        {
            [self.dueDateLabel setTextColor:[UIColor blackColor]];
        }
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"dd MMM"];
        self.dueDateString = [dateFormatter stringFromDate:task.dueDate];
        
        [dateFormatter release];
    }
    else
    {
        self.dueDateString = @"";
    }
    [self.titleLabel setText:self.title];
    [self.summaryLabel setText:self.description];
    [self.dueDateLabel setText:self.dueDateString];
    
    if (task.priorityInt == 1)
    {
        [self.priorityView setImage:[UIImage imageNamed:@"HighPriorityRightNav.png"]];
    }
    else if (task.priorityInt == 2)
    {
        [self.priorityView setImage:[UIImage imageNamed:@"MedPriorityRightNav.png"]];
    }
    else 
    {
        [self.priorityView setImage:[UIImage imageNamed:@"LowPriorityRightNav.png"]];
    }
    
    if (task.taskItemType == TASKITEM_TYPE_STARTEDBYME)
    {
        [self.readStatusView setHidden:YES];
    }
    else if ([[ReadUnreadManager sharedManager] readStatusForTaskId:task.taskId])
    {
        [self.readStatusView setHidden:YES];
    }
    else 
    {
        [self.readStatusView setHidden:NO];
    }
}

#pragma mark - UIView

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGSize summarySize = [self.description sizeWithFont:[UIFont systemFontOfSize:kTextFontSize]
                                      constrainedToSize:CGSizeMake(maxWidth, maxHeight) 
                                          lineBreakMode:UILineBreakModeWordWrap];
    self.summaryLabel.frame = CGRectMake(30, 7, summarySize.width, summarySize.height);
    [self.summaryLabel appendDotsIfTextDoesNotFit];

    CGSize dueDateSize = [self.dueDateString sizeWithFont:[UIFont systemFontOfSize:kTextFontSize]
                                      constrainedToSize:CGSizeMake(maxWidth, 20) 
                                          lineBreakMode:UILineBreakModeWordWrap];
    
    int leftMargin = 30;
    
    self.priorityView.frame = CGRectMake(leftMargin, 18 + summarySize.height, self.priorityView.image.size.width, self.priorityView.image.size.height);
    
    self.dueDateLabel.frame = CGRectMake(leftMargin + 10 + self.priorityView.image.size.width, 12 + summarySize.height, dueDateSize.width, 20);
    
    int titleMargin = 40;
    if (self.dueDateString.length > 0)
    {
        titleMargin = titleMargin + 10;
    }
    self.titleLabel.frame = CGRectMake(titleMargin + self.priorityView.image.size.width + dueDateSize.width, 
                                       12 + summarySize.height, maxWidth - dueDateSize.width - 75, 20);
    
    self.readStatusView.frame = CGRectMake(8, (summarySize.height + 32) / 2, self.readStatusView.image.size.width, self.readStatusView.image.size.height);

}

@end
