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
 * Portions created by the Initial Developer are Copyright (C) 2011
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  SelectSiteViewController.m
//

#import "SelectSiteViewController.h"
#import "RepositoryItem.h"
#import "TableCellViewController.h"
#import "AlfrescoAppDelegate.h"
#import "IFTextViewTableView.h"
#import "RepositoryServices.h"
#import "MBProgressHUD.h"
#import "TableViewNode.h"
#import "ExpandTableViewCell.h"
#import "AccountNode.h"
#import "SiteNode.h"
#import "NetworkNode.h"
#import "NetworkSiteNode.h"

@interface  SelectSiteViewController (private)
-(void)startHUD;
-(void)stopHUD;
-(void)requestSitesForAccountUUID:(NSString *)uuid;
-(void)retrieveChildNodes:(TableViewNode *)node;
-(void)expandOrCollapseTableNode:(TableViewNode *)tableNode;
@end

@implementation SelectSiteViewController
@synthesize selectedNode;
@synthesize expandingNode;
@synthesize allItems;
@synthesize delegate;
@synthesize HUD;
@synthesize selectedAccountUUID;

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [selectedNode release];
    [expandingNode release];
    [allItems release];
    [HUD release];
    [selectedAccountUUID release];
    [super dealloc];
}

-(void)viewDidLoad {
    [super viewDidLoad];
    NSArray *allAccounts = [[MultiAccountBrowseManager sharedManager] accounts];
    self.allItems = [NSMutableArray arrayWithCapacity:[allAccounts count]];

    
    for(AccountInfo *account in allAccounts) {
        AccountNode *cellNode = [[AccountNode alloc] init];
        [cellNode setIndentationLevel:0];
        [cellNode setValue:account];
        [cellNode setCanExpand:YES];
        [cellNode setAccountUUID:[account uuid]];
        [allItems addObject:cellNode];
        [cellNode release];
    }
    
    [self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                             target:self
                                                                                             action:@selector(cancelSelection:)] autorelease]];
    
    UIBarButtonItem *saveButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                 target:self
                                                                                 action:@selector(saveSelection:)] autorelease];
    styleButtonAsDefaultAction(saveButton);
    [self.navigationItem setRightBarButtonItem:saveButton];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAccountListUpdated:) 
                                                 name:kNotificationAccountListUpdated object:nil];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.allItems = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if(!cancelled) 
    {
        if(delegate && [delegate respondsToSelector:@selector(selectSiteDidCancel:)]) 
        {
            [delegate selectSiteDidCancel:self];
        } 
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

#pragma mark - UITableViewControllerDelegate
- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [allItems count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
    TableViewNode *cellNode = [allItems objectAtIndex:indexPath.row];
    return [cellNode indentationLevel];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TableViewNode *cellNode = [allItems objectAtIndex:indexPath.row];
    ExpandTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kExpandCellIdentifier];
    
    if(!cell) {
        NSArray *nibItems = [[NSBundle mainBundle] loadNibNamed:@"ExpandTableViewCell" owner:self options:nil];
		cell = [nibItems objectAtIndex:0];
		NSAssert(nibItems, @"Failed to load object from NIB");
    }
    
    [cell setIndentationLevel:[cellNode indentationLevel]];
    [cell.textLabel setText:[cellNode title]];
    [cell.textLabel setHighlightedTextColor:[UIColor whiteColor]];
    [cell.imageView setImage:[cellNode cellImage]];
    
    if([cellNode isEqual:selectedNode]) {
        [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    
    [cell setIsExpanded:[cellNode isExpanded]];
    if([cellNode canExpand]) {
        //Set hidden not working for a UIButton?
        //Using the alpha property instead
        [cell.expandView setHidden:NO];
        [cell setExpandTarget:self];
        [cell setExpandAction:@selector(expandOrCollapseCellNode:)];
        [cell setIndexPath:indexPath];
    } else {
        [cell.expandView setHidden:YES];
        [cell setExpandTarget:nil];
        [cell setIndexPath:nil];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    TableViewNode *cellNode = [allItems objectAtIndex:indexPath.row];
    AccountInfo *account = [cellNode value];
    
    //We expand (or collapse) the nodes that cannot be selected like a Cloud account
    if(![cellNode isKindOfClass:[AccountNode class]] || ![account isMultitenant]) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self setSelectedNode:cellNode];
    } else 
    {
        [self expandOrCollapseTableNode:cellNode];
    }
    
    [tableView reloadData];
}

#pragma mark - Collapse/expand

- (void)collapseNode:(TableViewNode *)node{
    NSInteger itemIndex = [allItems indexOfObject:node];
    NSMutableArray *nodesToRemove = [NSMutableArray array];
    NSInteger index = itemIndex + 1;
    TableViewNode *nextItem = nil;
    
    if(index < [allItems count]) {
        nextItem = [allItems objectAtIndex:index];
    }
    
    while(nextItem != nil) {
        if([nextItem parent] == node)
        {
            [nodesToRemove addObject:nextItem];
        }
        
        index++;
        if(index < [allItems count]) {
            nextItem = [allItems objectAtIndex:index];
        } else {
            nextItem = nil;
        }
    }
    
    for(TableViewNode *node in nodesToRemove)
    {
        if([node canExpand] && [node isExpanded])
        {
            [self collapseNode:node];
        }
    }
    
    [node setIsExpanded:NO];
    [allItems removeObjectsInArray:nodesToRemove];
    [self.tableView reloadData];
}

- (void)expandNode:(TableViewNode *)node withNodes:(NSArray *)nodes {
    NSInteger itemIndex = [allItems indexOfObject:node] + 1;
    [node setIsExpanded:YES];
    
    for(TableViewNode *currNode in nodes) {
        [currNode setIndentationLevel:[node indentationLevel]+1];
        [currNode setParent:node];
        
        [allItems insertObject:currNode atIndex:itemIndex];
        itemIndex++;
    }
    
    [self.tableView reloadData];
}
#pragma mark - Expand or Collapse target/action
-(void)expandOrCollapseCellNode:(ExpandTableViewCell *)tableCell {
    TableViewNode *cellNode = [allItems objectAtIndex:[tableCell.indexPath row]];
    [self expandOrCollapseTableNode:cellNode];
}

-(void)expandOrCollapseTableNode:(TableViewNode *)tableNode
{
    [tableNode setIsExpanded:![tableNode isExpanded]];
    
    if([tableNode isExpanded]) {
        [self retrieveChildNodes:tableNode];
    } else {
        [self collapseNode:tableNode];
    }

}

#pragma mark - Requesting childs (sites/networks)
-(void)retrieveChildNodes:(TableViewNode *)node{
    id value = [node value];
    AccountInfo *account = [node value];
    
    if([value isKindOfClass:[AccountInfo class]] && ![account isMultitenant]) {
        [self startHUD];
        self.expandingNode = node;
        [[MultiAccountBrowseManager sharedManager] addListener:self];
        [[MultiAccountBrowseManager sharedManager] loadSitesForAccountUUID:[account uuid]];
    } else if([value isKindOfClass:[AccountInfo class]] && [account isMultitenant]) {
        [self startHUD];
        self.expandingNode = node;
        [[MultiAccountBrowseManager sharedManager] addListener:self];
        [[MultiAccountBrowseManager sharedManager] loadNetworksForAccountUUID:[account uuid]];
    } else if([node isKindOfClass:[NetworkNode class]]) {
        [self startHUD];
        self.expandingNode = node;
        RepositoryInfo *repoInfo = [node value];
        [[MultiAccountBrowseManager sharedManager] addListener:self];
        [[MultiAccountBrowseManager sharedManager] loadSitesForAccountUUID:[node accountUUID] tenantID:[repoInfo tenantID]];
    }
}

#pragma mark -
#pragma mark MultiAccountBrowseListener methods

-(void)multiAccountBrowseUpdated:(MultiAccountBrowseManager *)manager forType:(MultiAccountUpdateType)type {
    if(type == MultiAccountSitesUpdate) {
        AccountInfo *account = [expandingNode value];
        NSArray *sites = [manager sitesForAccountUUID:[account uuid]];
        NSMutableArray *newNodes = [NSMutableArray arrayWithCapacity:[sites count]];
        
        for(RepositoryItem *site in sites) {
            SiteNode *node = [[SiteNode alloc] init];
            [node setParent:expandingNode];
            [node setValue:site];
            [node setCanExpand:NO];
            [node setAccountUUID:[account uuid]];
            [newNodes addObject:node];
            [node release];
        }
        
        [self expandNode:expandingNode withNodes:newNodes];
    } else if(type == MultiAccountNetworksUpdate) {
        AccountInfo *account = [expandingNode value];
        NSArray *sites = [manager networksForAccountUUID:[account uuid]];
        NSMutableArray *newNodes = [NSMutableArray arrayWithCapacity:[sites count]];
        
        for(RepositoryInfo *site in sites) {
            NetworkNode *node = [[NetworkNode alloc] init];
            [node setParent:expandingNode];
            [node setValue:site];
            [node setCanExpand:YES];
            [node setAccountUUID:[account uuid]];
            [newNodes addObject:node];
            [node release];
        }
        
        [self expandNode:expandingNode withNodes:newNodes];
    } else if(type == MultiAccountNetworkSitesUpdate) {
        //Expanding node is a NetworkNode
        RepositoryInfo *repositoryInfo = [expandingNode value];
        
        NSArray *sites = [manager sitesForAccountUUID:[expandingNode accountUUID] tenantID:[repositoryInfo tenantID]];
        NSMutableArray *newNodes = [NSMutableArray arrayWithCapacity:[sites count]];
        
        for(RepositoryItem *site in sites) {
            NetworkSiteNode *node = [[NetworkSiteNode alloc] init];
            [node setParent:expandingNode];
            [node setValue:site];
            [node setCanExpand:NO];
            [node setAccountUUID:[expandingNode accountUUID]];
            [node setTenantID:[repositoryInfo tenantID]];
            [newNodes addObject:node];
            [node release];
        }
        
        [self expandNode:expandingNode withNodes:newNodes];
    }
    
    [self setExpandingNode:nil];
    [manager removeListener:self];
    [self stopHUD];
}

-(void)multiAccountBrowseFailed:(MultiAccountBrowseManager *)manager forType:(MultiAccountUpdateType)type {
    [self setExpandingNode:nil];
    [manager removeListener:self];
    [self stopHUD];
}

#pragma mark - Navbar buttons
-(void)saveSelection:(id)sender {
    if(delegate && [delegate respondsToSelector:@selector(selectSite:finishedWithItem:)]) {
        [delegate selectSite:self finishedWithItem:selectedNode];
    } 
}

-(void)cancelSelection:(id)sender {
    cancelled = YES;
    if(delegate && [delegate respondsToSelector:@selector(selectSiteDidCancel:)]) {
        [delegate selectSiteDidCancel:self];
    } 
}

#pragma mark - static initializers
+(SelectSiteViewController *)selectSiteViewController {
    SelectSiteViewController *select = [[[SelectSiteViewController alloc] initWithStyle:UITableViewStylePlain] autorelease];
    return select;
}

#pragma mark -
#pragma mark MBProgressHUD Helper Methods
- (void)startHUD
{
	if (HUD) {
		return;
	}
    
    [self setHUD:[MBProgressHUD showHUDAddedTo:self.view animated:YES]];
    [self.HUD setRemoveFromSuperViewOnHide:YES];
    [self.HUD setTaskInProgress:YES];
    [self.HUD setMode:MBProgressHUDModeIndeterminate];
}

- (void)stopHUD
{
	if (HUD) {
		[HUD setTaskInProgress:NO];
		[HUD hide:YES];
		[HUD removeFromSuperview];
		[self setHUD:nil];
    }
}

#pragma mark -
#pragma mark Notification methods
- (void)handleAccountListUpdated:(NSNotification *) notification
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(handleAccountListUpdated:) withObject:notification waitUntilDone:NO];
        return;
    }
    
    NSDictionary *userInfo = [notification userInfo];
    NSString *uuid = [userInfo objectForKey:@"uuid"];
    BOOL isReset = [[userInfo objectForKey:@"reset"] boolValue];
    
    if(self.selectedNode && ([[self.selectedNode accountUUID] isEqualToString:uuid] || isReset)) 
    {
        [self setSelectedNode:nil];
        [self.tableView reloadData];
    }
}

@end
