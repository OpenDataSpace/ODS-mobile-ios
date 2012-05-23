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
//  RepositoryNodeViewController.m
//

#import "CMISTypeDefinitionHTTPRequest.h"
#import "RepositoryNodeViewController.h"
#import "DocumentViewController.h"
#import "RepositoryItemTableViewCell.h"
#import "Utility.h"
#import "RepositoryItem.h"
#import "NSData+Base64.h"
#import "UIImageUtils.h"
#import "Theme.h"
#import "AppProperties.h"
#import "RepositoryServices.h"
#import "LinkRelationService.h"
#import "MetaDataTableViewController.h"
#import "IFTemporaryModel.h"
#import "FileUtils.h"
#import "IpadSupport.h"
#import "ThemeProperties.h"
#import "TransparentToolbar.h"
#import "DownloadInfo.h"
#import "FileDownloadManager.h"
#import "FolderDescendantsRequest.h"
#import "CMISSearchHTTPRequest.h"
#import "DownloadMetadata.h"
#import "NSString+Utils.h"
#import "AssetUploadItem.h"
#import "UploadHelper.h"
#import "UploadInfo.h"
#import "AGImagePickerController.h"
#import "ProgressPanelView.h"
#import "UploadProgressTableViewCell.h"
#import "RepositoryItemCellWrapper.h"
#import "UploadsManager.h"
#import "CMISUploadFileHTTPRequest.h"
#import "FailedUploadDetailViewController.h"

NSInteger const kDownloadFolderAlert = 1;
NSInteger const kCancelUploadPrompt = 2;
NSInteger const kDismissFailedUploadPrompt = 3;
UITableViewRowAnimation const kDefaultTableViewRowAnimation = UITableViewRowAnimationRight;

@interface RepositoryNodeViewController (PrivateMethods)
- (void)initRepositoryItems;
- (void)addUploadsToRepositoryItems:(NSArray *)uploads insertCells:(BOOL)insertCells;
- (void)initSearchResultItems;
- (void)loadRightBar;
- (void)cancelAllHTTPConnections;
- (void)presentModalViewControllerHelper:(UIViewController *)modalViewController;
- (void)dismissModalViewControllerHelper;
- (void)startHUD;
- (void)stopHUD;
- (void)downloadAllDocuments;
- (void)downloadAllCheckOverwrite:(NSArray *)allItems;
- (void)prepareDownloadAllDocuments;
- (void)continueDownloadFromAlert: (UIAlertView *) alert clickedButtonAtIndex:(NSInteger)buttonIndex;
- (void)overwritePrompt: (NSString *) filename;
- (void)noFilesToDownloadPrompt;
- (void)fireNotificationAlert: (NSString *) message;
- (void)loadAudioUploadForm;
- (void)presentUploadFormWithItem:(UploadInfo *)uploadInfo andHelper:(id<UploadHelper>)helper;
- (void)presentUploadFormWithMultipleItems:(NSArray *)infos andUploadType:(UploadFormType)uploadType;
- (UploadInfo *)uploadInfoFromAsset:(ALAsset *)asset;
- (UploadInfo *)uploadInfoFromURL:(NSURL *)fileURL;
@end

@implementation RepositoryNodeViewController

@synthesize guid;
@synthesize folderItems;
@synthesize metadataDownloader;
@synthesize downloadProgressBar;
@synthesize downloadQueueProgressBar;
@synthesize postProgressBar;
@synthesize itemDownloader;
@synthesize folderDescendantsRequest;
@synthesize contentStream;
@synthesize popover;
@synthesize alertField;
@synthesize HUD;
@synthesize searchController;
@synthesize searchRequest;
@synthesize photoSaver;
@synthesize tableView = _tableView;
@synthesize repositoryItems = _repositoryItems;
@synthesize searchResultItems = _searchResultItems;
@synthesize uploadToCancel = _uploadToCancel;
@synthesize uploadToDismiss = _uploadToDismiss;
@synthesize selectedAccountUUID;
@synthesize tenantID;
@synthesize actionSheetSenderControl = _actionSheetSenderControl;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self cancelAllHTTPConnections];
    
	[guid release];
	[folderItems release];
    [metadataDownloader release];
	[downloadProgressBar release];
    [downloadQueueProgressBar release];
	[itemDownloader release];
    [folderDescendantsRequest release];
	[contentStream release];
	[popover release];
	[alertField release];
    [selectedIndex release];
    [willSelectIndex release];
    [HUD release];
    [searchController release];
    [searchRequest release];
    [photoSaver release];
    [_tableView release];
    [_repositoryItems release];
    [_searchResultItems release];
    [_uploadToCancel release];
    [_uploadToDismiss release];
    [selectedAccountUUID release];
    [tenantID release];
    [_actionSheetSenderControl release];
    
    [super dealloc];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super init];
    if(self)
    {
        _tableViewStyle = style;
        [self setRepositoryItems:[NSMutableArray array]];
        [self setSearchResultItems:[NSMutableArray array]];
    }
    return self;
}

- (void)loadView
{
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:_tableViewStyle];
    [tableView setDelegate:self];
    [tableView setDataSource:self];
    [tableView setAutoresizesSubviews:YES];
    [tableView setAutoresizingMask:UIViewAutoresizingNone];
    [self setView:tableView];
    [self setTableView:tableView];
    [tableView release];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
    UITableView *tableView;
    if([searchController isActive]) {
        tableView = [searchController searchResultsTableView];
    } else {
        tableView = self.tableView;
    }
    NSIndexPath *selectedRow = [tableView indexPathForSelectedRow];
    
    //Retrieving the selectedItem. We want to deselect a folder when the view appears even if we're on the iPad
    // We only set it when working in the main tableView since the search doesn't return folders
    RepositoryItem *selectedItem = nil;
    if(selectedRow && [tableView isEqual:self.tableView])
    {
        RepositoryItemCellWrapper *cellWrapper = [self.repositoryItems objectAtIndex:selectedRow.row];
        selectedItem = [cellWrapper repositoryItem];
    }
    
    if(!IS_IPAD || [selectedItem isFolder] ) {
        [[self tableView] deselectRowAtIndexPath:selectedRow animated:YES];
        [self.searchController.searchResultsTableView deselectRowAtIndexPath:selectedRow animated:YES];
    }

    [willSelectIndex release];
    willSelectIndex = nil;
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
	
	replaceData = NO;
    [self loadRightBar];

	[Theme setThemeForUIViewController:self];

    [self.tableView setRowHeight:kDefaultTableCellHeight];
    
    //Contextual Search view
    UISearchBar * theSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0,0,320,40)]; // frame has no effect.
    [theSearchBar setTintColor:[ThemeProperties toolbarColor]];
    [theSearchBar setShowsCancelButton:YES];
    [theSearchBar setDelegate:self];
    [theSearchBar setShowsCancelButton:NO animated:NO];
    [self.tableView setTableHeaderView:theSearchBar];
    
    UISearchDisplayController *searchCon = [[UISearchDisplayController alloc]
                                            initWithSearchBar:theSearchBar contentsController:self];
    self.searchController = searchCon;
    [searchCon release];
    [searchController setDelegate:self];
    [searchController setSearchResultsDelegate:self];
    [searchController setSearchResultsDataSource:self];
    [searchController.searchResultsTableView setRowHeight:kDefaultTableCellHeight];
    
    [self initRepositoryItems];
    
    //[searchController setActive:YES animated:YES];
    //[theSearchBar becomeFirstResponder];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadQueueChanged:) name:kNotificationUploadQueueChanged object:nil];
}


- (void) viewDidUnload {
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.tableView = nil;
    self.contentStream = nil;
    [self.popover dismissPopoverAnimated:NO];
    self.popover = nil;
    self.alertField = nil;
    [self stopHUD];
    
    [self cancelAllHTTPConnections];
}

- (void)cancelAllHTTPConnections
{    
    [folderItems clearDelegatesAndCancel];
    [metadataDownloader clearDelegatesAndCancel];
    [[downloadProgressBar httpRequest] clearDelegatesAndCancel];
    [itemDownloader clearDelegatesAndCancel];
    [folderDescendantsRequest clearDelegatesAndCancel];
    [searchRequest clearDelegatesAndCancel];
    [self stopHUD];
}

- (void)initRepositoryItems
{
    NSMutableArray *allItems = [NSMutableArray arrayWithCapacity:[[folderItems children] count]];
    for(RepositoryItem *child in [folderItems children])
    {
        RepositoryItemCellWrapper *cellWrapper = [[RepositoryItemCellWrapper alloc] initWithRepositoryItem:child];
        [cellWrapper setItemTitle:child.title];
        [allItems addObject:cellWrapper];
        [cellWrapper release];
    }
    
    [self setRepositoryItems:allItems];
    NSArray *activeUploads = [[UploadsManager sharedManager] uploadsInUplinkRelation:[[self.folderItems item] identLink]];
    [self addUploadsToRepositoryItems:activeUploads insertCells:NO];
}

- (void)addUploadsToRepositoryItems:(NSArray *)uploads insertCells:(BOOL)insertCells
{
    for(UploadInfo *uploadInfo in uploads)
    {
        RepositoryItemCellWrapper *cellWrapper = [[RepositoryItemCellWrapper alloc] initWithUploadInfo:uploadInfo];
        [cellWrapper setItemTitle:[uploadInfo completeFileName]];
        
        NSComparator comparator = ^(RepositoryItemCellWrapper *obj1, RepositoryItemCellWrapper *obj2) {
            
            return (NSComparisonResult)[obj1.itemTitle caseInsensitiveCompare:obj2.itemTitle];
        };
        
        NSUInteger newIndex = [self.repositoryItems indexOfObject:cellWrapper
                                     inSortedRange:(NSRange){0, [self.repositoryItems count]}
                                           options:NSBinarySearchingInsertionIndex
                                   usingComparator:comparator];
        [self.repositoryItems insertObject:cellWrapper atIndex:newIndex];
        [cellWrapper release];
    }
    
    if(insertCells)
    {
        NSMutableArray *newIndexPaths = [NSMutableArray arrayWithCapacity:[uploads count]];
        // We get the final index of all of the inserted uploads
        for(UploadInfo *uploadInfo in uploads)
        {
            NSUInteger index = [self.repositoryItems indexOfObjectPassingTest:^BOOL(RepositoryItemCellWrapper *obj, NSUInteger idx, BOOL *stop) {
                if([obj.uploadInfo isEqual:uploadInfo])
                {
                    *stop = YES;
                    return YES;
                }
                
                return NO;
            }];
            [newIndexPaths addObject:[NSIndexPath indexPathForRow:index inSection:0]];
        }
        //[self.tableView reloadData];
        [self.tableView insertRowsAtIndexPaths:newIndexPaths withRowAnimation:kDefaultTableViewRowAnimation];
        [self.tableView scrollToRowAtIndexPath:[newIndexPaths lastObject] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    }
}

- (void)initSearchResultItems
{
    NSMutableArray *searchResults = [NSMutableArray array];
    
    if([searchRequest.results count] > 0)
    {
        for(RepositoryItem *result in [searchRequest results])
        {
            RepositoryItemCellWrapper *cellWrapper = [[RepositoryItemCellWrapper alloc] initWithRepositoryItem:result];
            [cellWrapper setItemTitle:result.title];
            [searchResults addObject:cellWrapper];
            [cellWrapper release];
        }
    }
    else 
    {
        RepositoryItemCellWrapper *cellWrapper = [[RepositoryItemCellWrapper alloc] initWithRepositoryItem:nil];
        [cellWrapper setIsSearchError:YES];
        [cellWrapper setSearchStatusCode:searchRequest.responseStatusCode];
        [searchResults addObject:cellWrapper];
        [cellWrapper release];
    }
    
    [self setSearchResultItems:searchResults];
}

- (void)loadRightBar 
{
    UIBarButtonItem *reloadButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
                                                                                   target:self action:@selector(reloadFolderAction)] autorelease];
    [reloadButton setStyle:UIBarButtonItemStyleBordered];
    
    BOOL showAddButton = [[AppProperties propertyForKey:kBShowAddButton] boolValue];
    BOOL showDownloadFolderButton = [[AppProperties propertyForKey:kBShowDownloadFolderButton] boolValue];
    BOOL showSecondButton = ((showAddButton && nil != [folderItems item] && ([folderItems item].canCreateFolder || [folderItems item].canCreateDocument)) || showDownloadFolderButton);
    
    //We only show the second button if any option is going to be displayed
    if(showSecondButton) {
        // There is no "official" way to know the width of the UIBarButtonItem
        // This is the closest value we got. If we use a bigger width in the 
        // toolbar we take space from the NavigationController title
        CGFloat width = 35;
        
        TransparentToolbar *rightBarToolbar = [[TransparentToolbar alloc] initWithFrame:CGRectMake(0, 0, width*2+10, 44.01)];
        UIBarButtonItem *flexibleSpace = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
        
        NSMutableArray *rightBarButtons = [NSMutableArray arrayWithObjects: flexibleSpace,reloadButton, nil];
        
        //Select the appropiate button item
        UIBarButtonItem *actionButton = nil;
        if(showDownloadFolderButton) {
            actionButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(performAction:)] autorelease];
        } else {
            actionButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(performAction:)] autorelease];
        }
        
        actionButton.style = UIBarButtonItemStyleBordered;
        [rightBarButtons addObject:actionButton];
        rightBarToolbar.tintColor = [ThemeProperties toolbarColor];
        rightBarToolbar.items = rightBarButtons;
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:rightBarToolbar] autorelease];
        [rightBarToolbar release];
    }
    else {
        [[self navigationItem] setRightBarButtonItem:reloadButton];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)performAction:(id)sender {
	if (IS_IPAD) {
		if(nil != popover && [popover isPopoverVisible]) {
			[popover dismissPopoverAnimated:YES];
            [self setPopover:nil];
		}
	}

    UIActionSheet *sheet = [[UIActionSheet alloc]
                            initWithTitle:@""
                            delegate:self 
                            cancelButtonTitle:nil
                            destructiveButtonTitle:nil 
                            otherButtonTitles: nil];
    BOOL showAddButton = [[AppProperties propertyForKey:kBShowAddButton] boolValue];
    
    if (showAddButton && folderItems.item.canCreateFolder) {
		[sheet addButtonWithTitle:NSLocalizedString(@"add.actionsheet.create-folder", @"Create Folder")];
	}
    
	if (showAddButton && folderItems.item.canCreateDocument) {
        NSArray *sourceTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
		BOOL hasCamera = [sourceTypes containsObject:(NSString *) kUTTypeImage];
        BOOL canCaptureVideo = [sourceTypes containsObject:(NSString *) kUTTypeMovie];
        
        [sheet addButtonWithTitle:NSLocalizedString(@"add.actionsheet.upload", @"Upload")];
        
		if (hasCamera && canCaptureVideo) {
            [sheet addButtonWithTitle:NSLocalizedString(@"add.actionsheet.take-photo-video", @"Take Photo or Video")];
		}
        else if (hasCamera) 
        {
			[sheet addButtonWithTitle:NSLocalizedString(@"add.actionsheet.take-photo", @"Take Photo")];
        }
        
        [sheet addButtonWithTitle:@"Record Audio"];
	}
	
    BOOL showDownloadFolderButton = [[AppProperties propertyForKey:kBShowDownloadFolderButton] boolValue];
    if(showDownloadFolderButton) {
        [sheet addButtonWithTitle:NSLocalizedString(@"add.actionsheet.download-folder", @"Download all documents")];
    }
    
	[sheet setCancelButtonIndex:[sheet addButtonWithTitle:NSLocalizedString(@"add.actionsheet.cancel", @"Cancel")]];
    
    if(IS_IPAD) {
        [self setActionSheetSenderControl:sender];
        [sheet setActionSheetStyle:UIActionSheetStyleDefault];
        [sheet showFromBarButtonItem:sender animated:YES];
        [(UIBarButtonItem *)sender setEnabled:NO];
    } else {
        [sheet showInView:[[self tabBarController] view]];
    }
	
	[sheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex 
{
	NSString *buttonLabel = [actionSheet buttonTitleAtIndex:buttonIndex];
    [actionSheet dismissWithClickedButtonIndex:0 animated:YES];
    [self.actionSheetSenderControl setEnabled:YES];
    
	if (![buttonLabel isEqualToString:NSLocalizedString(@"add.actionsheet.cancel", @"Cancel")]) 
    {
        
        // TODO
        // Re-implement using a switch and button indices.  
        //
        
        if ([buttonLabel isEqualToString:@"Upload a Photo"]) 
        {
            UploadInfo *uploadInfo = [[[UploadInfo alloc] init] autorelease];
            [uploadInfo setUploadType:UploadFormTypePhoto];
            [self presentUploadFormWithItem:uploadInfo andHelper:nil];
        }
		else if ([buttonLabel isEqualToString:NSLocalizedString(@"add.actionsheet.choose-photo", @"Choose Photo from Library")]) {                        
            AGImagePickerController *imagePickerController = [[AGImagePickerController alloc] initWithFailureBlock:^(NSError *error) 
            {
                NSLog(@"Fail. Error: %@", error);
                
                if (error == nil) 
                {
                    NSLog(@"User has cancelled.");
                    [self dismissModalViewControllerHelper];
                } 
                else 
                {
                    
                    // We need to wait for the view controller to appear first.
                    double delayInSeconds = 0.5;
                    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        [self dismissModalViewControllerHelper];
                    });
                }
                
                [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
                
            } andSuccessBlock:^(NSArray *info) 
            {
                [self startHUD];
                NSLog(@"User finished picking the library assets: %@", info);
                [self dismissModalViewControllerHelper];
                
                if([info count] == 1)
                {
                    ALAsset *asset = [info lastObject];
                    UploadInfo *uploadInfo = [self uploadInfoFromAsset:asset];
                    [self presentUploadFormWithItem:uploadInfo andHelper:[uploadInfo uploadHelper]];
                } 
                else if([info count] > 1)
                {
                    NSMutableArray *uploadItems = [NSMutableArray arrayWithCapacity:[info count]];
                    for (ALAsset *asset in info) {
                        [uploadItems addObject:[self uploadInfoFromAsset:asset]];
                    }
                    
                    [self presentUploadFormWithMultipleItems:uploadItems andUploadType:UploadFormTypeLibrary];
                }
                
                [self stopHUD];
                [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
            }];
            
            [imagePickerController setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
            [self presentModalViewControllerHelper:imagePickerController];
            [imagePickerController release];
            
		}
        else if ([buttonLabel isEqualToString:NSLocalizedString(@"add.actionsheet.take-photo", @"Take Photo")] || [buttonLabel isEqualToString:NSLocalizedString(@"add.actionsheet.take-photo-video", @"Take Photo or Video")]) 
        {
			UIImagePickerController *picker = [[UIImagePickerController alloc] init];
			[picker setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
			[picker setSourceType:UIImagePickerControllerSourceTypeCamera];
            [picker setMediaTypes:[UIImagePickerController availableMediaTypesForSourceType:picker.sourceType]];
			[picker setDelegate:self];
			
			[self presentModalViewControllerHelper:picker];
			
			[picker release];
            
		}
        else if ([buttonLabel isEqualToString:NSLocalizedString(@"add.actionsheet.create-folder", @"Create Folder")]) 
        {
			UIAlertView *alert = [[UIAlertView alloc] 
								  initWithTitle:NSLocalizedString(@"add.create-folder.prompt.title", @"Name: ")
								  message:@" \r\n "
								  delegate:self 
								  cancelButtonTitle:NSLocalizedString(@"closeButtonText", @"Cancel Button Text")
								  otherButtonTitles:NSLocalizedString(@"okayButtonText", @"OK Button Text"), nil];
            
			self.alertField = [[[UITextField alloc] initWithFrame:CGRectMake(12.0, 45.0, 260.0, 25.0)] autorelease];
			[alertField setBackgroundColor:[UIColor whiteColor]];
			[alert addSubview:alertField];
			[alert show];
			[alert release];
		} 
        else if([buttonLabel isEqualToString:NSLocalizedString(@"add.actionsheet.upload-document", @"Upload Document from Saved Docs")]) 
        {
            
            SavedDocumentPickerController *picker = [[SavedDocumentPickerController alloc] initWithMultiSelection:YES];
			[picker setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
			[picker setDelegate:self];
            
            [self presentModalViewControllerHelper:picker];
            [picker release];
        } 
        else if([buttonLabel isEqualToString:@"Record Audio"]) 
        {
            [self loadAudioUploadForm];
        }
        else if([buttonLabel isEqualToString:NSLocalizedString(@"add.actionsheet.download-folder", @"Download all documents")]) 
        {
            [self prepareDownloadAllDocuments];
        }
        else if ([buttonLabel isEqualToString:NSLocalizedString(@"add.actionsheet.upload", @"Upload")]) {
            UIActionSheet *sheet = [[UIActionSheet alloc]
                                    initWithTitle:@""
                                    delegate:self 
                                    cancelButtonTitle:nil
                                    destructiveButtonTitle:nil 
                                    otherButtonTitles: NSLocalizedString(@"add.actionsheet.choose-photo", @"Choose Photo from Library"), NSLocalizedString(@"add.actionsheet.upload-document", @"Upload Document"), nil];
            
            [sheet setCancelButtonIndex:[sheet addButtonWithTitle:NSLocalizedString(@"add.actionsheet.cancel", @"Cancel")]];
            if(IS_IPAD) 
            {
                [sheet setActionSheetStyle:UIActionSheetStyleDefault];
                [sheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem  animated:YES];
            } 
            else 
            {
                [sheet showInView:[[self tabBarController] view]];
            }
            
            [sheet release];
        }
	}
}

- (void) presentModalViewControllerHelper:(UIViewController *)modalViewController {
    if (IS_IPAD) {
        UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:modalViewController];
        [self setPopover:popoverController];
        [popoverController release];
        
        [popover presentPopoverFromBarButtonItem:self.actionSheetSenderControl
                        permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    } else  {
        [[self navigationController] presentModalViewController:modalViewController animated:YES];
    }
}

- (void)dismissModalViewControllerHelper
{
    if (IS_IPAD) 
    {
		if(nil != popover && [popover isPopoverVisible]) {
			[popover dismissPopoverAnimated:YES];
            [self setPopover:nil];
		}
	}
    else 
    {
        [self dismissModalViewControllerAnimated:YES];
    }
}

#pragma mark - Download all items in folder methods

- (void)prepareDownloadAllDocuments 
{    
    BOOL downloadFolderTree = [[AppProperties propertyForKey:kBDownloadFolderTree] boolValue];
    if(downloadFolderTree) {
        [self startHUD];
        
        FolderDescendantsRequest *down = [FolderDescendantsRequest folderDescendantsRequestWithItem:[folderItems item] accountUUID:selectedAccountUUID];
        [self setFolderDescendantsRequest:down];
        [down setDelegate:self];
        [down startAsynchronous];
    } else {
        NSMutableArray *allDocuments = [NSMutableArray arrayWithCapacity:[self.repositoryItems count]];
        for (RepositoryItemCellWrapper *cellWrapper in self.repositoryItems) {
            if(cellWrapper.repositoryItem)
            {
                [allDocuments addObject:cellWrapper.repositoryItem];
            } 
            else if(cellWrapper.uploadInfo.repositoryItem)
            {
                [allDocuments addObject:cellWrapper.uploadInfo.repositoryItem];
            }
        }
        
        [self downloadAllCheckOverwrite:allDocuments];
    }
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    [self.tableView setAllowsSelection:YES];

    if([request isKindOfClass:[FolderDescendantsRequest class]]) 
    {
        FolderDescendantsRequest *fdr = (FolderDescendantsRequest *)request;
        [self downloadAllCheckOverwrite:[fdr folderDescendants]];
    } 
    else if ([request isKindOfClass:[CMISSearchHTTPRequest class]]) 
    {
        [self initSearchResultItems];
        [[searchController searchResultsTableView] reloadData];
    } 
    else if ([request isKindOfClass:[CMISTypeDefinitionHTTPRequest class]]) 
    {
		CMISTypeDefinitionHTTPRequest *tdd = (CMISTypeDefinitionHTTPRequest *) request;
        MetaDataTableViewController *viewController = [[MetaDataTableViewController alloc] initWithStyle:UITableViewStylePlain 
                                                                                              cmisObject:[tdd repositoryItem] 
                                                                                             accountUUID:[tdd accountUUID] 
                                                                                                tenantID:self.tenantID];
        [viewController setCmisObjectId:tdd.repositoryItem.guid];
        [viewController setMetadata:tdd.repositoryItem.metadata];
        [viewController setPropertyInfo:tdd.properties];
        [viewController setSelectedAccountUUID:selectedAccountUUID];
        
        [IpadSupport pushDetailController:viewController withNavigation:self.navigationController andSender:self];
        [viewController release];
	} 
    
    [self stopHUD];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    [self.tableView setAllowsSelection:YES];

    if ([request isKindOfClass:[CMISSearchHTTPRequest class]]) {
        [[searchController searchResultsTableView] reloadData];
    }

    [self stopHUD];
}

- (void) downloadAllCheckOverwrite:(NSArray *)allItems {
    RepositoryItem *child;
    [childsToDownload release];
    childsToDownload = [[NSMutableArray array] retain];
    [childsToOverwrite release];
    childsToOverwrite = [[NSMutableArray array] retain];
    
    for(child in allItems) {
        if(![child isFolder]) {
            if([[NSFileManager defaultManager] fileExistsAtPath:[FileUtils pathToSavedFile:child.title]]) {
                [childsToOverwrite addObject:child];
            } else {
                [childsToDownload addObject:child];
            }
        }
    }
    
    [self downloadAllDocuments];
}

- (void) overwritePrompt: (NSString *) filename { 
    UIAlertView *overwritePrompt = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"documentview.overwrite.download.prompt.title", @"")
                                message:[NSString stringWithFormat:NSLocalizedString(@"documentview.overwrite.filename.prompt.message", @"Yes/No Question"), filename]
                               delegate:self 
                      cancelButtonTitle:NSLocalizedString(@"No", @"No Button Text") 
                      otherButtonTitles:NSLocalizedString(@"Yes", @"Yes BUtton Text"), nil] autorelease];
    [overwritePrompt setTag:kDownloadFolderAlert];
    [overwritePrompt show];
}

- (void) noFilesToDownloadPrompt {
    UIAlertView *noFilesToDownloadPrompt = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"documentview.overwrite.download.prompt.title", @"")
                                                               message:NSLocalizedString(@"documentview.download.noFilesToDownload", @"There are no files to download")
                                                              delegate:nil 
                                                             cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK")
                                                     otherButtonTitles:nil] autorelease];
    [noFilesToDownloadPrompt show];
}

- (void) downloadAllDocuments {
    if([childsToOverwrite count] > 0) {
        RepositoryItem *lastChild = [childsToOverwrite lastObject];
        [self overwritePrompt:lastChild.title];
        return;
    }
    
    if([childsToDownload count] <= 0) {
        [self noFilesToDownloadPrompt];
    } else {
        NSLog(@"Begin downloading %d files", [childsToDownload count]);
        //download all childs
        self.downloadQueueProgressBar = [DownloadQueueProgressBar createWithNodes:childsToDownload delegate:self andMessage:NSLocalizedString(@"Downloading Document", @"Downloading Document")];
        [downloadQueueProgressBar setSelectedUUID:selectedAccountUUID];
        [self.downloadQueueProgressBar startDownloads];
    }
}

- (void) continueDownloadFromAlert: (UIAlertView *) alert clickedButtonAtIndex:(NSInteger)buttonIndex {
    RepositoryItem *lastChild = [childsToOverwrite lastObject];
    [childsToOverwrite removeObject:lastChild];
    
    if (buttonIndex != alert.cancelButtonIndex) {
        [childsToDownload addObject:lastChild];
    }
    
    [self downloadAllDocuments];
}

#pragma mark AudioRecorderDialogDelegate methods
- (void) loadAudioUploadForm {
    UploadInfo *uploadInfo = [[[UploadInfo alloc] init] autorelease];
    [uploadInfo setUploadType:UploadFormTypeAudio];
    [self presentUploadFormWithItem:uploadInfo andHelper:nil];
}

#pragma mark DownloadQueueDelegate

- (void) downloadQueue:(DownloadQueueProgressBar *)down completeDownloads:(NSArray *)downloads {
    //NSLog(@"Download Queue completed!");
    DownloadInfo *download;
    NSInteger successCount = 0;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    for(download in downloads) {
        if([download isCompleted] && [fileManager fileExistsAtPath:download.tempFilePath]) {
            successCount++;
            DownloadMetadata *metadata = download.downloadMetadata;
            [[FileDownloadManager sharedInstance] setDownload:metadata.downloadInfo forKey:metadata.key withFilePath:[download.tempFilePath lastPathComponent]];
        }
    }
    
    NSString *message = nil;
    
    if(successCount == [childsToDownload count]) {
        message = NSLocalizedString(@"browse.downloadFolder.success", @"All documents had been saved to your device");
    } else if(successCount != 0) {
        NSString *plural = successCount == 1 ? @"" : @"s";
        NSString *format = NSLocalizedString(@"browse.downloadFolder.partialSuccess", @"All but x documents had been saved to your device");
        NSInteger documentsMissed = [childsToDownload count] - successCount;
        message = [NSString stringWithFormat:format, documentsMissed, plural];
    } else {
        message = NSLocalizedString(@"browse.downloadFolder.failed", @"Could not download any document to your device");
    }
    
    [self fireNotificationAlert:message];
    self.downloadQueueProgressBar = nil;
    NSLog(@"%d downloads successful", successCount);
}

- (void) downloadQueueWasCancelled:(DownloadQueueProgressBar *)down {
    [self fireNotificationAlert:@"browse.downloadFolder.failed"];
    self.downloadQueueProgressBar = nil;
}

- (void) fireNotificationAlert:(NSString *)message {
    UIAlertView *notificationAlert = [[[UIAlertView alloc] initWithTitle:@""
                                                                       message:message
                                                                      delegate:nil 
                                                             cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK")
                                                             otherButtonTitles:nil] autorelease];
    [notificationAlert show];
}

#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info 
{
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
    [picker dismissModalViewControllerAnimated:YES];
    if (IS_IPAD) {
		if(nil != popover && [popover isPopoverVisible]) {
			[popover dismissPopoverAnimated:YES];
            [self setPopover:nil];
		}
	}
    
    //When we take an image with the camera we should add manually the EXIF metadata
    if([mediaType isEqualToString:(NSString *) kUTTypeImage])
    {
        //The PhotoCaptureSaver will save the image with metadata into the user's camera roll
        //and return the url to the asset
        [self startHUD];
        [self setPhotoSaver:[[[PhotoCaptureSaver alloc] initWithPickerInfo:info andDelegate:self] autorelease]];
        [self.photoSaver startSavingImage];
    } 
    else if ([mediaType isEqualToString:(NSString *)kUTTypeVideo] || [mediaType isEqualToString:(NSString *)kUTTypeMovie]) 
    {   
        NSURL *mediaURL = [info objectForKey:UIImagePickerControllerMediaURL];
        UploadInfo *videoUpload = [[[UploadInfo alloc] init] autorelease];
        [videoUpload setUploadFileURL:mediaURL];
        [videoUpload setUploadType:UploadFormTypeVideo];
        [self presentUploadFormWithItem:videoUpload andHelper:nil];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker 
{
	[picker dismissModalViewControllerAnimated:YES];
    if (IS_IPAD) {
		if(nil != popover && [popover isPopoverVisible]) {
			[popover dismissPopoverAnimated:YES];
            [self setPopover:nil];
		}
	}
}

- (void)photoCaptureSaver:(PhotoCaptureSaver *)photoSaver didFinishSavingWithAssetURL:(NSURL *)assetURL
{
    NSLog(@"Image saved into the camera roll");
    AssetUploadItem *assetUploadHelper =  [[[AssetUploadItem alloc] initWithAssetURL:assetURL] autorelease];
    [assetUploadHelper createPreview:^(NSURL *previewURL) {
        UploadInfo *uploadInfo = [[[UploadInfo alloc] init] autorelease];
        [uploadInfo setUploadFileURL:previewURL];
        [uploadInfo setUploadType:UploadFormTypePhoto];
        [self presentUploadFormWithItem:uploadInfo andHelper:assetUploadHelper];;
        [self stopHUD];
    }];
}

- (void)photoCaptureSaver:(PhotoCaptureSaver *)photoSaver didFailWithError:(NSError *)error
{
    NSLog(@"Error trying to save the image in the camera roll %@", error  );
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle: @"Save failed"
                          message: @"Failed to save image"\
                          delegate: nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
    [alert show];
    [alert release];
    [self stopHUD];
}

- (void)didPresentAlertView:(UIAlertView *)alertView {
	[alertField becomeFirstResponder];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    
    if (IS_IPAD) {
		if(nil != popover && [popover isPopoverVisible]) {
			[popover dismissPopoverAnimated:YES];
            [self setPopover:nil];
		}
	}
    
    if(alertView.tag == kDownloadFolderAlert) 
    {
        [self continueDownloadFromAlert:alertView clickedButtonAtIndex:buttonIndex];
        return;
    }
    
    if(alertView.tag == kCancelUploadPrompt) 
    {
        UploadInfo *uploadInfo = [self.uploadToCancel uploadInfo];
        if(buttonIndex != alertView.cancelButtonIndex && ([uploadInfo uploadStatus] == UploadInfoStatusActive || [uploadInfo uploadStatus] == UploadInfoStatusUploading))
        {
            // We MUST remove the cell before clearing the upload in the manager
            // since every time the queue changes we listen to the notification ploand also try to remove it there (see: uploadQueueChanged:)
            NSUInteger index = [self.repositoryItems indexOfObject:self.uploadToCancel];
            [self.repositoryItems removeObjectAtIndex:index];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:kDefaultTableViewRowAnimation];
            
            [[UploadsManager sharedManager] clearUpload:uploadInfo.uuid];
        }
        
        return;
    }
    if(alertView.tag == kDismissFailedUploadPrompt)
    {
        if(buttonIndex != alertView.cancelButtonIndex)
        {
            [[UploadsManager sharedManager] clearUpload:self.uploadToDismiss.uuid];
        }
    }
    
	NSString *userInput = [alertField text];
	NSString *strippedUserInput = [userInput stringByReplacingOccurrencesOfString:@" " withString:@""];
	self.alertField = nil;
	
	if (1 == buttonIndex && [strippedUserInput length] > 0) {
		if (nil != contentStream) {
			NSString *postBody  = [NSString stringWithFormat:@""
								   "<?xml version=\"1.0\" ?>"
								   "<entry xmlns=\"http://www.w3.org/2005/Atom\" xmlns:app=\"http://www.w3.org/2007/app\" xmlns:cmisra=\"http://docs.oasis-open.org/ns/cmis/restatom/200908/\">"
								   "<cmisra:content>"
								   "<cmisra:mediatype>image/png</cmisra:mediatype>"
								   "<cmisra:base64>%@</cmisra:base64>"
								   "</cmisra:content>"
								   "<cmisra:object xmlns:cmis=\"http://docs.oasis-open.org/ns/cmis/core/200908/\">"
								   "<cmis:properties>"
								   "<cmis:propertyId propertyDefinitionId=\"cmis:objectTypeId\">"
								   "<cmis:value>cmis:document</cmis:value>"
								   "</cmis:propertyId>"
								   "</cmis:properties>"
								   "</cmisra:object><title>%@.png</title></entry>",
								   [contentStream base64EncodedString],
								   userInput
								   ];
			NSLog(@"POSTING DATA: %@", postBody);
			self.contentStream = nil;
			
			RepositoryItem *item = [folderItems item];
			NSString *location   = [item identLink];
			NSLog(@"TO LOCATION: %@", location);
			
			self.postProgressBar = 
			[PostProgressBar createAndStartWithURL:[NSURL URLWithString:location]
									   andPostBody:postBody
										  delegate:self 
										   message:NSLocalizedString(@"postprogressbar.upload.picture", @"Uploading Picture")
                                        accountUUID:selectedAccountUUID];
		} else {
			NSString *postBody = [NSString stringWithFormat:@""
								  "<?xml version=\"1.0\" ?>"
								  "<entry xmlns=\"http://www.w3.org/2005/Atom\" xmlns:app=\"http://www.w3.org/2007/app\" xmlns:cmisra=\"http://docs.oasis-open.org/ns/cmis/restatom/200908/\">"
								  "<title type=\"text\">%@</title>"
								  "<cmisra:object xmlns:cmis=\"http://docs.oasis-open.org/ns/cmis/core/200908/\">"
								  "<cmis:properties>"
								  "<cmis:propertyId  propertyDefinitionId=\"cmis:objectTypeId\">"
								  "<cmis:value>cmis:folder</cmis:value>"
								  "</cmis:propertyId>"
								  "</cmis:properties>"
								  "</cmisra:object>"
								  "</entry>", userInput];
			NSLog(@"POSTING DATA: %@", postBody);
			
			RepositoryItem *item = [folderItems item];
			NSString *location   = [item identLink];
			NSLog(@"TO LOCATION: %@", location);
			
			self.postProgressBar = 
				[PostProgressBar createAndStartWithURL:[NSURL URLWithString:location]
								 andPostBody:postBody
								 delegate:self 
								 message:NSLocalizedString(@"postprogressbar.create.folder", @"Creating Folder")
                                 accountUUID:selectedAccountUUID];
		}
	}
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    if(tableView == self.tableView) 
    {
        return [self.repositoryItems count];
    } 
    else 
    {
        return [self.searchResultItems count];
    }
    
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	RepositoryItemCellWrapper *cellWrapper = nil;
    
    if(tableView == self.tableView)
    {
        cellWrapper = [self.repositoryItems objectAtIndex:indexPath.row];
    }
    else 
    {
        cellWrapper = [self.searchResultItems objectAtIndex:indexPath.row];
    }
    
    return [cellWrapper createCellInTableView:tableView];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	RepositoryItem *child = nil;
    RepositoryItemCellWrapper *cellWrapper = nil;
    
    if(tableView == self.tableView) 
    {
        cellWrapper = [self.repositoryItems objectAtIndex:[indexPath row]];
    } 
    else 
    {
        cellWrapper = [self.searchResultItems objectAtIndex:[indexPath row]];
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    }
    
    child = [cellWrapper anyRepositoryItem];
    
    //Don't continue if there's nothing to highlight
    if(!child)
    {
        return;
    }
	
	if ([child isFolder]) {
        [self startHUD];
		[self.itemDownloader clearDelegatesAndCancel];
		
		NSDictionary *optionalArguments = [[LinkRelationService shared] 
										   optionalArgumentsForFolderChildrenCollectionWithMaxItems:nil skipCount:nil filter:nil 
										   includeAllowableActions:YES includeRelationships:NO renditionFilter:nil orderBy:nil includePathSegment:NO];
		NSURL *getChildrenURL = [[LinkRelationService shared] getChildrenURLForCMISFolder:child 
																   withOptionalArguments:optionalArguments];
		FolderItemsHTTPRequest *down = [[FolderItemsHTTPRequest alloc] initWithURL:getChildrenURL accountUUID:selectedAccountUUID];
        [down setDelegate:self];
        [down setDidFinishSelector:@selector(folderItemsRequestFinished:)];
        [down setDidFailSelector:@selector(folderItemsRequestFailed:)];
		[self setItemDownloader:down];
        [down setItem:child];
        [down setParentTitle:child.title];
		[down startAsynchronous];
		[down release];
	}
	else {
		if (child.contentLocation)
        {
            [self.tableView setAllowsSelection:NO];
			NSString *urlStr  = child.contentLocation;
			NSURL *contentURL = [NSURL URLWithString:urlStr];
			[self setDownloadProgressBar:[DownloadProgressBar createAndStartWithURL:contentURL
                                                                           delegate:self 
                                                                            message:NSLocalizedString(@"Downloading Document", @"Downloading Document")
                                                                           filename:child.title 
                                                                      contentLength:[child contentStreamLength] 
                                                                        accountUUID:selectedAccountUUID 
                                                                           tenantID:self.tenantID]];
            [[self downloadProgressBar] setCmisObjectId:[child guid]];
            [[self downloadProgressBar] setCmisContentStreamMimeType:[[child metadata] objectForKey:@"cmis:contentStreamMimeType"]];
            [[self downloadProgressBar] setVersionSeriesId:[child versionSeriesId]];
            [[self downloadProgressBar] setRepositoryItem:child];
		}
		else {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"noContentWarningTitle", @"No content")
                                                            message:NSLocalizedString(@"noContentWarningMessage", @"This document has no content.") 
                                                           delegate:nil 
                                                  cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK Button Text")
                                                  otherButtonTitles:nil];
			[alert show];
            [alert release];
		}
	}
    
    [willSelectIndex release];
    willSelectIndex = [indexPath retain];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	RepositoryItem *child = nil;
    RepositoryItemCellWrapper *cellWrapper = nil;
    
    if(tableView == self.tableView) {
        cellWrapper = [self.repositoryItems objectAtIndex:[indexPath row]];
    } else {
        cellWrapper = [self.searchResultItems objectAtIndex:[indexPath row]];
    }
    
    child = [cellWrapper anyRepositoryItem];
	
    if(child)
    {
        [self.tableView setAllowsSelection:NO];
        [self startHUD];
        
        CMISTypeDefinitionHTTPRequest *down = [[CMISTypeDefinitionHTTPRequest alloc] initWithURL:[NSURL URLWithString:child.describedByURL] accountUUID:selectedAccountUUID];
        [down setDelegate:self];
        [down setRepositoryItem:child];
        [down startAsynchronous];
        [self setMetadataDownloader:down];
        [down release];
    }
    else if(cellWrapper.uploadInfo && [cellWrapper.uploadInfo uploadStatus] != UploadInfoStatusFailed)
    {
        [self setUploadToCancel:cellWrapper];
        UIAlertView *confirmAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"uploads.cancelAll.title", @"Uploads") message:NSLocalizedString(@"uploads.cancel.body", @"Would you like to...") delegate:self cancelButtonTitle:NSLocalizedString(@"No", @"No") otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil] autorelease];
        [confirmAlert setTag:kCancelUploadPrompt];
        [confirmAlert show];
    }
    else if(cellWrapper.uploadInfo && [cellWrapper.uploadInfo uploadStatus] == UploadInfoStatusFailed)
    {
        [self setUploadToDismiss:[cellWrapper uploadInfo]];
        if (IS_IPAD) {
            FailedUploadDetailViewController *viewController = [[FailedUploadDetailViewController alloc] initWithUploadInfo:cellWrapper.uploadInfo];
            [viewController setCloseTarget:self];
            [viewController setCloseAction:@selector(closeFailedUpload:)];
            
            UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:viewController];
            [self setPopover:popoverController];
            [popoverController setPopoverContentSize:viewController.view.frame.size];
            [popoverController setDelegate:self];
            [popoverController release];
            [viewController release];
            
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            [popover presentPopoverFromRect:cell.accessoryView.frame inView:cell permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        } else  {
            UIAlertView *uploadFailDetail = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Upload Failed", @"") message:[cellWrapper.uploadInfo.error localizedDescription]  delegate:self cancelButtonTitle:NSLocalizedString(@"Close", @"Close") otherButtonTitles:NSLocalizedString(@"Clear", @"Clear"), nil];
            [uploadFailDetail setTag:kDismissFailedUploadPrompt];
            [uploadFailDetail show];
            [uploadFailDetail release];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}


#pragma mark -
#pragma mark FailedUploadDetailViewController Delegate
//This is called from the FailedUploadDetailViewController and it means the user retry the failed upload
//We just want to dismiss the popover
- (void)closeFailedUpload:(FailedUploadDetailViewController *)sender
{
    if(nil != popover && [popover isPopoverVisible]) 
    {
        //Removing us as the delegate so we don't get the dismiss call at this point the user retried the upload and 
        // we don't want to clear the upload
        [popover setDelegate:nil];
        [popover dismissPopoverAnimated:YES];
        [self setPopover:nil];
    }
}

#pragma mark -
#pragma mark UIPopoverController Delegate methods
//This is called when the popover was dismissed by the user by tapping in another part of the screen,
//We want to to clear the upload
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [[UploadsManager sharedManager] clearUpload:self.uploadToDismiss.uuid];
}

#pragma mark -
#pragma mark FolderItemsHTTPRequest Delegate
- (void)folderItemsRequestFinished:(ASIHTTPRequest *)request 
{
	if ([request isKindOfClass:[FolderItemsHTTPRequest class]] && [request isEqual:itemDownloader]) 
    {
		// if we're reloading then just tell the view to update
		if (replaceData) {
			replaceData = NO;
            [self initRepositoryItems];
			[[self tableView] reloadData];
		}
		// otherwise we're loading a child which needs to
		// be created and pushed onto the nav stack
		else {
			FolderItemsHTTPRequest *fid = (FolderItemsHTTPRequest *) request;

			// create a new view controller for the list of repository items (documents and folders)            
			RepositoryNodeViewController *viewController = [[RepositoryNodeViewController alloc] initWithNibName:nil bundle:nil];
            [viewController setSelectedAccountUUID:[self selectedAccountUUID]];
            [viewController setTenantID:[self tenantID]];
            [viewController setFolderItems:fid];
            [viewController setTitle:[fid parentTitle]];
            [viewController setGuid:fid.item.guid];

			// push that view onto the nav controller's stack
			[self.navigationController pushViewController:viewController animated:YES];
			[viewController release];
		}
	} 
        
    [self stopHUD];
}

- (void)folderItemsRequestFailed:(ASIHTTPRequest *)request {
	[self stopHUD];
}


#pragma mark -
#pragma mark Instance Methods

- (void)reloadFolderAction
{
    // A request is active we should not try to reload
    if(hudCount > 0) {
        return;
    }
    
    [self startHUD];
	replaceData = YES;
	RepositoryItem *currentNode = [folderItems item];
	NSDictionary *optionalArguments = [[LinkRelationService shared] 
									   optionalArgumentsForFolderChildrenCollectionWithMaxItems:nil skipCount:nil filter:nil 
									   includeAllowableActions:YES includeRelationships:NO renditionFilter:nil orderBy:nil includePathSegment:NO];
	NSURL *getChildrenURL = [[LinkRelationService shared] getChildrenURLForCMISFolder:currentNode 
															   withOptionalArguments:optionalArguments];
    if (getChildrenURL == nil) {
        // Workaround: parser seems to not be working correctly, need to investigate what's happening here....
        // For now setting the URL to be what was used to populate this form
        getChildrenURL = [folderItems url];
    }
    
    FolderItemsHTTPRequest *down = [[FolderItemsHTTPRequest alloc] initWithURL:getChildrenURL accountUUID:selectedAccountUUID];
    [down setDelegate:self];
    [down setDidFinishSelector:@selector(folderItemsRequestFinished:)];
    [down setDidFailSelector:@selector(folderItemsRequestFailed:)];
    [down setItem:currentNode];
    [down setParentTitle:currentNode.title];
    [down startAsynchronous];
    
    [self setItemDownloader:down];
    [self setFolderItems:down];
    [down release];
}

- (void)download:(DownloadProgressBar *)down completeWithPath:(NSString *)filePath 
{
	DocumentViewController *doc = [[DocumentViewController alloc] initWithNibName:kFDDocumentViewController_NibName bundle:[NSBundle mainBundle]];
	[doc setCmisObjectId:down.cmisObjectId];
    [doc setContentMimeType:[down cmisContentStreamMimeType]];
    [doc setHidesBottomBarWhenPushed:YES];
    [doc setSelectedAccountUUID:selectedAccountUUID];
    [doc setTenantID:down.tenantID];
    
    DownloadMetadata *fileMetadata = down.downloadMetadata;
    NSString *filename;
    [doc setFileMetadata:fileMetadata];
    if(fileMetadata.key) {
        filename = fileMetadata.key;
    } else {
        filename = down.filename;
    }
    
    [doc setFileName:filename];
    [doc setFilePath:filePath];
    
    [[FileDownloadManager sharedInstance] setDownload:fileMetadata.downloadInfo forKey:filename];
	
	[IpadSupport pushDetailController:doc withNavigation:self.navigationController andSender:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(detailViewControllerChanged:) name:kDetailViewControllerChangedNotification object:nil];
    
	[doc release];
    
    [selectedIndex release];
    selectedIndex = willSelectIndex;
    willSelectIndex = nil;
    
    [self.tableView setAllowsSelection:YES];

}

- (void)downloadWasCancelled:(DownloadProgressBar *)down {

    [self.tableView setAllowsSelection:YES];
    [self.tableView deselectRowAtIndexPath:willSelectIndex animated:YES];

    
    // We don't want to reselect the previous row in iPhone
    if(IS_IPAD) {
        [self.tableView selectRowAtIndexPath:selectedIndex animated:YES scrollPosition:UITableViewScrollPositionNone];
    }

    [self.tableView setAllowsSelection:YES];
}

- (void)post:(PostProgressBar *)bar completeWithData:(NSData *)data 
{
    [self reloadFolderAction];
}

- (void) post:(PostProgressBar *)bar failedWithData:(NSData *)data
{
    NSLog(@"WARNING - not implemented post:failedWithData:");
}

- (NSIndexPath *)indexPathForNodeWithGuid:(NSString *)itemGuid
{
    NSIndexPath *indexPath = nil;
    
    if (itemGuid != nil && folderItems != nil)
    {
        // Define a block predicate to search for the item being viewed
        BOOL (^matchesRepostoryItem)(RepositoryItemCellWrapper *, NSUInteger, BOOL *) = ^ (RepositoryItemCellWrapper *cellWrapper, NSUInteger idx, BOOL *stop)
        {
            BOOL matched = NO;
            RepositoryItem *repositoryItem = [cellWrapper anyRepositoryItem];
            if ([[repositoryItem guid] isEqualToString:itemGuid] == YES)
            {
                matched = YES;
                *stop = YES;
            }
            return matched;
        };
        
        // See if there's an item in the list with a matching guid, using the block defined above
        NSUInteger matchingIndex = [self.repositoryItems indexOfObjectPassingTest:matchesRepostoryItem];
        if (matchingIndex != NSNotFound)
        {
            indexPath = [NSIndexPath indexPathForRow:matchingIndex inSection:0];
            NSLog(@"Reselecting document with nodeRef %@ at selectedIndex %@", itemGuid, indexPath);
            
            // TODO: The following code tells the cell to re-render, but relies on updated metadata which we can't
            //       easily achieve with the current code.
            // [[folderItems children] replaceObjectAtIndex:matchingIndex withObject:[fileMetadata repositoryItem]];
            // [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:selectedIndex] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
    
    return indexPath;
}

#pragma mark - UploadFormDelegate
- (void)dismissUploadViewController:(UploadFormTableViewController *)recipeAddViewController didUploadFile:(BOOL)success {
    [recipeAddViewController dismissModalViewControllerAnimated:YES];
}

#pragma mark - SavedDocumentPickerDelegate
- (void) savedDocumentPicker:(SavedDocumentPickerController *)picker didPickDocuments:(NSArray *)documentURLs {
    NSLog(@"User selected the documents %@", documentURLs);
    
    //Hide popover on iPad
    [self savedDocumentPickerDidCancel:picker];
    
    if([documentURLs count] == 1)
    {
        NSURL *documentURL = [documentURLs lastObject];
        UploadInfo *uploadInfo = [self uploadInfoFromURL:documentURL];
        [self presentUploadFormWithItem:uploadInfo andHelper:[uploadInfo uploadHelper]];
    } 
    else if([documentURLs count] > 1)
    {
        NSMutableArray *uploadItems = [NSMutableArray arrayWithCapacity:[documentURLs count]];
        for(NSURL *documentURL in documentURLs) 
        {
            [uploadItems addObject:[self uploadInfoFromURL:documentURL]];
        }
        
        [self presentUploadFormWithMultipleItems:uploadItems andUploadType:UploadFormTypeMultipleDocuments];
    }
}

- (void)savedDocumentPickerDidCancel:(SavedDocumentPickerController *)picker
{
    if (IS_IPAD) {
		if(nil != popover && [popover isPopoverVisible]) 
        {
			[popover dismissPopoverAnimated:YES];
            [self setPopover:nil];
		}
	}
}

- (void)presentUploadFormWithItem:(UploadInfo *)uploadInfo andHelper:(id<UploadHelper>)helper;
{
    UploadFormTableViewController *formController = [[[UploadFormTableViewController alloc] init] autorelease];
    [formController setExistingDocumentNameArray:[folderItems valueForKeyPath:@"children.title"]];
    [formController setUploadType:uploadInfo.uploadType];
    [formController setUpdateAction:@selector(uploadFormDidFinishWithItems:)];
    [formController setUpdateTarget:self];
    [formController setSelectedAccountUUID:selectedAccountUUID];
    [formController setTenantID:self.tenantID];
    [uploadInfo setUpLinkRelation:[[self.folderItems item] identLink]];
    [uploadInfo setSelectedAccountUUID:self.selectedAccountUUID];
    [uploadInfo setFolderName:[self.folderItems parentTitle]];
    
    IFTemporaryModel *formModel = [[IFTemporaryModel alloc] init];

    [formController setUploadInfo:uploadInfo];
    [formController setUploadHelper:helper];
    [formModel setObject:uploadInfo.uploadFileURL forKey:@"previewURL"];
    
    
    if(uploadInfo.filename)
    {
        [formModel setObject:uploadInfo.filename forKey:@"name"];
    }
    [formController setModel:formModel];
    [formModel release];
    
    [formController setModalPresentationStyle:UIModalPresentationFormSheet];
    formController.delegate = self;
    // We want to present the UploadFormTableViewController modally in ipad
    // and in iphone we want to push it into the current navigation controller
    // IpadSupport helper method provides this logic
    [IpadSupport presentModalViewController:formController withNavigation:self.navigationController];
}

- (void)presentUploadFormWithMultipleItems:(NSArray *)infos andUploadType:(UploadFormType)uploadType
{
    UploadFormTableViewController *formController = [[[UploadFormTableViewController alloc] init] autorelease];
    [formController setExistingDocumentNameArray:[folderItems valueForKeyPath:@"children.title"]];
    [formController setUploadType:uploadType];
    [formController setUpdateAction:@selector(uploadFormDidFinishWithItems:)];
    [formController setUpdateTarget:self];
    [formController setSelectedAccountUUID:selectedAccountUUID];
    [formController setTenantID:self.tenantID];
    [formController setMultiUploadItems:infos];
    
    for(UploadInfo *uploadInfo in infos)
    {
        [uploadInfo setUpLinkRelation:[[self.folderItems item] identLink]];
        [uploadInfo setSelectedAccountUUID:self.selectedAccountUUID];
        [uploadInfo setFolderName:[self.folderItems parentTitle]];
    }
    
    IFTemporaryModel *formModel = [[IFTemporaryModel alloc] init];
    [formController setModel:formModel];
    [formModel release];
    
    [formController setModalPresentationStyle:UIModalPresentationFormSheet];
    formController.delegate = self;
    // We want to present the UploadFormTableViewController modally in ipad
    // and in iphone we want to push it into the current navigation controller
    // IpadSupport helper method provides this logic
    [IpadSupport presentModalViewController:formController withNavigation:self.navigationController];
}

- (UploadInfo *)uploadInfoFromAsset:(ALAsset *)asset
{
    UploadInfo *uploadInfo = [[UploadInfo alloc] init];
    NSURL *previewURL = [AssetUploadItem createPreviewFromAsset:asset];
    [uploadInfo setUploadFileURL:previewURL];
    
    if(isVideoExtension([previewURL pathExtension]))
    {
        [uploadInfo setUploadType:UploadFormTypeVideo];
    }
    else 
    {
        [uploadInfo setUploadType:UploadFormTypePhoto];
    }
    
    return [uploadInfo autorelease];
}

- (UploadInfo *)uploadInfoFromURL:(NSURL *)fileURL
{
    UploadInfo *uploadInfo = [[UploadInfo alloc] init];
    [uploadInfo setUploadFileURL:fileURL];
    [uploadInfo setUploadType:UploadFormTypeDocument];

    return [uploadInfo autorelease];
}

#pragma mark -
#pragma mark UploadFormTableViewController delegate method
- (void)uploadFormDidFinishWithItems:(NSArray *)items
{
    [self addUploadsToRepositoryItems:items insertCells:YES];
}

#pragma mark -
#pragma mark SearchBarDelegate Protocol Methods
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar 
{
    NSString *searchPattern = [[searchBar text] trimWhiteSpace];
    
    if([searchPattern length] > 0) {
        NSLog(@"Start searching for %@", searchPattern);
        //Cancel if there's a current request
        if([searchRequest isExecuting]) {
            [searchRequest clearDelegatesAndCancel];
            [self stopHUD];
            [self setSearchRequest:nil];
        }
        
        [self startHUD];
        
        CMISSearchHTTPRequest *searchReq = [[[CMISSearchHTTPRequest alloc] initWithSearchPattern:searchPattern folderObjectId:self.guid 
                                                                                     accountUUID:self.selectedAccountUUID tenantID:self.tenantID] autorelease];
        [self setSearchRequest:searchReq];        
        [searchRequest setDelegate:self];
        [searchRequest setShow500StatusError:NO];
        [searchRequest startAsynchronous];

    }
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller 
{
    //Cleaning up the search results
    [self setSearchRequest:nil];
}

#pragma mark -
#pragma mark MBProgressHUD Helper Methods
- (void)startHUD
{
    hudCount++;
	if (!self.HUD)
    {
        if ([searchController isActive])
        {
            self.HUD = createAndShowProgressHUDForView([searchController searchResultsTableView]);
        }
        else
        {
            self.HUD = createAndShowProgressHUDForView(self.tableView);
        }
    }
}

- (void)stopHUD
{
    hudCount--;
    
	if (self.HUD && hudCount <= 0)
    {
        stopProgressHUD(self.HUD);
		self.HUD = nil;
	}
}

#pragma mark - NotificationCenter methods
- (void) detailViewControllerChanged:(NSNotification *) notification 
{
    id sender = [notification object];
    DownloadMetadata *fileMetadata = [[notification userInfo] objectForKey:@"fileMetadata"];
    
    if(sender && ![sender isEqual:self]) 
    {
        // Release any existing selection index
        if (selectedIndex != nil)
        {
            [selectedIndex release];
            selectedIndex = nil;
        }
        
        selectedIndex = [[self indexPathForNodeWithGuid:fileMetadata.objectId] retain];
        [self.tableView selectRowAtIndexPath:selectedIndex animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kDetailViewControllerChangedNotification object:nil];
}

- (void) applicationWillResignActive:(NSNotification *) notification {
    NSLog(@"applicationWillResignActive in RepositoryNodeViewController");
    [popover dismissPopoverAnimated:NO];
    self.popover = nil;
    
    [self cancelAllHTTPConnections];
}

- (void)uploadQueueChanged:(NSNotification *) notification
{
    //Something in the queue changed, we are interested if a current upload (ghost cell) was cleared
    NSMutableArray *indexPaths = [NSMutableArray array];
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for(NSUInteger index = 0; index < [self.repositoryItems count]; index++)
    {
        RepositoryItemCellWrapper *cellWrapper = [self.repositoryItems objectAtIndex:index];
        //We keep the cells for finished uploads and failed uploads
        if(cellWrapper.uploadInfo && [cellWrapper.uploadInfo uploadStatus] != UploadInfoStatusUploaded && ![[UploadsManager sharedManager] isManagedUpload:cellWrapper.uploadInfo.uuid])
        {
            _GTMDevLog(@"We are displaying an upload that is not currently managed");
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            [indexPaths addObject:indexPath];
            [indexSet addIndex:index];
        }
    }
    
    if([indexPaths count] > 0)
    {
        [self.repositoryItems removeObjectsAtIndexes:indexSet];
        [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:kDefaultTableViewRowAnimation];
    }
}

@end
