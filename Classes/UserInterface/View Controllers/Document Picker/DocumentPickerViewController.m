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
#import "RepositoryInfo.h"
#import "DocumentPickerSiteTableDelegate.h"
#import "ThemeProperties.h"
#import "RepositoryItem.h"
#import "DocumentPickerRepositoryItemTableDelegate.h"
#import "DocumentPickerSelection.h"

#define SITE_TYPE_SELECTION_HEIGHT 40
#define SITE_TYPE_SELECTION_DEFAULT_SELECTED_SEGMENT 0
#define SITE_TYPE_SELECTION_HORIZONTAL_MARGIN 30
#define SITE_TYPE_SELECTION_VERTICAL_MARGIN 5

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
@property (nonatomic, retain) UISegmentedControl *siteTypeSegmentedControl;
@property (nonatomic, retain) UITableView *tableView;

@end

@implementation DocumentPickerViewController

@synthesize state = _state;
@synthesize tableView = _tableView;
@synthesize tableDelegate = _tableDelegate;
@synthesize siteTypeSegmentedControl = _siteTypeSegmentedControl;


#pragma mark View controller lifecycle

- (void)dealloc
{
    [_tableView release];
    [_tableDelegate release];
    [_siteTypeSegmentedControl release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    CGFloat currentHeight = 0;

    // Site type selection control
    if (self.state == DocumentPickerStateShowingSites)
    {
        currentHeight += [self createSiteTypeSegmentControl:currentHeight];
    }

    // Table view
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, currentHeight, self.view.frame.size.width, self.view.frame.size.height)];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    tableView.delegate = self.tableDelegate;
    tableView.dataSource = self.tableDelegate;

    self.tableView = tableView;
    [self.view addSubview:tableView];
    [tableView release];
    [self.tableDelegate tableViewDidLoad:tableView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // The delegate may now async load the data
    [self.tableDelegate loadDataForTableView:self.tableView];

    // Deselect any selected cell (needed when going back in the view hierarchy)
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

#pragma mark Getters and Setters

- (DocumentPickerSelection *)selection
{
    // If none was set by the user, create a default one
    if (_selection == nil)
    {
        DocumentPickerSelection *defaultSelection = [[DocumentPickerSelection alloc] init];
        self.selection = defaultSelection;
        [defaultSelection release];
    }
    return _selection;
}

#pragma mark Site Type selection bar above table

- (CGFloat)createSiteTypeSegmentControl:(CGFloat)currentHeight
{
    // Simple UIView as background
    UIView *background = [[UIView alloc] initWithFrame:CGRectMake(0, currentHeight, self.view.frame.size.width, SITE_TYPE_SELECTION_HEIGHT)];
    background.backgroundColor = [ThemeProperties segmentedControlBkgColor];
    [self.view addSubview:background];
    [background release];

    // The segment control
    UISegmentedControl *siteTypeSegmentedControl = [[UISegmentedControl alloc]
            initWithItems:[NSArray arrayWithObjects:NSLocalizedString(@"root.favsites.sectionheader", @"Favorite Sites"),
                                                    NSLocalizedString(@"root.mysites.sectionheader", @"My Sites"),
                                                    NSLocalizedString(@"root.allsites.sectionheader", @"All Sites"), nil]];
    siteTypeSegmentedControl.frame =  CGRectMake(SITE_TYPE_SELECTION_HORIZONTAL_MARGIN,
            currentHeight + SITE_TYPE_SELECTION_VERTICAL_MARGIN,
            self.view.frame.size.width - 2 * SITE_TYPE_SELECTION_HORIZONTAL_MARGIN,
            SITE_TYPE_SELECTION_HEIGHT - 2 * SITE_TYPE_SELECTION_VERTICAL_MARGIN);
    siteTypeSegmentedControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    siteTypeSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    [siteTypeSegmentedControl setTintColor:[ThemeProperties segmentedControlColor]];
    [siteTypeSegmentedControl setBackgroundColor:[ThemeProperties segmentedControlBkgColor]];

    [siteTypeSegmentedControl setSelectedSegmentIndex:SITE_TYPE_SELECTION_DEFAULT_SELECTED_SEGMENT];

    [siteTypeSegmentedControl addTarget:self action:@selector(siteTypeSelectionChanged) forControlEvents:UIControlEventValueChanged];
    [self siteTypeSelectionChanged]; // Otherwise nothing is shown

    self.siteTypeSegmentedControl = siteTypeSegmentedControl;
    [self.view addSubview:self.siteTypeSegmentedControl];
    [siteTypeSegmentedControl release];

    return SITE_TYPE_SELECTION_HEIGHT;
}

- (void)siteTypeSelectionChanged
{
    // We can safely cast, because the site type selection is only shown when this delegate is used
    DocumentPickerSiteTableDelegate *delegate = (DocumentPickerSiteTableDelegate *) self.tableDelegate;
    switch (self.siteTypeSegmentedControl.selectedSegmentIndex)
    {
        case 0:
            delegate.siteTypeToDisplay = DocumentPickerSiteTypeFavoriteSites;
            break;
        case 1:
            delegate.siteTypeToDisplay = DocumentPickerSiteTypeMySites;
            break;
        case 2:
            delegate.siteTypeToDisplay = DocumentPickerSiteTypeAllSites;
            break;
        default:
            NSLog(@"Something went wrong. You shouldn't come here. Probably a programmatic error");
            break;
    }
    [delegate loadDataForTableView:self.tableView];
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
    documentPickerViewController.title = delegate.titleForTable;

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

+ (DocumentPickerViewController *)documentPickerForRepository:(RepositoryInfo *)repositoryInfo
{
    DocumentPickerSiteTableDelegate *delegate = [[[DocumentPickerSiteTableDelegate alloc] initWithRepositoryInfo:repositoryInfo] autorelease];
    return [self documentPickerWithState:DocumentPickerStateShowingSites andWithDelegate:delegate];
}

+ (DocumentPickerViewController *)documentPickerForRepositoryItem:(RepositoryItem *)repositoryItem accountUuid:(NSString *)accountUuid tenantId:(NSString *)tenantId
{
    DocumentPickerRepositoryItemTableDelegate *delegate = [[[DocumentPickerRepositoryItemTableDelegate alloc] initWitRepositoryItem:repositoryItem accountUuid:accountUuid tenantId:tenantId] autorelease];
    return [self documentPickerWithState:DocumentPickerStateShowingSite andWithDelegate:delegate];
}

@end
