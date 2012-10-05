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

@interface FDGenericTableViewController(private)
- (void)rightButtonAction:(id)sender;
- (void)notifyDelegateLastResponderDone;
@end

@implementation FDGenericTableViewController
@synthesize settingsReader = _settingsReader;
@synthesize rightButton = _rightButton;
@synthesize editingStyle = _editingStyle;
@synthesize tableStyle = _tableStyle;
@synthesize datasource = _datasource;
@synthesize selectedAccountUUID = _selectedAccountUUID;
@synthesize rowHeight = _rowHeight;
@synthesize datasourceDelegate = _datasourceDelegate;
@synthesize rowRenderDelegate = _rowRenderDelegate;
@synthesize actionsDelegate = _actionsDelegate;

- (void)dealloc
{
    [_settingsReader release];
    [_rightButton release];
    [_datasource release];
    [_selectedAccountUUID release];
    [_datasourceDelegate release];
    [_rowRenderDelegate release];
    [_actionsDelegate release];
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
    [Theme setThemeForUINavigationBar:self.navigationController.navigationBar];
    [self.navigationItem setTitle:[self.settingsReader title]];
    
    if(self.rightButton)
    {
        [self.rightButton setTarget:self];
        [self.rightButton setAction:@selector(rightButtonAction:)];
        [self.navigationItem setRightBarButtonItem:self.rightButton];
    }
    
    // If there's a datasource and the actions delegate responds to the datasourceChanged: selector
    // we should notifiy the delegate. Useful when we want change the navigation based on the datasource state
    // for example, navigate into the account if there's only one account.
    if(self.datasource && self.actionsDelegate && [self.actionsDelegate respondsToSelector:@selector(datasourceChanged:inController:notification:)])
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
    if ([self.rowRenderDelegate allowsEditing])
    {
        return self.editingStyle;
    }
    return UITableViewCellEditingStyleNone;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(_rowHeight <= 0)
    {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    } 
    else
    {
        return _rowHeight;
    }
}

#pragma mark - IFGenericTableViewController improvements
/*
 THe next two methods add support for views in the footer group rather than only strings to the
 IFGenericTableViewController functionality
 */
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (!tableGroups)
	{
		[self constructTableGroups];
	}
	
	if (tableFooters)
	{
		id object = [tableFooters objectAtIndex:section];
		if ([object isKindOfClass:[NSString class]])
		{
			if ([object length] > 0)
			{
				return 30;
			}
            else
            {
                return 0;
            }
		}
        
        if([object isKindOfClass:[UILabel class]]) 
        {
            UILabel *footerLabel = (UILabel *)object;
            return [footerLabel numberOfLines] * 30;
        }
	}
    
    if(![tableFooters objectAtIndex:section])
    {
        return 0;
    }
    
	return 60;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (!tableGroups)
	{
		[self constructTableGroups];
	}
	
	if (tableFooters)
	{
		id object = [tableFooters objectAtIndex:section];
		if ([object isKindOfClass:[NSString class]])
		{
			if ([object length] > 0)
			{
                UIView *originalView = [super tableView:tableView viewForFooterInSection:section];
				return originalView;
			}
		}
        
        if ([object isKindOfClass:[UIView class]])
		{
            return object;
		}
	}
    
	return nil;
}

#pragma mark - IFCellControllerFirstResponder
// call the right button after the last responder is done
// IF the user taps in Done in the keyboard for the last field
- (void)lastResponderIsDone: (NSObject<IFCellController> *)cellController
{
	[super lastResponderIsDone:cellController];
    [self notifyDelegateLastResponderDone];
    [self rightButtonAction:cellController];
}

#pragma mark - User actions
- (void)notifyDelegateLastResponderDone
{
    if(self.actionsDelegate && [self.actionsDelegate respondsToSelector:@selector(genericController:lastResponderIsDoneWithDatasource:)])
    {
        [self.actionsDelegate genericController:self lastResponderIsDoneWithDatasource:self.datasource];
    }
}

- (void)cellSelectAction:(NSObject<IFCellController> *) cellController
{
    if(self.actionsDelegate && [self.actionsDelegate respondsToSelector:@selector(rowWasSelectedAtIndexPath:withDatasource:andController:)])
    {
        NSIndexPath *indexPath = [self indexPathForCellController:cellController];
        [self.actionsDelegate rowWasSelectedAtIndexPath:indexPath withDatasource:self.datasource andController:self];
    }
}

- (void)rightButtonAction:(id)sender
{
    if(self.actionsDelegate && [self.actionsDelegate respondsToSelector:@selector(rightButtonActionWithDatasource:andController:)])
    {
        [self.actionsDelegate rightButtonActionWithDatasource:self.datasource andController:self];
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
    
    // We reload the view if the delegate doesn't perform the shouldReloadTableView selector
    if(![self.datasourceDelegate respondsToSelector:@selector(shouldReloadTableView)] || [self.datasourceDelegate shouldReloadTableView])
    {
        [self setDatasource:newDatasource];
        [self updateAndReload];
    }
}

+ (FDGenericTableViewController *)genericTableViewWithPlistPath:(NSString *)plistPath andTableViewStyle:(UITableViewStyle)tableStyle
{
    FDGenericTableViewPlistReader *settingsReader = [[[FDGenericTableViewPlistReader alloc] initWithPlistPath:plistPath] autorelease];
    FDGenericTableViewController *controller = [[FDGenericTableViewController alloc] init];
    [controller setTableStyle:tableStyle];
    [controller setSettingsReader:settingsReader];
    return [controller autorelease];
}

@end
