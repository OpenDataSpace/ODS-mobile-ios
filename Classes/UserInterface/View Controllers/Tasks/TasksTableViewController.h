//
//  TasksTableViewController.h
//  FreshDocs
//
//  Created by Tijs Rademakers on 10/08/2012.
//  Copyright (c) 2012 . All rights reserved.
//

#import "IFGenericTableViewController.h"
#import "ASIHTTPRequest.h"
#import "MBProgressHUD.h"
#import "DownloadProgressBar.h"
#import "TaskManager.h"
#import "CMISServiceManager.h"
#import "EGORefreshTableHeaderView.h"

@class TaskListHTTPRequest;
@class TaskItem;

@interface TasksTableViewController : IFGenericTableViewController <EGORefreshTableHeaderDelegate, MBProgressHUDDelegate, TaskManagerDelegate>

@property (nonatomic, retain) MBProgressHUD *HUD;
@property (nonatomic, retain) TaskListHTTPRequest *tasksRequest;
@property (nonatomic, retain) TaskItem *selectedTask;
@property (nonatomic, retain) NSString *cellSelection;
@property (nonatomic, retain) EGORefreshTableHeaderView *refreshHeaderView;
@property (nonatomic, retain) NSDate *lastUpdated;

@end
