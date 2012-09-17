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
//  FavoritesErrorsViewController.m
//

#import "FavoritesErrorsViewController.h"
#import "FavoriteManager.h"
#import "Utility.h"
#import "FavoriteFileDownloadManager.h"

@interface FavoritesErrorsViewController ()

@property (nonatomic, retain) NSMutableDictionary *errorDictionary;
@property (nonatomic, retain) NSMutableDictionary *sectionHeaders;

- (NSString *)keyForSection:(NSInteger)section;
- (NSInteger)calculateHeaderHeightForSection:(NSInteger)section;
- (void)handleSyncObstacles;
- (void)reloadTableView;
- (NSInteger)numberOfPopulatedErrorArrays;

@end

@implementation FavoritesErrorsViewController

@synthesize tableView = _tableView;
@synthesize errorDictionary = _errorDictionary;
@synthesize sectionHeaders = _sectionHeaders;

- (id)initWithErrors:(NSMutableDictionary *)errors
{
    self = [super init];
    if (self)
    {
        self.errorDictionary = errors;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *dismissButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                   target:self
                                                                                   action:@selector(dismissModalView)];
    [self.navigationItem setRightBarButtonItem:dismissButton];
    [dismissButton release];
    
    [self.navigationItem setTitle:NSLocalizedString(@"favorite-errors.title", @"Favorite's Error Navigation Bar Title")];
    
    self.sectionHeaders = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"favorite-errors.unfavorited-on-server-with-local-changes.header",
                                                                      @"favorite-errors.deleted-on-server-with-local-changes.header", nil]
                                                             forKeys:[NSArray arrayWithObjects:kDocumentsUnfavoritedOnServerWithLocalChanges, kDocumentsDeletedOnServerWithLocalChanges, nil]];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self handleSyncObstacles];
}

- (void)dealloc
{
    [_tableView release];
    [_errorDictionary release];
    [_sectionHeaders release];
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Private Class functions

- (void)dismissModalView
{
    [self dismissModalViewControllerAnimated:YES];
}

- (NSString *)keyForSection:(NSInteger)sectionNumber
{
    NSString *key = nil;
    switch (sectionNumber)
    {
        case 0:
            key = kDocumentsUnfavoritedOnServerWithLocalChanges;
            break;
            
        case 1:
            key = kDocumentsDeletedOnServerWithLocalChanges;
            break;
            
        default:
            break;
    }
    return key;
}

- (NSInteger)calculateHeaderHeightForSection:(NSInteger)section
{
    NSString *key = [self keyForSection:section];
    if ([[self.errorDictionary objectForKey:key] count] != 0)
    {
        NSString *headerText = NSLocalizedString([self.sectionHeaders objectForKey:key], @"TableView Header Section Descriptions");
        return [headerText sizeWithFont:[UIFont systemFontOfSize:14.0f] constrainedToSize:CGSizeMake(320, 2000) lineBreakMode:UILineBreakModeWordWrap].height;
    }
    return 0;
}

- (void)handleSyncObstacles
{
    NSArray *syncObstacles = [self.errorDictionary objectForKey:kDocumentsDeletedOnServerWithLocalChanges];
    for (NSString *fileName in syncObstacles)
    {
        [[FavoriteManager sharedManager] saveDeletedFavoriteFileBeforeRemovingFromSync:fileName];
    }    
}

- (void)reloadTableView
{
    NSInteger numberOfPopulatedErrorArrays = [self numberOfPopulatedErrorArrays];
    
    if (numberOfPopulatedErrorArrays == 0)
    {
        [self dismissModalView];
    }
    
    [self.tableView reloadData];
}

- (NSInteger)numberOfPopulatedErrorArrays
{
    NSArray *allKeys = [self.errorDictionary allKeys];
    int numberOfPopulatedErrorArrays = 0;
    for (NSString *key in allKeys)
    {
        NSArray *errorArray = [self.errorDictionary objectForKey:key];
        if ([errorArray count] > 0)
        {
            numberOfPopulatedErrorArrays++;
        }
    }
    return numberOfPopulatedErrorArrays;
}

#pragma mark - UITableViewDataSourceDelegate functions

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.errorDictionary allKeys] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *key = [self keyForSection:section];
    return [[self.errorDictionary objectForKey:key] count];;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *standardCellIdentifier = @"StandardCellIdentifier";
    static NSString *favoritesErrorCellIdentifier = @"FavoritesErrorCellIdentifier";
    
    UITableViewCell *standardCell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:standardCellIdentifier];
    FavoritesErrorTableViewCell *favoritesErrorCell = (FavoritesErrorTableViewCell *)[tableView dequeueReusableCellWithIdentifier:favoritesErrorCellIdentifier];
    
    if (!standardCell)
    {
        standardCell = (UITableViewCell *)[[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:standardCellIdentifier] autorelease];
        standardCell.imageView.contentMode = UIViewContentModeCenter;
    }
    
    if (!favoritesErrorCell)
    {
        NSArray *nibItems = [[NSBundle mainBundle] loadNibNamed:@"FavoritesErrorTableViewCell" owner:self options:nil];
        favoritesErrorCell = (FavoritesErrorTableViewCell *)[nibItems objectAtIndex:0];
        favoritesErrorCell.delegate = self;
        [favoritesErrorCell.syncButton setBackgroundImage:[[UIImage imageNamed:@"blue-button-30.png"] stretchableImageWithLeftCapWidth:5 topCapHeight:5] forState:UIControlStateNormal];
        [favoritesErrorCell.saveButton setBackgroundImage:[[UIImage imageNamed:@"blue-button-30.png"] stretchableImageWithLeftCapWidth:5 topCapHeight:5] forState:UIControlStateNormal];
        NSAssert(nibItems, @"Failed to load object from NIB");
    }
    
    NSString *key = [self keyForSection:indexPath.section];
    NSArray *currentErrorArray = [self.errorDictionary objectForKey:key];
    NSString *currentFileName = [[[FavoriteFileDownloadManager sharedInstance] downloadInfoForFilename:[currentErrorArray objectAtIndex:indexPath.row]] objectForKey:@"filename"];
    
    if ([key isEqualToString:kDocumentsDeletedOnServerWithLocalChanges])
    {
        standardCell.selectionStyle = UITableViewCellSelectionStyleNone;
        standardCell.textLabel.font = [UIFont systemFontOfSize:17.0f];
        standardCell.textLabel.text = currentFileName;
        standardCell.imageView.image = imageForFilename([currentErrorArray objectAtIndex:indexPath.row]);
        
        return standardCell;
    }

    favoritesErrorCell.selectionStyle = UITableViewCellSelectionStyleNone;
    favoritesErrorCell.fileNameTextLabel.text = currentFileName;
    favoritesErrorCell.imageView.image = imageForFilename([currentErrorArray objectAtIndex:indexPath.row]);
    
    return favoritesErrorCell;
}

#pragma mark - UITableViewDelegate Functions

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *key = [self keyForSection:section];
    NSArray *syncErrors = [self.errorDictionary objectForKey:key];
    if ([syncErrors count] > 0)
    {
        int horizontalMargin = 10;
        int verticalMargin = 10;
        
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, [self calculateHeaderHeightForSection:section])];
        
        headerView.backgroundColor = [UIColor clearColor];
        headerView.contentMode = UIViewContentModeScaleAspectFit;
        headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(horizontalMargin, verticalMargin, tableView.frame.size.width - (horizontalMargin * 2), [self calculateHeaderHeightForSection:section] - (verticalMargin * 2))];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;;
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = UITextAlignmentCenter;
        label.lineBreakMode = UILineBreakModeWordWrap;
        label.numberOfLines = 0;
        label.font = [UIFont systemFontOfSize:14.0f];
        
        label.text = NSLocalizedString([self.sectionHeaders objectForKey:key], @"TableView Header Section Descriptions");
        
        [headerView addSubview:label];
        [label release];
        
        return [headerView autorelease];
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self calculateHeaderHeightForSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0f;
}

#pragma mark - FavoritesErrorTableViewDelegate Functions

- (void)didPressSyncButton:(UIButton *)syncButton
{
    FavoritesErrorTableViewCell *cell = (FavoritesErrorTableViewCell *)syncButton.superview.superview;
    NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
    // key for section
    NSString *key = [self keyForSection:cellIndexPath.section];
    NSArray *currentErrorArray = [self.errorDictionary objectForKey:key];
    // file name
    NSString *fileNameInCell = [currentErrorArray objectAtIndex:cellIndexPath.row];
    [[FavoriteManager sharedManager] syncUnfavoriteFileBeforeRemovingFromSync:fileNameInCell syncToServer:YES];
    [self reloadTableView];
}

- (void)didPressSaveToDownloadsButton:(UIButton *)saveButton
{
    FavoritesErrorTableViewCell *cell = (FavoritesErrorTableViewCell *)saveButton.superview.superview;
    NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
    // key for section
    NSString *key = [self keyForSection:cellIndexPath.section];
    NSArray *currentErrorArray = [self.errorDictionary objectForKey:key];
    // file name
    NSString *fileNameInCell = [currentErrorArray objectAtIndex:cellIndexPath.row];
    [[FavoriteManager sharedManager] syncUnfavoriteFileBeforeRemovingFromSync:fileNameInCell syncToServer:NO];
    [self reloadTableView];
}

@end
