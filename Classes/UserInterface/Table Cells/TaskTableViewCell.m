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

static CGFloat const kSummaryTextFontSize = 17;

@implementation TaskTableViewCell

@synthesize task = _task;
@synthesize summaryLabel = _summaryLabel;

- (void)dealloc {
    [_summaryLabel release];
    [_task release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil; 
    }
    
    self.summaryLabel = [[[TTTAttributedLabel alloc] initWithFrame:CGRectZero] autorelease];
    self.summaryLabel.font = [UIFont systemFontOfSize:kSummaryTextFontSize];
    self.summaryLabel.lineBreakMode = UILineBreakModeWordWrap;
    self.summaryLabel.numberOfLines = 0;
    self.summaryLabel.shadowColor = [UIColor colorWithWhite:0.87 alpha:1.0];
    self.summaryLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
    
    [self.contentView addSubview:self.summaryLabel];
    
    return self;
}

- (void)setTask:(TaskItem *)task {
    [self.summaryLabel setText:task.description];
}

#pragma mark - UIView

- (void)layoutSubviews {
    [super layoutSubviews];
    self.textLabel.hidden = YES;
    
    self.summaryLabel.frame = self.textLabel.frame;
}
@end
