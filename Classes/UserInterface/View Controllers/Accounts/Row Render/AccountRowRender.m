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
//  AccountRowRender.m
//

#import "AccountRowRender.h"
#import "AccountInfo.h"
#import "TableCellViewController.h"
#import "AccountCellController.h"

@implementation AccountRowRender
@synthesize allowsSelection = _allowsSelection;
@synthesize allowsEditing = _allowsEditing;

- (NSArray *)tableGroupsWithDatasource:(NSDictionary *)datasource
{
    NSArray *accounts = [[datasource objectForKey:@"accounts"] retain];
    
    NSMutableArray *groups =  [NSMutableArray array];
    
    NSMutableArray *accountsGroup = [NSMutableArray array];
    NSInteger index = 0;
    
    for(AccountInfo *detail in accounts) 
    {        
        NSString *iconImageName = ([detail isMultitenant] ? kCloudIcon_ImageName : kServerIcon_ImageName);
        
        /*
         The FDGenericTableViewController will try to assign the action and the target to the actionsDelegate in each cell
         */
        AccountCellController *accountCell = [[AccountCellController alloc] initWithAction:nil
                                                                                      onTarget:nil];
        [accountCell setCellStyle:UITableViewCellStyleSubtitle];
        [accountCell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        [accountCell setSelectionStyle:UITableViewCellSelectionStyleBlue];
        [accountCell setTag:index];
        [accountCell.textLabel setText:[detail description]];
        
        NSString *statusShortMessage = [[detail accountStatusInfo] shortMessage];
        if(statusShortMessage)
        {
            [accountCell.detailTextLabel setText:statusShortMessage];
        }
        
        UIColor *subtitleColor = [[detail accountStatusInfo] shortMessageTextColor];
        if(subtitleColor)
        {
            [accountCell.detailTextLabel setTextColor:subtitleColor];
        }
        [[accountCell imageView]setImage:[UIImage imageNamed:iconImageName]];
        
        if([[detail accountStatusInfo] isError])
        {
            [accountCell setWarningImage:[UIImage imageNamed:@"ui-button-bar-badge-error.png"]];
        }
        
        [accountsGroup addObject:accountCell];
        [accountCell release];
        index++;
        
        [self setAllowsSelection:YES];
        [self setAllowsEditing:YES];
    }
    
    if([accounts count] > 0) 
    {
        [groups addObject:accountsGroup];
    } 
    else 
    {
        AccountCellController *cell;
        cell = [[AccountCellController alloc] initWithAction:nil onTarget:nil];
        [cell setAccessoryType:UITableViewCellAccessoryNone];
        [[cell textLabel] setText:NSLocalizedString(@"serverlist.cell.noaccounts", @"No Accounts")];
        [cell setShouldResizeTextToFit:YES];
        
        NSMutableArray *group = [NSMutableArray array];
        [group addObject:cell];
        [cell release];
        
        [groups addObject:group];
        [self setAllowsSelection:NO];
        [self setAllowsEditing:NO];
    }
    
    [accounts release];
    
    return groups;
}

- (NSArray *)tableHeadersWithDatasource:(NSDictionary *)datasource
{
    return nil;
}

- (NSArray *)tableFootersWithDatasource:(NSDictionary *)datasource
{
    return nil;
}
@end
