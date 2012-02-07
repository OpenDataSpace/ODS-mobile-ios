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
//  MetaDataTableViewController.m
//

#import "MetaDataTableViewController.h"
#import "Theme.h"
#import "MetaDataCellController.h"
#import "IFTemporaryModel.h"
#import "IFMultilineCellController.h"
#import "PropertyInfo.h"
#import "IFTextCellController.h"
#import "NodeRef.h"
#import "Utility.h"
#import "IFButtonCellController.h"
#import "LinkRelationService.h"
#import "TableCellViewController.h"
#import "FileDownloadManager.h"
#import "RepositoryServices.h"
#import "FolderItemsHTTPRequest.h"
#import "VersionHistoryTableViewController.h"
#import "MBProgressHUD.h"
#import "AccountManager.h"

static NSArray * cmisPropertiesToDisplay = nil;
@interface MetaDataTableViewController(private)
-(void)startHUD;
-(void)stopHUD;
@end


@implementation MetaDataTableViewController
@synthesize delegate;
@synthesize cmisObjectId;
@synthesize metadata;
@synthesize propertyInfo;
@synthesize describedByURL;
@synthesize mode;
@synthesize tagsArray;
@synthesize taggingRequest;
@synthesize cmisObject;
@synthesize errorMessage;
@synthesize downloadMetadata;
@synthesize downloadProgressBar;
@synthesize versionHistoryRequest;
@synthesize isVersionHistory;
@synthesize HUD;
@synthesize selectedAccountUUID;
@synthesize tenantID;


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [taggingRequest clearDelegatesAndCancel];
    [versionHistoryRequest clearDelegatesAndCancel];
    
    [cmisObjectId release];
    [metadata release];
	[propertyInfo release];
    [describedByURL release];
    [mode release];
    [tagsArray release];
    [taggingRequest release];
    [cmisObject release];
    [errorMessage release];
    [downloadMetadata release];
    [downloadProgressBar release];
    [versionHistoryRequest release];
    [HUD release];
    [selectedAccountUUID release];
    [tenantID release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

+ (void)initialize {
    // TODO This should be externalized to the properties file
    if ( !cmisPropertiesToDisplay) {
        cmisPropertiesToDisplay = [[NSArray alloc] initWithObjects:@"cmis:createdBy", @"cmis:creationDate", 
                                   @"cmis:lastModifiedBy", @"cmis:lastModificationDate", @"cmis:name", @"cmis:versionLabel", nil];
        
    }
}

- (id)initWithStyle:(UITableViewStyle)style cmisObject:(RepositoryItem *)cmisObj accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        [self setMode:@"VIEW_MODE"];  // TODO... Constants // VIEW | EDIT | READONLY (?)
        [self setTagsArray:nil];
        [self setCmisObject:cmisObj];
        [self setSelectedAccountUUID:uuid];
        [self setTenantID:aTenantID];
    }
    return self;
}


#pragma mark - View lifecycle

- (void)viewDidUnload {
    [super viewDidUnload];
    
    self.tableView = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    BOOL usingAlfresco = [[AccountManager sharedManager] isAlfrescoAccountForAccountUUID:selectedAccountUUID];
    
    [Theme setThemeForUINavigationBar:self.navigationController.navigationBar];
    
    [self.navigationItem setTitle:[metadata objectForKey:@"cmis:name"]]; // XXX probably should check if value exists
    
    if ([self.mode isEqualToString:@"VIEW_MODE"]) {
        
        // TODO Check if editable
    
//        UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit 
//                                                                                    target:self 
//                                                                                    action:@selector(editButtonPressed)];
//        [self.navigationItem setRightBarButtonItem:editButton];
//        [editButton release];
    }
    else if ([self.mode isEqualToString:@"EDIT_MODE"]) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone 
                                                                                    target:self 
                                                                                    action:@selector(doneButtonPressed)];
        [self.navigationItem setRightBarButtonItem:doneButton];
        [doneButton release];
        
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
                                                                                      target:self action:@selector(cancelButtonPressed)];
        [self.navigationItem setLeftBarButtonItem:cancelButton animated:YES];
        [cancelButton release];
    }

    if (usingAlfresco) {
        @try {
            if(!errorMessage) {
                self.taggingRequest = [TaggingHttpRequest httpRequestGetNodeTagsForNode:[NodeRef nodeRefFromCmisObjectId:cmisObjectId] 
                                                                            accountUUID:selectedAccountUUID tenantID:self.tenantID];
                [self.taggingRequest setDelegate:self];
                [self.taggingRequest startAsynchronous];
            }
        }
        @catch (NSException *exception) {
            NSLog(@"FATAL: tagging request failed on viewDidload");
        }
        @finally {
        }
    }
}

#pragma mark -
#pragma mark ASIHTTPRequest

-(void)requestFinished:(TaggingHttpRequest *)request
{
    if([request isKindOfClass:[FolderItemsHTTPRequest class]]) {
        FolderItemsHTTPRequest *vhRequest = (FolderItemsHTTPRequest *)request;
        VersionHistoryTableViewController *controller = [[VersionHistoryTableViewController alloc] initWithStyle:UITableViewStyleGrouped 
                                                                                                  versionHistory:vhRequest.children 
                                                                                                     accountUUID:selectedAccountUUID 
                                                                                                        tenantID:self.tenantID];
        
        [self.navigationController pushViewController:controller animated:YES];
        [controller release];
        
    } else {
        NSArray *parsedTags = [TaggingHttpRequest tagsArrayWithResponseString:[request responseString] accountUUID:selectedAccountUUID];
        [self setTagsArray:parsedTags];
        [self updateAndReload];
    }
    
    [self stopHUD];
}

-(void)requestFailed:(TaggingHttpRequest *)request
{
    NSLog(@"Error from the request: %@", [request.error description]);
    [self stopHUD];
}

- (void)editButtonPressed {
    // DO NOTHING, Currently not being used
//    MetaDataTableViewController *viewController = [[MetaDataTableViewController alloc] initWithStyle:UITableViewStylePlain];
//    [viewController setMode:@"EDIT_MODE"];
//    [viewController setMetadata:[[self.metadata copy] autorelease]];
//    [viewController setPropertyInfo:[[self.propertyInfo copy] autorelease]];
//    [viewController setDescribedByURL:self.describedByURL];
//    [viewController setDelegate:self.delegate];
//    
//    [self.navigationController pushViewController:viewController animated:YES];
//    [viewController release];
}

- (void)doneButtonPressed {
    // NSLOG DO SOMETHING
    NSLog(@"DONE BUTTON PRESSED, EXECUTE A SAVE!");
    
    // Peform Save
    
    if (self.delegate) {
        [self.delegate tableViewController:self metadataDidChange:YES];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)cancelButtonPressed {
    
    if (self.delegate) {
        [self.delegate tableViewController:self metadataDidChange:NO];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
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


#pragma mark -
#pragma mark Generic Table View Construction

- (void)constructTableGroups
{
    if (![self.model isKindOfClass:[IFTemporaryModel class]]) {
        IFTemporaryModel *tempModel = [[IFTemporaryModel alloc] initWithDictionary:[NSMutableDictionary dictionaryWithDictionary:metadata]];
        [self setModel:tempModel];
        [tempModel release];
	}
    
    // Arrays for section headers, bodies and footers
	NSMutableArray *headers = [NSMutableArray array];
	NSMutableArray *groups =  [NSMutableArray array];
	NSMutableArray *footers = [NSMutableArray array];
    
    if(metadata) {
        NSMutableArray *metadataCellGroup = [NSMutableArray arrayWithCapacity:[metadata count]];
        
        NSArray *sortedKeys = [[metadata allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        for (NSString *key in sortedKeys) {
            
            if ( ! [cmisPropertiesToDisplay containsObject:key]) {
                // Skip - this is specific to Alfresco
                continue;
            }
            
            PropertyInfo *i = [self.propertyInfo objectForKey:key];
            
            NSString *displayKey = i.displayName ? i.displayName : key;
            displayKey = [NSString stringWithFormat:@"%@:", displayKey];
            
            if (self.mode && [self.mode isEqualToString:@"EDIT_MODE"]) { // TODO Externalize this string
                
                IFTextCellController *cellController = [[IFTextCellController alloc] initWithLabel:displayKey andPlaceholder:@"" 
                                                                                             atKey:key inModel:self.model];
                [metadataCellGroup addObject:cellController];
                [cellController release];
                
                // FIXME: IMPLEMENT ME
                
            } else {
                
                if ([i.propertyType isEqualToString:@"datetime"]) {
                    NSString *value = formatDateTime([model objectForKey:key]);
                    key = [key stringByAppendingString:@"Ex"];
                    [model setObject:value forKey:key];
                }
                
                MetaDataCellController *cellController = [[MetaDataCellController alloc] initWithLabel:displayKey 
                                                                                                 atKey:key inModel:self.model];
                [metadataCellGroup addObject:cellController];
                [cellController release];
            }
        }
        
        // TODO: Handle Edit MOde
        if (self.tagsArray && ([tagsArray count] > 0)) {
            [model setObject:([tagsArray componentsJoinedByString:@", "]) forKey:@"tags"];
            MetaDataCellController *tagsCellController = [[MetaDataCellController alloc] initWithLabel:@"Tags:" atKey:@"tags" inModel:self.model];
            [metadataCellGroup addObject:tagsCellController];
            [tagsCellController release];
        }
        
        [headers addObject:@""];
        [groups addObject:metadataCellGroup];
        [footers addObject:@""];
        
        NSMutableArray *versionsHistoryGroup = [NSMutableArray array];
        NSString *versionHistoryURI = [[LinkRelationService shared] hrefForLinkRelationString:@"version-history" onCMISObject:cmisObject];
        
        if(!isVersionHistory && versionHistoryURI) {
            IFButtonCellController *viewVersionHistoryButton = [[IFButtonCellController alloc] initWithLabel:NSLocalizedString(@"metadata.button.view.version.history", @"View Version History") 
                                                                                                  withAction:@selector(viewVersionHistoryButtonClicked) onTarget:self];
            [versionsHistoryGroup addObject:viewVersionHistoryButton];
            [viewVersionHistoryButton release];
            [headers addObject:@""];
            [groups addObject:versionsHistoryGroup];
            [footers addObject:@""];
        }
        
        
    } else if(errorMessage) {
        NSMutableArray *noMetadataGroup = [NSMutableArray arrayWithCapacity:1];
        TableCellViewController *cellController = [[TableCellViewController alloc] init];
        cellController.textLabel.text = errorMessage ;
        
        [noMetadataGroup addObject:cellController];
        [cellController release];
        
        [headers addObject:@""];
        [groups addObject:noMetadataGroup];
        [footers addObject:@""];
        
        [self.tableView setAllowsSelection:NO];
    }

    tableGroups = [groups retain];
	tableHeaders = [headers retain];
	tableFooters = [footers retain];
	[self assignFirstResponderHostToCellControllers];
}

- (void)viewVersionHistoryButtonClicked
{
    NSString *versionHistoryURI = [[LinkRelationService shared] hrefForLinkRelationString:@"version-history" onCMISObject:cmisObject];
    FolderItemsHTTPRequest *down = [[FolderItemsHTTPRequest alloc] initWithURL:[NSURL URLWithString:versionHistoryURI] accountUUID:selectedAccountUUID];
    [down setDelegate:self];
    [down setShow500StatusError:NO];
    [self setVersionHistoryRequest:down];
    [down startAsynchronous];
    [self startHUD];
    
    [down release];
}

#pragma mark -
#pragma mark DownloadProgressBarDelegate methods

- (void)redownloadButtonClicked
{
    NSURL *contentURL = [NSURL URLWithString:downloadMetadata.contentLocation];
    [self setDownloadProgressBar:[DownloadProgressBar createAndStartWithURL:contentURL delegate:self 
                                                                    message:NSLocalizedString(@"Downloading Document", @"Downloading Document")
                                                                   filename:downloadMetadata.filename 
                                                                accountUUID:selectedAccountUUID 
                                                                   tenantID:self.tenantID]];
    [[self downloadProgressBar] setCmisObjectId:downloadMetadata.objectId];
    [[self downloadProgressBar] setCmisContentStreamMimeType:downloadMetadata.contentStreamMimeType];
    [[self downloadProgressBar] setVersionSeriesId:downloadMetadata.versionSeriesId];
    
    RepositoryItem *item = [[RepositoryItem alloc] init];
    item.describedByURL = downloadMetadata.describedByUrl;
    item.metadata = [NSMutableDictionary dictionaryWithDictionary: downloadMetadata.metadata];
    [[self downloadProgressBar] setRepositoryItem:item];
    
    [item release];
}

- (void) download:(DownloadProgressBar *)down completeWithPath:(NSString *)filePath {
    DownloadMetadata *fileMetadata = down.downloadMetadata;
    [[FileDownloadManager sharedInstance] setDownload:fileMetadata.downloadInfo forKey:[filePath lastPathComponent] withFilePath:filePath];
    UIAlertView *saveConfirmationAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"documentview.download.confirmation.title", @"")
                                                                    message:NSLocalizedString(@"documentview.download.confirmation.message", @"The document has been saved to your device")
                                                                   delegate:nil 
                                                          cancelButtonTitle: @"Close" 
                                                          otherButtonTitles:nil, nil];
    [saveConfirmationAlert show];
    [saveConfirmationAlert release];
}

- (void) downloadWasCancelled:(DownloadProgressBar *)down {
    
    NSLog(@"Download was cancelled!");
}

#pragma mark -
#pragma mark MetaDataTableViewDelegate

- (void)tableViewController:(MetaDataTableViewController *)controller metadataDidChange:(BOOL)metadataDidChange
{
    // TODO
    
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

- (void) cancelActiveConnection:(NSNotification *) notification {
    NSLog(@"applicationWillResignActive in MetaDataTableViewController");
    [taggingRequest clearDelegatesAndCancel];
    [versionHistoryRequest cancel];
}


@end
