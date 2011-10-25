//
//  ***** BEGIN LICENSE BLOCK *****
//  Version: MPL 1.1
//
//  The contents of this file are subject to the Mozilla Public License Version
//  1.1 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS" basis,
//  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
//  for the specific language governing rights and limitations under the
//  License.
//
//  The Original Code is the Alfresco Mobile App.
//  The Initial Developer of the Original Code is Zia Consulting, Inc.
//  Portions created by the Initial Developer are Copyright (C) 2011
//  the Initial Developer. All Rights Reserved.
//
//
//  ***** END LICENSE BLOCK *****
//
//
//  DocumentCommentsTableViewController.m
//

#import "DocumentCommentsTableViewController.h"
#import "Theme.h"
#import "IFTemporaryModel.h"
#import "IFMultilineCellController.h"
#import "IFTextViewTableView.h"
#import "IFValueCellController.h"
#import "NodeRef.h"
#import "CommentsHttpRequest.h"
#import "Utility.h"


@implementation DocumentCommentsTableViewController
@synthesize cmisObjectId;

- (void)dealloc
{
    [cmisObjectId release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (id)initWithCMISObjectId:(NSString *)objectId
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        [self setCmisObjectId:objectId];
    }
    return self;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [Theme setThemeForUINavigationBar:self.navigationController.navigationBar];
    
    [self.navigationItem setTitle:NSLocalizedString(@"comments.view.title", @"Comments Table View Title")];
    
    id nodePermissions = [self.model objectForKey:@"nodePermissions"];  // model is not K/V codeable
    if ([nodePermissions objectForKey:@"create"]) {
        // Add Button
        UIBarButtonItem *addCommentButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
                                                                                          target:self action:@selector(addCommentButtonPressed)];
        [self.navigationItem setRightBarButtonItem:addCommentButton];
        [addCommentButton release];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
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


#pragma mark -
#pragma mark Generic Table View Construction
- (void)constructTableGroups
{
    if (![self.model isKindOfClass:[IFTemporaryModel class]]) {
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
    for (NSDictionary *item in items) {
        author = [NSString stringWithFormat:@"%@ %@", 
                  ([item valueForKeyPath:@"author.firstName"] ? [item valueForKeyPath:@"author.firstName"] : [NSString string]), 
                  ([item valueForKeyPath:@"author.lastName"] ? [item valueForKeyPath:@"author.lastName"] : [NSString string])
                  ];
        commentHtml = [item objectForKey:@"content"];
        modifiedOn = [item objectForKey:@"modifiedOn"];
        commentHtml = [NSString stringWithFormat:@"%@\r\n%@", commentHtml, modifiedOn];

        
        IFMultilineCellController *cellController = [[IFMultilineCellController alloc] initWithTitle:author 
                                                                                         andSubtitle:commentHtml 
                                                                                             inModel:self.model];
        [commentsCellGroup addObject:cellController];
        [cellController release];
    }
    
    NSString *footerText;
    switch ([items count]) {
        case 1:
            footerText = NSLocalizedString(@"1 Comment", @"1 Comment");
            break;
        case 0:
            footerText = NSLocalizedString(@"0 Comments", @"0 Comments");
            [commentsCellGroup addObject:[[[IFValueCellController alloc]initWithLabel:@" " atKey:nil inModel:nil]autorelease]];
            break;
        default:
            footerText = [NSString stringWithFormat:NSLocalizedString(@"%d Comments",@"%d Comments"), [items count]];
            break;
    }
    
    [headers addObject:@""];
	[groups addObject:commentsCellGroup];
	[footers addObject:footerText];
    
    tableGroups = [groups retain];
	tableHeaders = [headers retain];
	tableFooters = [footers retain];
	
	[self assignFirstResponderHostToCellControllers];
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UILabel *footerBackground = [[[UILabel alloc] init] autorelease];
    [footerBackground  setText:[tableFooters objectAtIndex:section]];	
    [footerBackground setBackgroundColor:[UIColor clearColor]];
    [footerBackground setTextAlignment:UITextAlignmentCenter];
    return  footerBackground;
}


#pragma mark -
#pragma mark Action methods
- (void)addCommentButtonPressed
{
    AddCommentViewController *viewController = [[AddCommentViewController alloc] initWithNodeRef:[NodeRef nodeRefFromCmisObjectId:self.cmisObjectId]];
    [viewController setDelegate:self];
    [self.navigationController pushViewController:viewController animated:YES];
    [viewController release];
}

#pragma mark - 
#pragma mark AddCommentViewDelegate
- (void) didSubmitComment:(NSString *)comment
{
    NSLog(@"Comment: %@", comment);
    CommentsHttpRequest *request = [CommentsHttpRequest commentsHttpGetRequestWithNodeRef:[NodeRef nodeRefFromCmisObjectId:self.cmisObjectId]];
    [request setDelegate:self];
    [request startAsynchronous];
}

- (void)requestFinished:(ASIHTTPRequest *)sender
{
    NSLog(@"commentsHttpRequestDidFinish");
    CommentsHttpRequest * request = (CommentsHttpRequest *)sender;
    [self setModel:[[[IFTemporaryModel alloc] initWithDictionary:request.commentsDictionary] autorelease]];
    [self updateAndReload];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSLog(@"commentsHttpRequestDidFail!");
}

@end
