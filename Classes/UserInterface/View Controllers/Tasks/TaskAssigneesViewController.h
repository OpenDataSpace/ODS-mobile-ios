//
//  TaskAssigneesViewController.h
//  FreshDocs
//
//  Created by Tijs Rademakers on 04/09/2012.
//  Copyright (c) 2012 U001b. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TaskAssigneesViewController : UIViewController

@property (nonatomic, retain) NSMutableArray *assignees;
@property (nonatomic) BOOL isMultipleSelection;

- (id)initWithAccount:(NSString *)uuid tenantID:(NSString *)tenantID;

@end
