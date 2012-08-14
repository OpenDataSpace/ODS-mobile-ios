//
//  TaskTableViewCell.m
//  FreshDocs
//
//  Created by Tijs Rademakers on 10/08/2012.
//  Copyright (c) 2012 . All rights reserved.
//

#import "TaskTableViewCell.h"
#import "TTTAttributedLabel.h"
#import "TaskItem.h"
#import "Utility.h"

static CGFloat const kTitleTextFontSize = 17;
static CGFloat const kSummaryTextFontSize = 15;
static CGFloat const maxWidth = 240;
static CGFloat const maxHeight = 4000;

@interface TaskTableViewCell ()

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) NSString *dueDateString;

@end

@implementation TaskTableViewCell

@synthesize task = _task;
@synthesize title = _title;
@synthesize description = _description;
@synthesize dueDateString = _dueDateString;
@synthesize titleLabel = _titleLabel;
@synthesize summaryLabel = _summaryLabel;
@synthesize dueDateLabel = _dueDateLabel;

- (void)dealloc {
    [_titleLabel release];
    [_summaryLabel release];
    [_dueDateLabel release];
    [_task release];
    [_title release];
    [_description release];
    [_dueDateString release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil; 
    }
    
    self.titleLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    self.titleLabel.font = [UIFont boldSystemFontOfSize:kTitleTextFontSize];
    [self.contentView addSubview:self.titleLabel];
    
    self.summaryLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    self.summaryLabel.font = [UIFont systemFontOfSize:kSummaryTextFontSize];
    self.summaryLabel.lineBreakMode = UILineBreakModeWordWrap;
    self.summaryLabel.numberOfLines = 0;
    self.summaryLabel.shadowColor = [UIColor colorWithWhite:0.87 alpha:1.0];
    self.summaryLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
    [self.contentView addSubview:self.summaryLabel];
    
    self.dueDateLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    self.dueDateLabel.font = [UIFont systemFontOfSize:kSummaryTextFontSize];
    [self.contentView addSubview:self.dueDateLabel];
    
    return self;
}

- (void)setTask:(TaskItem *)task {
    self.title = task.title;
    self.description = task.description;
    if (task.dueDate != nil)
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"dd MMM"];
        self.dueDateString = [dateFormatter stringFromDate:task.dueDate];
        
        [dateFormatter release];
    }
    else
    {
        self.dueDateString = @"No due date";
    }
    [self.titleLabel setText:self.title];
    [self.summaryLabel setText:self.description];
    [self.dueDateLabel setText:self.dueDateString];
}

#pragma mark - UIView

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize titleSize = [self.title sizeWithFont:[UIFont boldSystemFontOfSize:kTitleTextFontSize]
                              constrainedToSize:CGSizeMake(maxWidth, maxHeight) 
                                  lineBreakMode:UILineBreakModeWordWrap];
    
    self.titleLabel.frame = CGRectMake(30, 5, titleSize.width, titleSize.height);
    
    CGSize summarySize = [self.description sizeWithFont:[UIFont systemFontOfSize:kSummaryTextFontSize]
                                      constrainedToSize:CGSizeMake(maxWidth, maxHeight) 
                                          lineBreakMode:UILineBreakModeWordWrap];
    
    self.summaryLabel.frame = CGRectMake(30, 7 + titleSize.height, summarySize.width, summarySize.height);
    
    self.dueDateLabel.frame = CGRectMake(30, 9 + titleSize.height + summarySize.height, 150, 19);
}

@end
