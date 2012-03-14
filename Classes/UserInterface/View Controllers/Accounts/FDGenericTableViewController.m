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
//  FDGenericTableViewController.m
//

#import "FDGenericTableViewController.h"
#import "FDGenericTableViewPlistReader.h"
#import "IFTextViewTableView.h"
#import "Theme.h"

@implementation FDGenericTableViewController
@synthesize settingsReader = _settingsReader;
@synthesize rightButton = _rightButton;
@synthesize editingStyle = _editingStyle;
@synthesize tableStyle = _tableStyle;
@synthesize datasource = _datasource;
@synthesize selectedAccountUUID = _selectedAccountUUID;
@synthesize datasourceDelegate = _datasourceDelegate;
@synthesize rowRenderDelegate = _rowRenderDelegate;
@synthesize actionsDelegate = _actionsDelegate;

- (void)dealloc
{
    [_settingsReader release];
    [_rightButton release];
    [_datasource release];
    [_selectedAccountUUID release];
    [super dealloc];
}

- (void)setSettingsReader:(FDGenericTableViewPlistReader *)settingsReader
{
    if(settingsReader)
    {
        [settingsReader retain];
        [_settingsReader release];
        _settingsReader = settingsReader;
        
        [self setRightButton:[self.settingsReader rightBarButton]];
        [self setEditingStyle:[self.settingsReader editingStyle]];
        [self setDatasourceDelegate:[self.settingsReader datasourceDelegate]];
        [self setRowRenderDelegate:[self.settingsReader rowRenderDelegate]];
        [self setActionsDelegate:[self.settingsReader actionsDelegate]];
        [self setDatasource:[self.datasourceDelegate datasource]];
        
        if(self.datasourceDelegate && [self.datasourceDelegate respondsToSelector:@selector(delegate:forDatasourceChangeWithSelector:)])
        {
            [self.datasourceDelegate delegate:self forDatasourceChangeWithSelector:@selector(datasourceChanged:notification:)];
        }
    }
}

- (void)loadView
{
    if(!self.tableStyle)
    {
        [self setTableStyle:UITableViewStylePlain];
    }
	// NOTE: This code circumvents the normal loading of the UITableView and replaces it with an instance
	// of IFTextViewTableView (which includes a workaround for the hit testing problems in a UITextField.)
	// Check the header file for IFTextViewTableView to see why this is important.
	//
	// Since there is no style accessor on UITableViewController (to obtain the value passed in with the
	// initWithStyle: method), the value is hard coded for this use case. Too bad.
    
	self.view = [[[IFTextViewTableView alloc] initWithFrame:CGRectZero style:self.tableStyle] autorelease];
	[(IFTextViewTableView *)self.view setDelegate:self];
	[(IFTextViewTableView *)self.view setDataSource:self];
	[self.view setAutoresizesSubviews:YES];
	[self.view setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [Theme setThemeForUIViewController:self]; 
    [self setTitle:[self.settingsReader title]];
    
    if(self.rightButton && self.actionsDelegate && [self.actionsDelegate respondsToSelector:@selector(rightButtonActionWithDatasource:)])
    {
        [self.rightButton setTarget:self.actionsDelegate];
        [self.rightButton setAction:@selector(rightButtonActionWithDatasource:)];
        [self.navigationItem setRightBarButtonItem:self.rightButton];
    }
    
    // If there's a datasource and the actions delegate responds to the datasourceChanged: selector
    // we should notifiy the delegate. Useful when we want change the navigation based on the datasource state
    // for example, navigate into the account if there's only one account.
    if(self.datasource && self.actionsDelegate && [self.actionsDelegate respondsToSelector:@selector(datasourceChanged:inController:)])
    {
        [self.actionsDelegate datasourceChanged:self.datasource inController:self notification:nil];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)constructTableGroups
{
    [tableGroups release];
    [tableHeaders release];
    [tableFooters release];
    tableGroups = [[self.rowRenderDelegate tableGroupsWithDatasource:self.datasource] retain];
    tableHeaders = [[self.rowRenderDelegate tableHeadersWithDatasource:self.datasource] retain]; 
    tableFooters = [[self.rowRenderDelegate tableFootersWithDatasource:self.datasource] retain]; 
    
    // We have to check if each cell conforms to the FDTargetActionProtocol.
    // In that case we handle the tap action and pass it to the actions delegate
    for(NSArray *group in tableGroups)
    {
        for(NSObject<IFCellController> *cellController in group)
        {
            if([cellController conformsToProtocol:@protocol(FDTargetActionProtocol)]) {
                id<FDTargetActionProtocol> targetActionCell = (id<FDTargetActionProtocol>)cellController;
                [targetActionCell setAction:@selector(cellSelectAction:)];
                [targetActionCell setTarget:self];
            }
        }
    }
    
    [self.tableView setAllowsSelection:[self.rowRenderDelegate allowsSelection]];
    [self assignFirstResponderHostToCellControllers];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.actionsDelegate && [self.actionsDelegate respondsToSelector:@selector(commitEditingForIndexPath:withDatasource:)])
    {
        [self.actionsDelegate commitEditingForIndexPath:indexPath withDatasource:self.datasource];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.editingStyle;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kDefaultTableCellHeight;
}

- (void)cellSelectAction:(NSObject<IFCellController> *) cellController
{
    if(self.actionsDelegate && [self.actionsDelegate respondsToSelector:@selector(rowWasSelectedAtIndexPath:withDatasource:andController:)])
    {
        NSIndexPath *indexPath = [self indexPathForCellController:cellController];
        [self.actionsDelegate rowWasSelectedAtIndexPath:indexPath withDatasource:self.datasource andController:self];
    }
}

- (void)datasourceChanged:(NSDictionary *)newDatasource notification:(NSNotification *)notification
{
    // If there's a datasource and the actions delegate responds to the datasourceChanged: selector
    // we should notifiy the delegate. Useful when we want change the navigation based on the datasource state
    // for example, navigate into the account if there's only one account.
    if(self.datasource && self.actionsDelegate && [self.actionsDelegate respondsToSelector:@selector(datasourceChanged:inController:notification:)])
    {
        [self.actionsDelegate datasourceChanged:newDatasource inController:self notification:notification];
    }
    
    [self setDatasource:newDatasource];
    [self updateAndReload];
}

+ (FDGenericTableViewController *)genericTableViewWithPlistPath:(NSString *)plistPath andTableViewStyle:(UITableViewStyle)tableStyle
{
    FDGenericTableViewPlistReader *settingsReader = [[[FDGenericTableViewPlistReader alloc] initWithPlistPath:[[NSBundle mainBundle] pathForResource:@"BrowseAccountConfiguration" ofType:@"plist"]] autorelease];
    FDGenericTableViewController *controller = [[FDGenericTableViewController alloc] init];
    [controller setTableStyle:tableStyle];
    [controller setSettingsReader:settingsReader];
    return [controller autorelease];
}

@end
