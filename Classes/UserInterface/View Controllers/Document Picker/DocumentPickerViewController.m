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
#import "CoolButton.h"

#define SITE_TYPE_SELECTION_HEIGHT 40
#define SITE_TYPE_SELECTION_DEFAULT_SELECTED_SEGMENT 0
#define SITE_TYPE_SELECTION_HORIZONTAL_MARGIN 30
#define SITE_TYPE_SELECTION_VERTICAL_MARGIN 5
#define BUTTON_BACKGROUND_HEIGHT 40
#define BUTTON_HEIGHT 30
#define BUTTON_WIDTH  200

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
@property (nonatomic, retain) UIView *siteTypeSelectionBackgroundView;
@property (nonatomic, retain) UISegmentedControl *siteTypeSegmentedControl;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) UIView *buttonBackground;
@property (nonatomic, retain) UIButton *finishSelectionButton;
@property (nonatomic, retain) UIButton *deselectAllButton;

@end

@implementation DocumentPickerViewController

@synthesize state = _state;
@synthesize tableView = _tableView;
@synthesize tableDelegate = _tableDelegate;
@synthesize siteTypeSegmentedControl = _siteTypeSegmentedControl;
@synthesize selection = _selection;
@synthesize finishSelectionButton = _finishSelectionButton;
@synthesize buttonBackground = _buttonBackground;
@synthesize siteTypeSelectionBackgroundView = _siteTypeSelectionBackgroundView;
@synthesize deselectAllButton = _deselectAllButton;


#pragma mark View controller lifecycle

- (void)dealloc
{
    [_tableView release];
    [_tableDelegate release];
    [_siteTypeSegmentedControl release];
    [_selection release];
    [_finishSelectionButton release];
    [_buttonBackground release];
    [_siteTypeSelectionBackgroundView release];
    [_deselectAllButton release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self createCancelButton];

    CGFloat currentHeight = 0;

    // Site type selection control
    if (self.state == DocumentPickerStateShowingSites)
    {
        currentHeight += [self createSiteTypeSegmentControl:currentHeight];
    }

    [self createTableView:currentHeight];
    [self createFinishSelectionButton];
    [self createDeselectAllButton];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // The delegate may now async load the data
    [self.tableDelegate loadDataForTableView:self.tableView];

    // Deselect any selected cell (needed when going back in the view hierarchy)
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];

    // Always reload the data, as things might have changed in the model back-end
    [self selectionDidUpdate];
    [self.tableView reloadData];
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

#pragma mark UI creation

- (void)createCancelButton
{
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelDocumentPicker)];
    cancelButton.title = NSLocalizedString(@"document.picker.cancel", nil);
    self.navigationItem.rightBarButtonItem = cancelButton;
    [cancelButton release];
}

- (void)cancelDocumentPicker
{
    // Simply pop all instances of this class from the navigation controller
    int index = self.navigationController.viewControllers.count - 1;
    while (index >= 0 && [[self.navigationController.viewControllers objectAtIndex:index] isKindOfClass:[DocumentPickerViewController class]])
    {
        index--;
    }

    [self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:index] animated:YES];
}

- (CGFloat)createSiteTypeSegmentControl:(CGFloat)currentHeight
{
    // Simple UIView as background
    UIView *background = [[UIView alloc] init];
    background.backgroundColor = [ThemeProperties segmentedControlBkgColor];
    self.siteTypeSelectionBackgroundView = background;
    [self.view addSubview:self.siteTypeSelectionBackgroundView];
    [background release];

    // The segment control
    UISegmentedControl *siteTypeSegmentedControl = [[UISegmentedControl alloc]
            initWithItems:[NSArray arrayWithObjects:NSLocalizedString(@"root.favsites.sectionheader", @"Favorite Sites"),
                                                    NSLocalizedString(@"root.mysites.sectionheader", @"My Sites"),
                                                    NSLocalizedString(@"root.allsites.sectionheader", @"All Sites"), nil]];
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


- (void)createTableView:(CGFloat)currentHeight
{
    UITableView *tableView = [[UITableView alloc] init];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    tableView.delegate = self.tableDelegate;
    tableView.dataSource = self.tableDelegate;

    self.tableView = tableView;
    [self.view addSubview:tableView];
    [tableView release];
    [self.tableDelegate tableViewDidLoad:tableView];
}

- (void)createFinishSelectionButton
{
    // Background
    UIView *backgroundView = [[UIView alloc] init];
    backgroundView.backgroundColor = [ThemeProperties segmentedControlBkgColor];
    backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    self.buttonBackground = backgroundView;
    [self.view addSubview:self.buttonBackground];
    [backgroundView release];

    // Button
    CoolButton *finishSelectionButton = [[CoolButton alloc] init];
    [finishSelectionButton setTitle:self.selection.selectiontextPrefix forState:UIControlStateNormal];
    [finishSelectionButton setEnabled:NO];

    self.finishSelectionButton = finishSelectionButton;
    [finishSelectionButton release];

    [self.view addSubview:self.finishSelectionButton];
    [self selectionDidUpdate];
}

- (void)createDeselectAllButton
{
    CoolButton *deselectAllButton = [[CoolButton alloc] init];
    deselectAllButton.enabled = NO;
    deselectAllButton.buttonColor = [UIColor colorWithRed:0.70 green:0.08 blue:0.04 alpha:1.0];
    [deselectAllButton setTitle:NSLocalizedString(@"document.picker.deselectAll", nil) forState:UIControlStateNormal];
    [deselectAllButton addTarget:self action:@selector(deselectAllButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.deselectAllButton = deselectAllButton;
    [self.view addSubview:self.deselectAllButton];
    [deselectAllButton release];
}

- (void)deselectAllButtonPressed
{
    // Remove all selections from the model
    [self.selection clearAll];

    // Update UI's
    [self selectionDidUpdate];
    [self.tableView reloadData];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    // Site selection
    CGFloat currentHeight = 0;
    if (self.siteTypeSegmentedControl)
    {
        self.siteTypeSelectionBackgroundView.frame = CGRectMake(0, currentHeight, self.view.frame.size.width, SITE_TYPE_SELECTION_HEIGHT);
        self.siteTypeSegmentedControl.frame =  CGRectMake(SITE_TYPE_SELECTION_HORIZONTAL_MARGIN,
                currentHeight + SITE_TYPE_SELECTION_VERTICAL_MARGIN,
                self.view.frame.size.width - 2 * SITE_TYPE_SELECTION_HORIZONTAL_MARGIN,
                SITE_TYPE_SELECTION_HEIGHT - 2 * SITE_TYPE_SELECTION_VERTICAL_MARGIN);
        currentHeight += SITE_TYPE_SELECTION_HEIGHT;
    }

    // TableView
    self.tableView.frame = CGRectMake(0, currentHeight, self.view.frame.size.width,
            self.view.frame.size.height - BUTTON_BACKGROUND_HEIGHT - currentHeight);

    // Finish selection button
    CGRect backgroundViewFrame = CGRectMake(0,
                   self.tableView.frame.origin.y + self.tableView.frame.size.height,
                   self.view.frame.size.width,
            BUTTON_BACKGROUND_HEIGHT);
    self.buttonBackground.frame = backgroundViewFrame;

    CGFloat margin = 20;
    CGFloat buttonWidth = (backgroundViewFrame.size.width - (3 * margin)) / 2;
    self.deselectAllButton.frame = CGRectMake(margin,
            backgroundViewFrame.origin.y + (backgroundViewFrame.size.height - BUTTON_HEIGHT) / 2,
            buttonWidth,
            BUTTON_HEIGHT);

    self.finishSelectionButton.frame = CGRectMake(
            self.deselectAllButton.frame.origin.x + self.deselectAllButton.frame.size.width + margin,
            self.deselectAllButton.frame.origin.y,
            BUTTON_WIDTH,
            BUTTON_HEIGHT);
}


#pragma mark Instance methods

- (void)selectionDidUpdate
{
    // Gather all the counts
    NSNumber *accountCount = [NSNumber numberWithInt:self.selection.selectedAccounts.count];
    NSNumber *repoCount = [NSNumber numberWithInt:self.selection.selectedRepositories.count];
    NSNumber *siteCount = [NSNumber numberWithInt:self.selection.selectedSites.count];
    NSNumber *folderCount = [NSNumber numberWithInt:self.selection.selectedFolders.count];
    NSNumber *documenCount = [NSNumber numberWithInt:self.selection.selectedDocuments.count];

    BOOL multipleItemsSelected = NO;
    uint totalCount  = 0;
    NSArray *counts = [NSArray arrayWithObjects:accountCount, repoCount, siteCount, folderCount, documenCount, nil];
    for (NSNumber *count in counts)
    {
        uint value = count.unsignedIntValue;
        if (count.unsignedIntValue > 0 && totalCount > 0)
        {
            multipleItemsSelected = YES;
        }
        totalCount += value;
    }

    // Change the button text depending on the counts
    NSString *itemText = @"";
    if (multipleItemsSelected)
    {
        itemText = totalCount > 1 ? NSLocalizedString(@"document.picker.items", nil) : NSLocalizedString(@"document.picker.item", nil);
    }
    else // only one type selected
    {
        if (accountCount.intValue > 0)
        {
            itemText = totalCount > 1 ? NSLocalizedString(@"document.picker.accounts", nil) : NSLocalizedString(@"document.picker.account", nil);
        }
        if (repoCount.intValue > 0)
        {
            itemText = totalCount > 1 ? NSLocalizedString(@"document.picker.repositories", nil) : NSLocalizedString(@"document.picker.repository", nil);
        }
        if (siteCount.intValue > 0)
        {
            itemText = totalCount > 1 ? NSLocalizedString(@"document.picker.sites", nil) : NSLocalizedString(@"document.picker.site", nil);
        }
        if (folderCount.intValue > 0)
        {
            itemText = totalCount > 1 ? NSLocalizedString(@"document.picker.folders", nil) : NSLocalizedString(@"document.picker.folder", nil);
        }
        if (documenCount.intValue > 0)
        {
            itemText = totalCount > 1 ? NSLocalizedString(@"document.picker.documents", nil) : NSLocalizedString(@"document.picker.document", nil);
        }
    }

    if (totalCount > 0)
    {
        self.deselectAllButton.enabled = YES;
        self.finishSelectionButton.enabled = YES;
        if (totalCount > 1)
        {
            [self.finishSelectionButton setTitle:[NSString stringWithFormat:@"%@ %d %@",
                  self.selection.selectiontextPrefix, totalCount, itemText] forState:UIControlStateNormal];
        }
        else
        {
            [self.finishSelectionButton setTitle:[NSString stringWithFormat:@"%@ %@",
                              self.selection.selectiontextPrefix, itemText] forState:UIControlStateNormal];
        }
    }
    else
    {
        self.deselectAllButton.enabled = NO;
        self.finishSelectionButton.enabled = NO;
        [self.finishSelectionButton setTitle:self.selection.selectiontextPrefix forState:UIControlStateNormal];
    }
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
