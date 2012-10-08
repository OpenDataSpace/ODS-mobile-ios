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
//  TaskAssigneesViewController.m
//

#import "TaskAssigneesViewController.h"
#import "Person.h"
#import "PersonTableViewCell.h"
#import "AvatarHTTPRequest.h"
#import "ASIDownloadCache.h"
#import "PeoplePickerViewController.h"

@interface TaskAssigneesViewController () <UITableViewDataSource, UITableViewDelegate, PeoplePickerDelegate>

@property (nonatomic, retain) NSString *accountUuid;
@property (nonatomic, retain) NSString *tenantID;
@property (nonatomic, retain) UITableView *tableView;

// See https://issues.alfresco.com/jira/browse/MOBILE-719
@property (nonatomic) BOOL isViewAlreadyShown;

@end

@implementation TaskAssigneesViewController

@synthesize assignees = _assignees;
@synthesize isMultipleSelection = _isMultipleSelection;
@synthesize accountUuid = _accountUuid;
@synthesize tenantID = _tenantID;
@synthesize tableView = _tableView;
@synthesize isViewAlreadyShown = _isViewAlreadyShown;


- (id)initWithAccount:(NSString *)uuid tenantID:(NSString *)tenantID
{
    self = [super init];
    if (self) {
        self.accountUuid = uuid;
        self.tenantID = tenantID;
        self.isViewAlreadyShown = NO;
    }
    return self;
}

- (void)dealloc
{
    [_accountUuid release];
    [_tenantID release];
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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

     // See https://issues.alfresco.com/jira/browse/MOBILE-719
    // Need to remove this view controller again when popping back ...
    if (self.isViewAlreadyShown)
    {
        if ([self.navigationController viewControllers].count == 1)
        {
            [self dismissModalViewControllerAnimated:YES];
        }
        else
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    else
    {
        self.isViewAlreadyShown = YES;
    }
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
