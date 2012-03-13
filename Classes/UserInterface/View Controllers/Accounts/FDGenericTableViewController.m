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

@implementation FDGenericTableViewController
@synthesize settingsReader = _settingsReader;
@synthesize rightButton = _rightButton;
@synthesize datasource = _datasource;
@synthesize datasourceDelegate = _datasourceDelegate;
@synthesize rowRenderDelegate = _rowRenderDelegate;
@synthesize actionsDelegate = _actionsDelegate;

- (void)dealloc
{
    [_settingsReader release];
    [_datasource release];
    [super dealloc];
}

- (id)initWithSettingsReader:(FDGenericTableViewPlistReader *)settingsReader
{
    self = [super initWithStyle:UITableViewStylePlain];
    if(self)
    {
        [self setSettingsReader:settingsReader];
        [self setRightButton:[self.settingsReader rightBarButton]];
        [self setEditingStyle:[self.settingsReader editingStyle]];
        [self setDatasourceDelegate:[self.settingsReader datasourceDelegate]];
        [self setRowRenderDelegate:[self.settingsReader rowRenderDelegate]];
        [self setActionsDelegate:[self.settingsReader actionsDelegate]];
        [self setDatasource:[self.datasourceDelegate datasource]];
        
        if(self.datasourceDelegate && [self.datasourceDelegate performSelector:@selector(delegate:forDatasourceChangeWithSelector:)])
        {
            [self.datasourceDelegate delegate:self forDatasourceChangeWithSelector:@selector(datasourceChanged:)];
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if(self.rightButton && self.actionsDelegate && [self.actionsDelegate performSelector:@selector(rightButtonActionWithDatasource:)])
    {
        [self.rightButton setTarget:self.actionsDelegate];
        [self.rightButton setAction:@selector(rightButtonActionWithDatasource:)];
        [self.navigationItem setRightBarButtonItem:self.rightButton];
    }
}

- (void)constructTableGroups
{
    [tableGroups release];
    [tableHeaders release];
    [tableFooters release];
    tableGroups = [self.rowRenderDelegate tableGroupsWithDatasource:self.datasource];
    tableHeaders = [self.rowRenderDelegate tableHeadersWithDatasource:self.datasource]; 
    tableFooters = [self.rowRenderDelegate tableFootersWithDatasource:self.datasource]; 
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.actionsDelegate && [self.actionsDelegate performSelector:@selector(commitEditingForIndexPath:withDatasource:)])
    {
        [self.actionsDelegate commitEditingForIndexPath:indexPath withDatasource:self.datasource];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.editingStyle;
}

- (void)datasourceChanged:(NSDictionary *)newDatasource
{
    [self setDatasource:newDatasource];
    [self updateAndReload];
}

@end
