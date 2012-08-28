//
//  SelectTaskTypeViewController.m
//  FreshDocs
//
//  Created by Tijs Rademakers on 28/08/2012.
//  Copyright (c) 2012 U001b. All rights reserved.
//

#import "SelectTaskTypeViewController.h"
#import "AddTaskViewController.h"
#import "Theme.h"

@interface SelectTaskTypeViewController ()

@property (nonatomic, retain) NSString *accountUuid;
@property (nonatomic, retain) NSString *tenantID;

@end

@implementation SelectTaskTypeViewController

@synthesize accountUuid = _accountUuid;
@synthesize tenantID = _tenantID;

- (id)initWithStyle:(UITableViewStyle)style account:(NSString *)uuid tenantID:(NSString *)tenantID
{
    self = [super initWithStyle:style];
    if (self) {
        self.accountUuid = uuid;
        self.tenantID = tenantID;
    }
    return self;
}

- (void)dealloc
{
    [_accountUuid release];
    [_tenantID release];
    [super dealloc]; 
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [Theme setThemeForUITableViewController:self];
    [self setTitle:@"Choose task type"];
    
    [self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                             target:self
                                                                                             action:@selector(cancel:)] autorelease]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)cancel:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    if (indexPath.section == 0)
    {
        cell.textLabel.text = @"Todo";
    }
    else 
    {
        cell.textLabel.text = @"Review";
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoTaskType taskType;
    if (indexPath.section == 0)
    {
        taskType = TASK_TYPE_TODO;
    }
    else 
    {
        taskType = TASK_TYPE_REVIEW;
    }
    
    AddTaskViewController *taskController = [[AddTaskViewController alloc] initWithStyle:UITableViewStyleGrouped account:self.accountUuid 
                                                         tenantID:self.tenantID taskType:taskType];
    
    [self.navigationController pushViewController:taskController animated:YES];
}

@end
