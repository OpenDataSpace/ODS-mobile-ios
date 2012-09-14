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

@interface FavoritesErrorsViewController ()

@property (nonatomic, retain) NSMutableDictionary *errorDictionary;
@property (nonatomic, retain) NSMutableDictionary *sectionHeaders;

- (NSString *)keyForSection:(NSInteger)section;
- (NSInteger)calculateHeaderHeightForSection:(NSInteger)section;
- (void)handleSyncObsticles;

@end

@implementation FavoritesErrorsViewController

@synthesize tableView;
@synthesize errorDictionary;
@synthesize sectionHeaders;

- (id)initWithErrors:(NSMutableDictionary *)errors
{
    self = [super init];
    if (self) {
        self.errorDictionary = errors;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *dismissButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                   target:self
                                                                                   action:@selector(dismissModalView)];
    [self.navigationItem setRightBarButtonItem:dismissButton];
    [dismissButton release];
    
    [self.navigationItem setTitle:NSLocalizedString(@"favorite-errors.title", @"Favorite's Error Navigation Bar Title")];
    
    self.sectionHeaders = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"favorite-errors.unfavorited-on-server-with-local-changes.header",
                                                                      @"favorite-errors.deleted-on-server-with-local-changes.header", nil]
                                                             forKeys:[NSArray arrayWithObjects:kDocumentsUnfavoritedOnServerWithLocalChanges, kDocumentsDeletedOnServerWithLocalChanges, nil]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [self.tableView release], self.tableView = nil;
    [self.errorDictionary release], self.errorDictionary = nil;
    [self.sectionHeaders release], self.sectionHeaders = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self handleSyncObsticles];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)dealloc
{
    [self.tableView release];
    [self.errorDictionary release];
    [self.sectionHeaders release];
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
    NSString *key;
    switch (sectionNumber) {
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
    NSString *headerText = NSLocalizedString([self.sectionHeaders objectForKey:key], @"TableView Header Section Descriptions");
    return [headerText sizeWithFont:[UIFont systemFontOfSize:14.0f] constrainedToSize:CGSizeMake(320, 2000) lineBreakMode:UILineBreakModeWordWrap].height;
}

- (void)handleSyncObsticles
{
    NSArray *syncObsticles = [self.errorDictionary objectForKey:kDocumentsDeletedOnServerWithLocalChanges];
    for (NSString *fileName in syncObsticles) {
        [[FavoriteManager sharedManager] saveDeletedFavoriteFileBeforeRemovingFromSync:fileName];
    }
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

- (UITableViewCell *)tableView:(UITableView *)tV cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *standardCellIdentifier = @"StandardCellIdentifier";
    static NSString *favoritesErrorCellIdentifier = @"FavoritesErrorCellIdentifier";
    
    UITableViewCell *standardCell = (UITableViewCell *)[tV dequeueReusableCellWithIdentifier:standardCellIdentifier];
    FavoritesErrorTableViewCell *favoritesErrorCell = (FavoritesErrorTableViewCell *)[tV dequeueReusableCellWithIdentifier:favoritesErrorCellIdentifier];
    
    if (!standardCell) {
        standardCell = (UITableViewCell *)[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:standardCellIdentifier];
    }
    
    
    if (!favoritesErrorCell) {
        NSArray *nibItems = [[NSBundle mainBundle] loadNibNamed:@"FavoritesErrorTableViewCell" owner:self options:nil];
        favoritesErrorCell = (FavoritesErrorTableViewCell *)[nibItems objectAtIndex:0];
        favoritesErrorCell.delegate = self;
        NSAssert(nibItems, @"Failed to load object from NIB");
    }
    
    NSString *key = [self keyForSection:indexPath.section];
    NSArray *currentErrorArray = [errorDictionary objectForKey:key];
    
    if ([key isEqualToString:kDocumentsDeletedOnServerWithLocalChanges]) {
        standardCell.selectionStyle = UITableViewCellSelectionStyleNone;
        standardCell.textLabel.font = [UIFont systemFontOfSize:17.0f];
        standardCell.textLabel.text = [currentErrorArray objectAtIndex:indexPath.row];
        
        return standardCell;
    }

    favoritesErrorCell.selectionStyle = UITableViewCellSelectionStyleNone;
    favoritesErrorCell.fileNameTextLabel.text = [currentErrorArray objectAtIndex:indexPath.row];
    
    return favoritesErrorCell;
}

#pragma mark - UITableViewDelegate Functions

- (UIView *)tableView:(UITableView *)tV viewForHeaderInSection:(NSInteger)section
{
    NSString *key = [self keyForSection:section];
    NSArray *syncErrors = [self.errorDictionary objectForKey:key];
    if ([syncErrors count] > 0) {
        int horizontalMargin = 10;
        int verticalMargin = 10;
        
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tV.frame.size.width, [self calculateHeaderHeightForSection:section])];
        
        headerView.backgroundColor = [UIColor clearColor];
        headerView.contentMode = UIViewContentModeScaleAspectFit;
        headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(horizontalMargin, verticalMargin, tV.bounds.size.width - (horizontalMargin * 2), [self calculateHeaderHeightForSection:section] - (verticalMargin * 2))];
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
    NSArray *currentErrorArray = [errorDictionary objectForKey:key];
    // file name
    NSString *fileNameInCell = [currentErrorArray objectAtIndex:cellIndexPath.row];
    [[FavoriteManager sharedManager] syncUnfavoriteFileBeforeRemovingFromSync:fileNameInCell syncToServer:YES];
    [self.tableView reloadData];
}

- (void)didPressSaveToDownloadsButton:(UIButton *)saveButton
{
    FavoritesErrorTableViewCell *cell = (FavoritesErrorTableViewCell *)saveButton.superview.superview;
    NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
    // key for section
    NSString *key = [self keyForSection:cellIndexPath.section];
    NSArray *currentErrorArray = [errorDictionary objectForKey:key];
    // file name
    NSString *fileNameInCell = [currentErrorArray objectAtIndex:cellIndexPath.row];
    [[FavoriteManager sharedManager] syncUnfavoriteFileBeforeRemovingFromSync:fileNameInCell syncToServer:NO];
    [self.tableView reloadData];
}

@end
