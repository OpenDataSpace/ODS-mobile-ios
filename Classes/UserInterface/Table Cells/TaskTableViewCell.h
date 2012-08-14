//
//  TaskTableViewCell.h
//  FreshDocs
//
//  Created by Tijs Rademakers on 10/08/2012.
//  Copyright (c) 2012 . All rights reserved.
//

#import <Foundation/Foundation.h>

@class TaskItem;

@interface TaskTableViewCell : UITableViewCell

@property (nonatomic, retain) TaskItem *task;
@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UILabel *summaryLabel;
@property (nonatomic, retain) UILabel *dueDateLabel;

@end
