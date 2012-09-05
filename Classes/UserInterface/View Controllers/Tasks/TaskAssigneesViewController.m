//
//  TaskAssigneesViewController.m
//  FreshDocs
//
//  Created by Tijs Rademakers on 04/09/2012.
//  Copyright (c) 2012 U001b. All rights reserved.
//

#import "TaskAssigneesViewController.h"
#import "Person.h"
#import "PersonTableViewCell.h"
#import "AvatarHTTPRequest.h"
#import "AsyncLoadingUIImageView.h"
#import "ASIDownloadCache.h"
#import "PeoplePickerViewController.h"

@interface TaskAssigneesViewController () <UITableViewDataSource, UITableViewDelegate, PeoplePickerDelegate>

@property (nonatomic, retain) NSString *accountUuid;
@property (nonatomic, retain) NSString *tenantID;
@property (nonatomic, retain) UITableView *tableView;

@end

@implementation TaskAssigneesViewController

@synthesize assignees = _assignees;
@synthesize isMultipleSelection = _isMultipleSelection;
@synthesize accountUuid = _accountUuid;
@synthesize tenantID = _tenantID;
@synthesize tableView = _tableView;

- (id)initWithAccount:(NSString *)uuid tenantID:(NSString *)tenantID
{
    self = [super init];
    if (self) {
        self.accountUuid = uuid;
        self.tenantID = tenantID;
    }
    return self;
}

- (void)dealloc
{
    [_assignees release];
    [_tableView release];
    [super dealloc];
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.isMultipleSelection)
    {
        self.navigationItem.title = NSLocalizedString(@"task.create.assignees", nil);
    }
    else 
    {
        self.navigationItem.title = NSLocalizedString(@"task.create.assignee", nil);
    }
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"task.create.attachment.edit", nil)
                                                                               style:UIBarButtonItemStyleDone target:self action:@selector(editButtonTapped)] autorelease];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:
                              CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    tableView.delegate = self;
    tableView.dataSource = self;
    
    self.tableView = tableView;
    [self.view addSubview:tableView];
    
    [tableView release];
}

-(void)editButtonTapped
{
    [self.tableView setEditing:!self.tableView.editing animated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Reload data when navigation controller is popped to this one again.
    [self.tableView reloadData];
}

#pragma mark Table View delegate / datasource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return 1;
    }
    else 
    {
        return self.assignees.count;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (indexPath.section == 0)
    {
        static NSString *CellIdentifier = @"SelectCell";
        cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil)
        {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        }
        
        if (self.isMultipleSelection)
        {
            cell.textLabel.text = NSLocalizedString(@"task.create.assignees.select", nil);
        }
        else 
        {
            cell.textLabel.text = NSLocalizedString(@"task.create.assignee.select", nil);
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else 
    {
        static NSString *CellIdentifier = @"PersonCell";
        cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil)
        {
            cell = [[[PersonTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.shouldIndentWhileEditing = NO;
        
        Person *person = [self.assignees objectAtIndex:indexPath.row];
        
        ((PersonTableViewCell *) cell).personLabel.text = [NSString stringWithFormat:@"%@ %@", (person.firstName != nil)
                                 ? person.firstName : @"", (person.lastName != nil) ? person.lastName : @"" ];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        if (person.userName)
        {
            // Set url for async loading of assignee avatar picture
            AvatarHTTPRequest *avatarHTTPRequest = [AvatarHTTPRequest
                                                    httpRequestAvatarForUserName:person.userName
                                                    accountUUID:self.accountUuid
                                                    tenantID:self.tenantID];
            avatarHTTPRequest.secondsToCache = 86400; // a day
            avatarHTTPRequest.downloadCache = [ASIDownloadCache sharedCache];
            [avatarHTTPRequest setCachePolicy:ASIOnlyLoadIfNotCachedCachePolicy];
            [((PersonTableViewCell *) cell).personImageView setImageWithRequest:avatarHTTPRequest];
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        PeoplePickerViewController *peoplePicker = [[PeoplePickerViewController alloc] initWithAccount:self.accountUuid tenantID:self.tenantID];
        peoplePicker.selection = self.assignees;
        peoplePicker.isMultipleSelection = self.isMultipleSelection;
        peoplePicker.delegate = self;
        
        [self.navigationController pushViewController:peoplePicker animated:YES];
        [peoplePicker release];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == 1;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [self.assignees removeObjectAtIndex:indexPath.row];
        
        [tableView reloadData];
        
        if (self.assignees.count == 0)
        {
            [self.tableView setEditing:NO animated:YES];
        }
    }
}

#pragma mark - PeoplePicker delegate

- (void)personsPicked:(NSArray *)persons
{
    self.assignees = [NSMutableArray arrayWithArray:persons];
}

@end
