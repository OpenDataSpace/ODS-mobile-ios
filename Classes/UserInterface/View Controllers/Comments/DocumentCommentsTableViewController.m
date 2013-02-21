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
//  DocumentCommentsTableViewController.m
//

#import "DocumentCommentsTableViewController.h"
#import "Theme.h"
#import "IFTemporaryModel.h"
#import "IFMultilineCellController.h"
#import "IFTextViewTableView.h"
#import "IFValueCellController.h"
#import "Utility.h"
#import "CommentCellViewController.h"

@implementation DocumentCommentsTableViewController
@synthesize cmisObjectId = _cmisObjectId;
@synthesize commentsRequest = _commentsRequest;
@synthesize downloadMetadata = _downloadMetadata;
@synthesize selectedAccountUUID = _selectedAccountUUID;
@synthesize tenantID = _tenantID;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_commentsRequest clearDelegatesAndCancel];
    
    [_cmisObjectId release];
    [_commentsRequest release];
    [_downloadMetadata release];
    [_selectedAccountUUID release];
    [_tenantID release];
    
    [super dealloc];
}

- (id)initWithCMISObjectId:(NSString *)objectId
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self)
    {
        [self setCmisObjectId:objectId];
    }
    return self;
}

- (id)initWithDownloadMetadata:(DownloadMetadata *)downloadData
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self)
    {
        [self setDownloadMetadata:downloadData];
    }
    return self;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [Theme setThemeForUINavigationBar:self.navigationController.navigationBar];
    
    [self.navigationItem setTitle:NSLocalizedString(@"comments.view.title", @"Comments Table View Title")];
    BOOL useLocalComments = [[FDKeychainUserDefaults standardUserDefaults] boolForKey:@"useLocalComments"];
    id nodePermissions = [self.model objectForKey:@"nodePermissions"];  // model is not K/V codeable
    BOOL canCreateComment = [[nodePermissions objectForKey:@"create"] boolValue];
    
    //Always allow adding local comments. 
    //Only allow alfresco repository adding when permissions are available and we are not in "Use Local Comments" mode
    if ((canCreateComment && !useLocalComments) || (self.downloadMetadata && useLocalComments))
    {
        // Add Button
        UIBarButtonItem *addCommentButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
                                                                                          target:self action:@selector(addCommentButtonPressed)];
        [self.navigationItem setRightBarButtonItem:addCommentButton];
        [addCommentButton release];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Always Rotate
    return YES;
}

- (void)loadView
{
#if 1
	// NOTE: This code circumvents the normal loading of the UITableView and replaces it with an instance
	// of IFTextViewTableView (which includes a workaround for the hit testing problems in a UITextField.)
	// Check the header file for IFTextViewTableView to see why this is important.
	//
	// Since there is no style accessor on UITableViewController (to obtain the value passed in with the
	// initWithStyle: method), the value is hard coded for this use case. Too bad.
    
	self.view = [[[IFTextViewTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain] autorelease];
	[(IFTextViewTableView *)self.view setDelegate:self];
	[(IFTextViewTableView *)self.view setDataSource:self];
	[self.view setAutoresizesSubviews:YES];
	[self.view setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
#else
	[super loadView];
#endif
}


#pragma mark - Generic Table View Construction

- (void)constructTableGroups
{
    if (![self.model isKindOfClass:[IFTemporaryModel class]])
    {
        IFTemporaryModel *tempModel = [[IFTemporaryModel alloc] init];
        [self setModel:tempModel];
        [tempModel release];
	}
    
    // Arrays for section headers, bodies and footers
	NSMutableArray *headers = [NSMutableArray array];
	NSMutableArray *groups =  [NSMutableArray array];
	NSMutableArray *footers = [NSMutableArray array];
    
    NSMutableArray *commentsCellGroup = [NSMutableArray array];
    
    NSString *author;
    NSString *commentHtml;
    NSString *modifiedOn;
    
    NSArray *items = [self.model objectForKey:@"items"];
    for (NSDictionary *item in items)
    {
        author = [NSString stringWithFormat:@"%@ %@", 
                  ([item valueForKeyPath:@"author.firstName"] ? [item valueForKeyPath:@"author.firstName"] : [NSString string]), 
                  ([item valueForKeyPath:@"author.lastName"] ? [item valueForKeyPath:@"author.lastName"] : [NSString string])
                  ];
        commentHtml = [item objectForKey:@"content"];
        modifiedOn = [item objectForKey:@"modifiedOn"];
        
        NSRange r;
        NSString *regEx = @"\\w{3} \\d{1,2} \\d{4} \\d{2}:\\d{2}:\\d{2} \\w+[\\+\\-]\\d{4}";
        r = [modifiedOn rangeOfString:regEx options:NSRegularExpressionSearch];
        
        if (r.location != NSNotFound)
        {
            modifiedOn = [modifiedOn substringWithRange:r];
        }

        modifiedOn = changeStringDateToFormat(modifiedOn, @"MMM dd yyyy HH:mm:ss ZZZZ", @"EE d MMM yyyy HH:mm:ss");
        AlfrescoLogDebug(@"Final Date: %@", modifiedOn);

        CommentCellViewController *cellController = [[CommentCellViewController alloc]  initWithTitle:author 
                                                                                         withSubtitle:[commentHtml stringByRemovingHTMLTags] 
                                                                                        andCreateDate:modifiedOn 
                                                                                              inModel:self.model];
        [commentsCellGroup addObject:cellController];
        [cellController release];
    }
    
    NSString *footerText;
    switch (items.count)
    {
        case 1:
            footerText = NSLocalizedString(@"1 Comment", @"1 Comment");
            break;
        case 0:
            footerText = NSLocalizedString(@"0 Comments", @"0 Comments");
            [commentsCellGroup addObject:[[[IFValueCellController alloc]initWithLabel:@" " atKey:nil inModel:nil]autorelease]];
            break;
        default:
            footerText = [NSString stringWithFormat:NSLocalizedString(@"%d Comments", @"%d Comments"), [items count]];
            break;
    }
    
    [headers addObject:@""];
	[groups addObject:commentsCellGroup];
	[footers addObject:footerText];
    
    tableGroups = [groups retain];
	tableHeaders = [headers retain];
	tableFooters = [footers retain];
	
    [self setEditing:NO animated:YES];
    
	[self assignFirstResponderHostToCellControllers];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UILabel *footerBackground = [[[UILabel alloc] init] autorelease];
    [footerBackground  setText:[tableFooters objectAtIndex:section]];	
    [footerBackground setBackgroundColor:[UIColor whiteColor]];
    [footerBackground setTextAlignment:UITextAlignmentCenter];
    return  footerBackground;
}

- (void)willTransitionToState:(UITableViewCellStateMask)state 
{
    if ((state & UITableViewCellStateShowingDeleteConfirmationMask) == UITableViewCellStateShowingDeleteConfirmationMask)
    {
        for (UIView *subview in self.view.subviews)
        {
            if ([NSStringFromClass([subview class]) isEqualToString:@"UITableViewCellDeleteConfirmationControl"])
            {
                subview.hidden = YES;
                subview.alpha = 0.0;
            }
        }
    }
}

- (void)didTransitionToState:(UITableViewCellStateMask)state 
{    
    if (state == UITableViewCellStateShowingDeleteConfirmationMask || state == UITableViewCellStateDefaultMask)
    {
        for (UIView *subview in self.view.subviews)
        {
            if ([NSStringFromClass([subview class]) isEqualToString:@"UITableViewCellDeleteConfirmationControl"])
            {
                UIView *deleteButtonView = (UIView *)[subview.subviews objectAtIndex:0];
                CGRect f = deleteButtonView.frame;
                f.origin.x -= 20;
                deleteButtonView.frame = f;
                
                subview.hidden = NO;
                
                [UIView beginAnimations:@"anim" context:nil];
                subview.alpha = 1.0;
                [UIView commitAnimations];
            }
        }
    }
}

#pragma mark - Action methods

- (void)addCommentButtonPressed
{
    AddCommentViewController *viewController;
    
    if (self.downloadMetadata)
    {
        viewController = [[AddCommentViewController alloc] initWithDownloadMetadata:self.downloadMetadata];
    }
    else
    {
        viewController = [[AddCommentViewController alloc] initWithNodeRef:[NodeRef nodeRefFromCmisObjectId:self.cmisObjectId]];
    }
    [viewController setDelegate:self];
    [viewController setSelectedAccountUUID:self.selectedAccountUUID];
    [viewController setTenantID:self.tenantID];
    [self.navigationController pushViewController:viewController animated:YES];
    [viewController release];
}

#pragma mark -  AddCommentViewDelegate

- (void) didSubmitComment:(NSString *)comment
{
    AlfrescoLogDebug(@"Comment: %@", comment);
    if (self.cmisObjectId)
    {
        self.commentsRequest = [CommentsHttpRequest commentsHttpGetRequestWithNodeRef:[NodeRef nodeRefFromCmisObjectId:self.cmisObjectId] 
                                                                          accountUUID:self.selectedAccountUUID
                                                                             tenantID:self.tenantID];
        [self.commentsRequest setDelegate:self];
        [self.commentsRequest startAsynchronous];
    }
    else if (self.downloadMetadata)
    {
        //local comment
        NSDictionary *commentDicts = [NSDictionary dictionaryWithObject:self.downloadMetadata.localComments forKey:@"items"];
        [self setModel:[[[IFTemporaryModel alloc] initWithDictionary:[NSMutableDictionary dictionaryWithDictionary:commentDicts]] autorelease]];
        [self updateAndReload];
    }
}

- (void)requestFinished:(ASIHTTPRequest *)sender
{
    AlfrescoLogDebug(@"commentsHttpRequestDidFinish");
    CommentsHttpRequest *request = (CommentsHttpRequest *)sender;
    [self setModel:[[[IFTemporaryModel alloc] initWithDictionary:[NSMutableDictionary dictionaryWithDictionary:request.commentsDictionary]] autorelease]];
    [self updateAndReload];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    AlfrescoLogDebug(@"commentsHttpRequestDidFail!");
}

- (void) cancelActiveConnection:(NSNotification *) notification
{
    AlfrescoLogDebug(@"applicationWillResignActive in DocumentCommentsTableViewController");
    [self.commentsRequest clearDelegatesAndCancel];
}

@end
