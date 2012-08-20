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
// AccountSelectionViewController 
//
#import "DocumentPickerViewController.h"
#import "AccountManager.h"

#import "DocumentPickerAccountTableDelegate.h"
#import "DocumentPickerRepositoryTableDelegate.h"

typedef enum {
    DocumentPickerStateShowingAccounts,
    DocumentPickerStateShowingRepositories,
    DocumentPickerStateShowingSites,
    DocumentPickerStateShowingSite
} DocumentPickerState;

@interface DocumentPickerViewController ()

@property DocumentPickerState state;

// Table delegate
@property (nonatomic, retain) id<DocumentPickerTableDelegate> tableDelegate;

// View
@property (nonatomic, retain) UITableView *tableView;

@end

@implementation DocumentPickerViewController

@synthesize state = _state;
@synthesize tableView = _tableView;
@synthesize tableDelegate = _tableDelegate;

#pragma mark View controller lifecycle

- (void)dealloc
{
    [_tableView release];
    [_tableDelegate release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Table view
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    tableView.delegate = self.tableDelegate;
    tableView.dataSource = self.tableDelegate;

    self.tableView = tableView;
    [self.view addSubview:tableView];
    [tableView release];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // The delegate may now async load the data
    [self.tableDelegate loadDataForTableView:self.tableView];
}

#pragma mark View controller creation methods

- (id)initWithTableDelegate:(id <DocumentPickerTableDelegate>)tableDelegate
{
    self = [super init];
    if (self)
    {
        _tableDelegate = [tableDelegate retain];
    }
    return self;
}

+ (DocumentPickerViewController *)documentPickerWithState:(DocumentPickerState)state
                                          andWithDelegate:(id<DocumentPickerTableDelegate>)delegate
{
    DocumentPickerViewController *documentPickerViewController =
            [[[DocumentPickerViewController alloc] initWithTableDelegate:delegate] autorelease];
    documentPickerViewController.state = state;

    delegate.documentPickerViewController = documentPickerViewController;

    return documentPickerViewController;
}

+ (DocumentPickerViewController *)documentPicker
{
    DocumentPickerAccountTableDelegate *delegate = [[[DocumentPickerAccountTableDelegate alloc] init] autorelease];
    return [self documentPickerWithState:DocumentPickerStateShowingAccounts andWithDelegate:delegate];
}

+ (DocumentPickerViewController *)documentPickerForAccount:(AccountInfo *)accountInfo
{
    DocumentPickerRepositoryTableDelegate *delegate = [[[DocumentPickerRepositoryTableDelegate alloc] initWithAccount:accountInfo] autorelease];
    return [self documentPickerWithState:DocumentPickerStateShowingRepositories andWithDelegate:delegate];
}

@end
