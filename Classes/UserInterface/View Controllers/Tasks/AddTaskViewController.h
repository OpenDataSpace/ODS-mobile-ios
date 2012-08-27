//
//  AddTaskViewController.h
//  FreshDocs
//
//  Created by Tijs Rademakers on 17/08/2012.
//  Copyright (c) 2012 U001b. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Person.h"

@interface AddTaskViewController : UITableViewController

@property (nonatomic, retain) NSDate *dueDate;
@property (nonatomic, retain) Person *assignee;

@end
