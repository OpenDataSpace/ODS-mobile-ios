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
#import "FailedTransferDetailViewController.h"
#import "DownloadManager.h"
#import "PreviewManager.h"
#import "DeleteObjectRequest.h"
#import "AlfrescoAppDelegate.h"
#import "TableViewHeaderView.h"

NSInteger const kDownloadFolderAlert = 1;
NSInteger const kCancelUploadPrompt = 2;
NSInteger const kDismissFailedUploadPrompt = 3;
NSInteger const kConfirmMultipleDeletePrompt = 4;
UITableViewRowAnimation const kDefaultTableViewRowAnimation = UITableViewRowAnimationFade;

NSString * const kMultiSelectDownload = @"downloadAction";
NSString * const kMultiSelectDelete = @"deleteAction";

@interface RepositoryNodeViewController ()
@property (nonatomic, retain) UIActionSheet *actionSheet;
@end

@interface RepositoryNodeViewController (PrivateMethods)
- (void)initRepositoryItems;
- (void)addUploadsToRepositoryItems:(NSArray *)uploads insertCells:(BOOL)insertCells;
- (void)initSearchResultItems;
- (void)loadRightBar;
- (void)loadRightBarForEditMode;
- (void)cancelAllHTTPConnections;
- (void)presentModalViewControllerHelper:(UIViewController *)modalViewController;
- (void)presentModalViewControllerHelper:(UIViewController *)modalViewController animated:(BOOL)animated;
- (void)dismissModalViewControllerHelper;
- (void)dismissModalViewControllerHelper:(BOOL)animated;
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
- (NSArray *)existingDocuments;
- (UITableView *)activeTableView;
- (RepositoryItemCellWrapper *)cellWrapperForIndexPath:(NSIndexPath *)indexPath;
- (RepositoryItemTableViewCell *)tableViewCellForIndexPath:(NSIndexPath *)indexPath;
@end

@implementation RepositoryNodeViewController

@synthesize guid;
@synthesize folderItems;
@synthesize metadataDownloader;
@synthesize downloadProgressBar;
@synthesize downloadQueueProgressBar;
@synthesize deleteQueueProgressBar;
@synthesize postProgressBar;
@synthesize itemDownloader;
@synthesize folderDescendantsRequest;
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
@synthesize refreshHeaderView = _refreshHeaderView;
@synthesize lastUpdated = _lastUpdated;
@synthesize multiSelectToolbar = _multiSelectToolbar;
@synthesize actionSheet = _actionSheet;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self cancelAllHTTPConnections];
    [self.popover dismissPopoverAnimated:NO];
    [_multiSelectToolbar removeFromSuperview];
    [[PreviewManager sharedManager] setDelegate:nil];
    [[PreviewManager sharedManager] setProgressIndicator:nil];
    
    [guid release];
    [folderItems release];
    [metadataDownloader release];
    [downloadProgressBar release];
    [downloadQueueProgressBar release];
    [deleteQueueProgressBar release];
    [itemDownloader release];
    [folderDescendantsRequest release];
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
    [_refreshHeaderView release];
    [_lastUpdated release];
    [_multiSelectToolbar release];
    [_actionSheet release];

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
    if([searchController isActive])
    {
        tableView = [searchController searchResultsTableView];
    }
    else
    {
        tableView = self.tableView;
    }
    NSIndexPath *selectedRow = [tableView indexPathForSelectedRow];
    
    // Retrieving the selectedItem. We want to deselect a folder when the view appears even if we're on the iPad
    // We only set it when working in the main tableView since the search doesn't return folders
    RepositoryItem *selectedItem = nil;
    if (selectedRow && [tableView isEqual:self.tableView])
    {
        RepositoryItemCellWrapper *cellWrapper = [self.repositoryItems objectAtIndex:selectedRow.row];
        selectedItem = [cellWrapper repositoryItem];
    }
    
    if (!IS_IPAD || [selectedItem isFolder])
    {
        [[self tableView] deselectRowAtIndexPath:selectedRow animated:YES];
        [self.searchController.searchResultsTableView deselectRowAtIndexPath:selectedRow animated:YES];
    }

    [willSelectIndex release];
    willSelectIndex = nil;

    // For non-iPad devices we'll hide the search view to save screen real estate
    if (!IS_IPAD)
    {
        [self.tableView setContentOffset:CGPointMake(0, 40)];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.popover dismissPopoverAnimated:YES];
    if (self.actionSheet.window)
    {
        [self.actionSheet dismissWithClickedButtonIndex:self.actionSheet.cancelButtonIndex animated:animated];
    }
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
	
	replaceData = NO;

	[Theme setThemeForUIViewController:self];
    [self.tableView setRowHeight:kDefaultTableCellHeight];
    
    //Contextual Search view
    UISearchBar * theSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    [theSearchBar setTintColor:[ThemeProperties toolbarColor]];
    [theSearchBar setShowsCancelButton:YES];
    [theSearchBar setDelegate:self];
    [theSearchBar setShowsCancelButton:NO animated:NO];
    [self.tableView setTableHeaderView:theSearchBar];
    
    UISearchDisplayController *searchCon = [[UISearchDisplayController alloc] initWithSearchBar:theSearchBar contentsController:self];
    [searchCon.searchBar setBackgroundColor:[UIColor whiteColor]];
    self.searchController = searchCon;
    [searchCon release];
    [searchController setDelegate:self];
    [searchController setSearchResultsDelegate:self];
    [searchController setSearchResultsDataSource:self];
    [searchController.searchResultsTableView setRowHeight:kDefaultTableCellHeight];
    
    [self initRepositoryItems];
    [self loadRightBar];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadQueueChanged:) name:kNotificationUploadQueueChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadFinished:) name:kNotificationUploadFinished object:nil];

	// Pull to Refresh
    self.refreshHeaderView = [[[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)
                                                                arrowImageName:@"pull-to-refresh.png"
                                                                     textColor:[ThemeProperties pullToRefreshTextColor]] autorelease];
    [self.refreshHeaderView setDelegate:self];
    [self setLastUpdated:[NSDate date]];
    [self.refreshHeaderView refreshLastUpdatedDate];
    [self.tableView addSubview:self.refreshHeaderView];

    // Multi-select toolbar
    [self setMultiSelectToolbar:[[[MultiSelectActionsToolbar alloc] initWithParentViewController:self] autorelease]];
    [self.multiSelectToolbar setMultiSelectDelegate:self];
    [self.multiSelectToolbar addActionButtonNamed:kMultiSelectDownload withLabelKey:@"multiselect.button.download" atIndex:0];
    [self.multiSelectToolbar addActionButtonNamed:kMultiSelectDelete withLabelKey:@"multiselect.button.delete" atIndex:1 isDestructive:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.tableView = nil;
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
    
    if ([searchRequest.results count] > 0)
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

- (void)fixSearchControllerFrame
{
    // Need to manually increase the frame to prevent incorrect sizing
    // Note: the frame is reset each time, so doesn't continue to grow with each call
    CGRect rect = self.searchDisplayController.searchContentsController.view.frame;
    rect.size.height += 44.;
    [self.searchDisplayController.searchContentsController.view setFrame:rect];
}

- (void)loadRightBar
{
    [self loadRightBarAnimated:YES];
}

- (void)loadRightBarAnimated:(BOOL)animated
{
    BOOL showAddButton = ([[AppProperties propertyForKey:kBShowAddButton] boolValue] && nil != [folderItems item]
                          && ([folderItems item].canCreateFolder || [folderItems item].canCreateDocument));
    BOOL showEditButton = ([[AppProperties propertyForKey:kBShowEditButton] boolValue]
                           && ([self.repositoryItems count] > 0));
    
    // We only show the second button if any option is going to be displayed
    if (showAddButton || showEditButton)
    {
        NSMutableArray *rightBarButtons = [NSMutableArray array];
        
        if (showEditButton)
        {
            UIBarButtonItem *editButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                         target:self
                                                                                         action:@selector(performEditAction:)] autorelease];
            [rightBarButtons addObject:editButton];
        }
        
        if (showAddButton)
        {
            UIBarButtonItem *addButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                        target:self
                                                                                        action:@selector(performAddAction:)] autorelease];
            addButton.style = UIBarButtonItemStyleBordered;
            [rightBarButtons addObject:addButton];
            self.actionSheetSenderControl = addButton;
        }

        [self.navigationItem setRightBarButtonItems:rightBarButtons animated:animated];
    }
}

- (void)loadRightBarForEditMode
{
    [self loadRightBarForEditMode:YES];
}

- (void)loadRightBarForEditMode:(BOOL)animated
{
    UIBarButtonItem *doneButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                 target:self
                                                                                 action:@selector(performEditingDoneAction:)] autorelease];
    styleButtonAsDefaultAction(doneButton);
    [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObject:doneButton] animated:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (IS_IPAD && self.isEditing)
    {
        // When in portrait orientation, show the master view controller to guide the user
        if (self.interfaceOrientation == UIInterfaceOrientationPortrait || self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
        {
            AlfrescoAppDelegate *appDelegate = (AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate.splitViewController showMasterPopover:nil];
        }
    }
    
    if ([self.searchController isActive])
    {
        // Need to fix-up the searchController's frame again
        [self fixSearchControllerFrame];
    }
}

- (void)performAddAction:(id)sender
{
	if (IS_IPAD)
    {
		if (nil != popover && [popover isPopoverVisible])
        {
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
    
	if (folderItems.item.canCreateDocument)
    {
        NSArray *sourceTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        BOOL hasCamera = [sourceTypes containsObject:(NSString *) kUTTypeImage];
        BOOL canCaptureVideo = [sourceTypes containsObject:(NSString *) kUTTypeMovie];
        
        [sheet addButtonWithTitle:NSLocalizedString(@"add.actionsheet.upload", @"Upload")];
        
		if (hasCamera && canCaptureVideo)
        {
            [sheet addButtonWithTitle:NSLocalizedString(@"add.actionsheet.take-photo-video", @"Take Photo or Video")];
		}
        else if (hasCamera) 
        {
			[sheet addButtonWithTitle:NSLocalizedString(@"add.actionsheet.take-photo", @"Take Photo")];
        }
        
        [sheet addButtonWithTitle:NSLocalizedString(@"add.actionsheet.record-audio", @"Record Audio")];
	}
	
    BOOL showDownloadFolderButton = [[AppProperties propertyForKey:kBShowDownloadFolderButton] boolValue];
    if(showDownloadFolderButton)
    {
        [sheet addButtonWithTitle:NSLocalizedString(@"add.actionsheet.download-folder", @"Download all documents")];
    }

    if (folderItems.item.canCreateFolder)
    {
        [sheet addButtonWithTitle:NSLocalizedString(@"add.actionsheet.create-folder", @"Create Folder")];
    }
	
	[sheet setCancelButtonIndex:[sheet addButtonWithTitle:NSLocalizedString(@"add.actionsheet.cancel", @"Cancel")]];
    
    if (IS_IPAD)
    {
        [self setActionSheetSenderControl:sender];
        [sheet setActionSheetStyle:UIActionSheetStyleDefault];
        [sheet showFromBarButtonItem:sender animated:YES];
        [(UIBarButtonItem *)sender setEnabled:NO];
    }
    else
    {
        [sheet showInView:[[self tabBarController] view]];
    }
	
    [self setActionSheet:sheet];
	[sheet release];
}

- (void)performEditAction:(id)sender
{
	if (IS_IPAD)
    {
		if ([popover isPopoverVisible])
        {
			[popover dismissPopoverAnimated:YES];
            [self setPopover:nil];
		}
	}

    if (self.actionSheet.window)
    {
        [self.actionSheet dismissWithClickedButtonIndex:self.actionSheet.cancelButtonIndex animated:YES];
    }

    [self setEditing:YES];
}

- (void)performEditingDoneAction:(id)sender
{
    [self setEditing:NO];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex 
{
	NSString *buttonLabel = nil;
    [actionSheet dismissWithClickedButtonIndex:0 animated:YES];
    [self.actionSheetSenderControl setEnabled:YES];
    [self setActionSheet:nil];

    if (buttonIndex > -1)
    {
        buttonLabel = [actionSheet buttonTitleAtIndex:buttonIndex];
    }

	if (![buttonLabel isEqualToString:NSLocalizedString(@"add.actionsheet.cancel", @"Cancel")]) 
    {
        // TODO
        // Re-implement using a switch and button indices.  
        //
        
        if ([buttonLabel isEqualToString:NSLocalizedString(@"add.actionsheet.choose-photo", @"Choose Photo from Library")])
        {               
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
                        [self dismissModalViewControllerHelper:NO];
                        //Fallback in the UIIMagePickerController if the AssetsLibrary is not accessible
                        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                        [picker setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
                        [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
                        [picker setMediaTypes:[UIImagePickerController availableMediaTypesForSourceType:picker.sourceType]];
                        [picker setDelegate:self];
                        
                        [self presentModalViewControllerHelper:picker animated:NO];
                        
                        [picker release];
                    });
                }
                
                [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
                
            } andSuccessBlock:^(NSArray *info) {
                [self startHUD];
                NSLog(@"User finished picking the library assets: %@", info);
                [self dismissModalViewControllerHelper];
                [[UploadsManager sharedManager] setExistingDocuments:[self existingDocuments] forUpLinkRelation:[[self.folderItems item] identLink]];
                
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
            if(IS_IPAD)
            {
                [imagePickerController setChangeBarStyle:NO];
            }
            [self presentModalViewControllerHelper:imagePickerController];
            [imagePickerController release];
		}
        else if ([buttonLabel isEqualToString:NSLocalizedString(@"add.actionsheet.take-photo", @"Take Photo")] || [buttonLabel isEqualToString:NSLocalizedString(@"add.actionsheet.take-photo-video", @"Take Photo or Video")]) 
        {
            if (IS_IPAD)
            {
                UIViewController *pickerContainer = [[UIViewController alloc] init];
                UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                [pickerContainer setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
                [picker setSourceType:UIImagePickerControllerSourceTypeCamera];
                [picker setMediaTypes:[UIImagePickerController availableMediaTypesForSourceType:picker.sourceType]];
                [picker setDelegate:self];
                [pickerContainer.view addSubview:picker.view];
                
                [self presentModalViewControllerHelper:pickerContainer];
                [self.popover setPopoverContentSize:picker.view.frame.size animated:YES];
                
                CGRect rect =self.popover.contentViewController.view.frame;
                picker.view.frame = rect;
                
                [pickerContainer release];
            }
            else
            {
                UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                [picker setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
                [picker setSourceType:UIImagePickerControllerSourceTypeCamera];
                [picker setMediaTypes:[UIImagePickerController availableMediaTypesForSourceType:picker.sourceType]];
                [picker setDelegate:self];
                
                [self presentModalViewControllerHelper:picker];
                
                [picker release];
            }
            
		}
        else if ([buttonLabel isEqualToString:NSLocalizedString(@"add.actionsheet.create-folder", @"Create Folder")]) 
        {
			UIAlertView *alert = [[UIAlertView alloc] 
								  initWithTitle:NSLocalizedString(@"add.create-folder.prompt.title", @"Name: ")
								  message:@" \r\n "
								  delegate:self 
								  cancelButtonTitle:NSLocalizedString(@"closeButtonText", @"Cancel Button Text")
								  otherButtonTitles:NSLocalizedString(@"okayButtonText", @"OK Button Text"), nil];
            
			self.alertField = [[[UITextField alloc] initWithFrame:CGRectMake(16., 55.0, 252.0, 25.0)] autorelease];
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
        else if([buttonLabel isEqualToString:NSLocalizedString(@"add.actionsheet.record-audio", @"Record Audio")]) 
        {
            [self loadAudioUploadForm];
        }
        else if([buttonLabel isEqualToString:NSLocalizedString(@"add.actionsheet.download-folder", @"Download all documents")]) 
        {
            [self prepareDownloadAllDocuments];
        }
        else if ([buttonLabel isEqualToString:NSLocalizedString(@"add.actionsheet.upload", @"Upload")])
        {
            UIActionSheet *sheet = [[UIActionSheet alloc]
                                    initWithTitle:@""
                                    delegate:self 
                                    cancelButtonTitle:nil
                                    destructiveButtonTitle:nil 
                                    otherButtonTitles: NSLocalizedString(@"add.actionsheet.choose-photo", @"Choose Photo from Library"), NSLocalizedString(@"add.actionsheet.upload-document", @"Upload Document"), nil];
            
            [sheet setCancelButtonIndex:[sheet addButtonWithTitle:NSLocalizedString(@"add.actionsheet.cancel", @"Cancel")]];
            if (IS_IPAD) 
            {
                [sheet setActionSheetStyle:UIActionSheetStyleDefault];
                [sheet showFromBarButtonItem:self.actionSheetSenderControl animated:YES];
            } 
            else 
            {
                [sheet showInView:[[self tabBarController] view]];
            }
            
            [self.actionSheetSenderControl setEnabled:NO];
            [self setActionSheet:sheet];
            [sheet release];
        }
        else if ([buttonLabel isEqualToString:NSLocalizedString(@"delete.confirmation.button", @"Delete")])
        {
            [self didConfirmMultipleDelete];
        }
	}
}

- (void) presentModalViewControllerHelper:(UIViewController *)modalViewController
{
    [self presentModalViewControllerHelper:modalViewController animated:YES];
}

- (void) presentModalViewControllerHelper:(UIViewController *)modalViewController animated:(BOOL)animated 
{
    if (IS_IPAD)
    {
        UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:modalViewController];
        [self setPopover:popoverController];
        [popoverController release];
        
        [popover presentPopoverFromBarButtonItem:self.actionSheetSenderControl
                        permittedArrowDirections:UIPopoverArrowDirectionUp animated:animated];
    } else  {
        [[self navigationController] presentModalViewController:modalViewController animated:animated];
    }
}

- (void)dismissModalViewControllerHelper
{
    [self dismissModalViewControllerHelper:YES];
}

- (void)dismissModalViewControllerHelper:(BOOL)animated
{
    if (IS_IPAD) 
    {
		if(nil != popover && [popover isPopoverVisible]) {
			[popover dismissPopoverAnimated:animated];
            [self setPopover:nil];
		}
	}
    else 
    {
        [self dismissModalViewControllerAnimated:animated];
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
    NSLog(@"%@ %@", [self class], NSStringFromSelector(_cmd));
    
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
    else if ([request isKindOfClass:[ObjectByIdRequest class]])
    {
        ObjectByIdRequest *object = (ObjectByIdRequest*) request;
        
        MetaDataTableViewController *viewController = [[MetaDataTableViewController alloc] initWithStyle:UITableViewStylePlain 
                                                                                              cmisObject:[object repositoryItem] 
                                                                                             accountUUID:[object accountUUID] 
                                                                                                tenantID:self.tenantID];
        [viewController setCmisObjectId:object.repositoryItem.guid];
        [viewController setMetadata:object.repositoryItem.metadata];
        [viewController setSelectedAccountUUID:selectedAccountUUID];
        
        [IpadSupport pushDetailController:viewController withNavigation:self.navigationController andSender:self];
        [viewController release];
    }
    
    [self loadRightBarAnimated:NO];
    [self stopHUD];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    [self.tableView setAllowsSelection:YES];

    if ([request isKindOfClass:[CMISSearchHTTPRequest class]])
    {
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

- (void) downloadQueue:(DownloadQueueProgressBar *)down completeDownloads:(NSArray *)downloads 
{
    //NSLog(@"Download Queue completed!");
    DownloadInfo *download;
    NSInteger successCount = 0;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    for(download in downloads) 
    {
        if(download.downloadStatus == DownloadInfoStatusDownloaded && [fileManager fileExistsAtPath:download.tempFilePath]) 
        {
            successCount++;
            DownloadMetadata *metadata = download.downloadMetadata;
            [[FileDownloadManager sharedInstance] setDownload:metadata.downloadInfo forKey:metadata.key withFilePath:[download.tempFilePath lastPathComponent]];
        }
    }
    
    NSString *message = nil;
    
    if(successCount == [childsToDownload count]) 
    {
        message = NSLocalizedString(@"browse.downloadFolder.success", @"All documents had been saved to your device");
    } 
    else if(successCount != 0) 
    {
        NSInteger documentsMissed = [childsToDownload count] - successCount;
        if(documentsMissed == 1)
        {
            message = NSLocalizedString(@"browse.downloadFolder.partialSuccess.singular", @"Partial Success 1 item didn't download");
        }
        else 
        {
            message = [NSString stringWithFormat:NSLocalizedString(@"browse.downloadFolder.partialSuccess.plural", @"Partial Success x item didn't download"), documentsMissed];
        }
    } 
    else 
    {
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
    
    if([mediaType isEqualToString:(NSString *) kUTTypeImage])
    {
         //When we take an image with the camera we should add manually the EXIF metadata
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
        
        [self startHUD];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
            
            [self presentUploadFormWithItem:videoUpload andHelper:nil];
            
            [self stopHUD];
        });
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

//This will be called when location services are not enabled
- (void)photoCaptureSaver:(PhotoCaptureSaver *)photoSaver didFinishSavingWithURL:(NSURL *)imageURL
{
    NSLog(@"Image saved into the camera roll and to a temp file");
    AssetUploadItem *assetUploadHelper =  [[[AssetUploadItem alloc] initWithAssetURL:nil] autorelease];
    [assetUploadHelper setTempImagePath:[imageURL path]];
    UploadInfo *uploadInfo = [[[UploadInfo alloc] init] autorelease];
    [uploadInfo setUploadFileURL:imageURL];
    [uploadInfo setUploadType:UploadFormTypePhoto];
    [self presentUploadFormWithItem:uploadInfo andHelper:assetUploadHelper];;
    [self stopHUD];
}

- (void)photoCaptureSaver:(PhotoCaptureSaver *)photoSaver didFailWithError:(NSError *)error
{
    NSLog(@"Error trying to save the image in the camera roll %@", error  );
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:NSLocalizedString(@"browse.capturephoto.failed.title", @"Photo capture failed alert title") 
                          message: NSLocalizedString(@"browse.capturephoto.failed.message", @"Photo capture failed alert message")
                          delegate: nil
                          cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK Button Text")
                          otherButtonTitles:nil];
    [alert show];
    [alert release];
    [self stopHUD];
}

- (void)didPresentAlertView:(UIAlertView *)alertView {
	[alertField becomeFirstResponder];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (IS_IPAD)
    {
		if (nil != popover && [popover isPopoverVisible])
        {
			[popover dismissPopoverAnimated:YES];
            [self setPopover:nil];
		}
	}
    
    if (alertView.tag == kDownloadFolderAlert) 
    {
        [self continueDownloadFromAlert:alertView clickedButtonAtIndex:buttonIndex];
        return;
    }
    else if (alertView.tag == kCancelUploadPrompt) 
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
    else if (alertView.tag == kDismissFailedUploadPrompt)
    {
        if (buttonIndex == alertView.cancelButtonIndex)
        {
            [[UploadsManager sharedManager] clearUpload:self.uploadToDismiss.uuid];
        }
        else {
            [[UploadsManager sharedManager] retryUpload:self.uploadToDismiss.uuid];
        }
    }
    else if (alertView.tag == kConfirmMultipleDeletePrompt)
    {
        if (buttonIndex != alertView.cancelButtonIndex)
        {
            [self didConfirmMultipleDelete];
        }
        [self setEditing:NO];
        return;
    }
    
    
	NSString *userInput = [alertField text];
	NSString *strippedUserInput = [userInput stringByReplacingOccurrencesOfString:@" " withString:@""];
	self.alertField = nil;
	
	if (1 == buttonIndex && [strippedUserInput length] > 0) {
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

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    if (tableView == self.tableView) 
    {
        return [self.repositoryItems count];
    } 
    else 
    {
        return [self.searchResultItems count];
    }
    
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	RepositoryItemCellWrapper *cellWrapper = nil;
    
    if (tableView == self.tableView)
    {
        cellWrapper = [self.repositoryItems objectAtIndex:indexPath.row];
    }
    else 
    {
        cellWrapper = [self.searchResultItems objectAtIndex:indexPath.row];
    }
    
    return [cellWrapper createCellInTableView:tableView];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
    // Row deselection - only interested when in edit mode
{
	RepositoryItem *child = nil;
    RepositoryItemCellWrapper *cellWrapper = nil;

    if ([tableView isEditing])
    {
        if (tableView == self.tableView)
        {
            cellWrapper = [self.repositoryItems objectAtIndex:[indexPath row]];
        }
        else
        {
            cellWrapper = [self.searchResultItems objectAtIndex:[indexPath row]];
        }

        child = [cellWrapper anyRepositoryItem];
        [self.multiSelectToolbar userDidDeselectItem:child atIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
    // Row selection (all modes)
{
	RepositoryItem *child = nil;
    RepositoryItemCellWrapper *cellWrapper = nil;
    
    if (tableView == self.tableView) 
    {
        cellWrapper = [self.repositoryItems objectAtIndex:[indexPath row]];
    } 
    else 
    {
        cellWrapper = [self.searchResultItems objectAtIndex:[indexPath row]];
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    }
    
    child = [cellWrapper anyRepositoryItem];
    
    // Don't continue if there's nothing to highlight
    if (!child)
    {
        return;
    }
    
    if ([tableView isEditing])
    {
        [self.multiSelectToolbar userDidSelectItem:child atIndexPath:indexPath];
    }
    else
    {
        if ([child isFolder])
        {
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
        else
        {
            if (child.contentLocation)
            {
                [tableView setAllowsSelection:NO];
                [[PreviewManager sharedManager] previewItem:child delegate:self accountUUID:selectedAccountUUID tenantID:self.tenantID];
            }
            else
            {
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
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    RepositoryItemCellWrapper *cellWrapper = [self cellWrapperForIndexPath:indexPath];
	RepositoryItem *child = [cellWrapper anyRepositoryItem];
    UploadInfo *uploadInfo = cellWrapper.uploadInfo;
	
    if (child)
    {
        if (cellWrapper.isDownloadingPreview)
        {
            [[PreviewManager sharedManager] cancelPreview];
        }
        else
        {
            [self.tableView setAllowsSelection:NO];
            [self startHUD];
            
            ObjectByIdRequest *object = [[ObjectByIdRequest defaultObjectById:child.guid accountUUID:selectedAccountUUID tenantID:self.tenantID] retain];
            [object setDelegate:self];
            [object startAsynchronous];
            [self setMetadataDownloader:object];
            [object release];
        }
    }
    else if (uploadInfo && [uploadInfo uploadStatus] != UploadInfoStatusFailed)
    {
        [self setUploadToCancel:cellWrapper];
        UIAlertView *confirmAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"uploads.cancelAll.title", @"Uploads")
                                                                message:NSLocalizedString(@"uploads.cancel.body", @"Would you like to...")
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"No", @"No")
                                                      otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil] autorelease];
        [confirmAlert setTag:kCancelUploadPrompt];
        [confirmAlert show];
    }
    else if (uploadInfo && [uploadInfo uploadStatus] == UploadInfoStatusFailed)
    {
        [self setUploadToDismiss:uploadInfo];
        if (IS_IPAD)
        {
            FailedTransferDetailViewController *viewController = [[FailedTransferDetailViewController alloc] initWithTitle:NSLocalizedString(@"Upload Failed", @"Upload failed popover title")
                                                                                                                   message:[uploadInfo.error localizedDescription]];
            
            [viewController setUserInfo:uploadInfo];
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
        }
        else
        {
            UIAlertView *uploadFailDetail = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Upload Failed", @"")
                                                                        message:[uploadInfo.error localizedDescription]
                                                                       delegate:self
                                                              cancelButtonTitle:NSLocalizedString(@"Close", @"Close")
                                                              otherButtonTitles:NSLocalizedString(@"Retry", @"Retry"), nil] autorelease];
            [uploadFailDetail setTag:kDismissFailedUploadPrompt];
            [uploadFailDetail show];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

#pragma mark - FailedUploadDetailViewController Delegate

// This is called from the FailedTransferDetailViewController and it means the user wants to retry the failed upload
- (void)closeFailedUpload:(FailedTransferDetailViewController *)sender
{
    if (nil != popover && [popover isPopoverVisible]) 
    {
        // Removing us as the delegate so we don't get the dismiss call at this point the user retried the upload and 
        // we don't want to clear the upload
        [popover setDelegate:nil];
        [popover dismissPopoverAnimated:YES];
        [self setPopover:nil];

        UploadInfo *uploadInfo = (UploadInfo *)sender.userInfo;
        [[UploadsManager sharedManager] retryUpload:uploadInfo.uuid];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    // TODO: we should check the number of sections in the table view before assuming that there will be a Site Selection
    if(tableView == self.searchController.searchResultsTableView)
    {
        if ([searchRequest.results count] == 30) { // TODO EXTERNALIZE THIS OR MAKE IT CONFIGURABLE
            return NSLocalizedString(@"searchview.footer.displaying-30-results", 
                                     @"Displaying the first 30 results");
        }
        
        return nil;
    }
    else {
        return nil;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    
    if(tableView == self.searchController.searchResultsTableView)
    {
        NSString *sectionTitle = [self tableView:tableView titleForFooterInSection:section];
        if ((nil == sectionTitle))
            return nil;
        
        //The height gets adjusted if it is less than the needed height
        TableViewHeaderView *headerView = [[[TableViewHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, [tableView bounds].size.width, 10) label:sectionTitle] autorelease];
        [headerView setBackgroundColor:[ThemeProperties browseFooterColor]];
        [headerView.textLabel setTextColor:[ThemeProperties browseFooterTextColor]];
        
        return headerView;
    }
    else {
        return nil;
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if(tableView == self.searchController.searchResultsTableView)
    {
        NSString *sectionTitle = [self tableView:tableView titleForFooterInSection:section];
        if ((nil == sectionTitle))
            return 0.0f;
        
        TableViewHeaderView *headerView = [[[TableViewHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, [tableView bounds].size.width, 10) label:sectionTitle] autorelease];
        return headerView.frame.size.height;
    }
    else {
        return 0;
    }
}

#pragma mark - UIPopoverController Delegate methods

// This is called when the popover was dismissed by the user by tapping in another part of the screen,
// We want to to clear the upload
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [[UploadsManager sharedManager] clearUpload:self.uploadToDismiss.uuid];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	RepositoryItemCellWrapper *cellWrapper = nil;
    if (tableView == self.tableView)
    {
        cellWrapper = [self.repositoryItems objectAtIndex:indexPath.row];
    }
    else 
    {
        cellWrapper = [self.searchResultItems objectAtIndex:indexPath.row];
    }
    
    return [cellWrapper.anyRepositoryItem canDeleteObject] ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	RepositoryItemCellWrapper *cellWrapper = nil;
    if (tableView == self.tableView)
    {
        cellWrapper = [self.repositoryItems objectAtIndex:indexPath.row];
    }
    else 
    {
        cellWrapper = [self.searchResultItems objectAtIndex:indexPath.row];
    }
    
    return cellWrapper.uploadInfo == nil || cellWrapper.uploadInfo.uploadStatus == UploadInfoStatusUploaded;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Enable single item delete action
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        RepositoryItem *item = [[self.repositoryItems objectAtIndex:indexPath.row] anyRepositoryItem];

        DeleteObjectRequest *deleteRequest = [DeleteObjectRequest deleteRepositoryItem:item accountUUID:selectedAccountUUID tenantID:tenantID];
        [deleteRequest startSynchronous];

        NSError *error = [deleteRequest error];
        if (!error)
        {
            /*
            if (IS_IPAD && item.guid == ?? TODO: Where can we get this from?)
            {
                // Deleting the item being previewed, so let's clear it
                [IpadSupport clearDetailController];
            }
             */

            [self.repositoryItems removeObjectAtIndex:[indexPath row]];
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self loadRightBarAnimated:NO];
            if (!IS_IPAD)
            {
                [self.tableView setContentOffset:CGPointMake(0., 40.)];
            }
        }
    }    
}

#pragma mark - FolderItemsHTTPRequest Delegate

- (void)folderItemsRequestFinished:(ASIHTTPRequest *)request 
{
	if ([request isKindOfClass:[FolderItemsHTTPRequest class]] && [request isEqual:itemDownloader]) 
    {
		// if we're reloading then just tell the view to update
		if (replaceData)
        {
			replaceData = NO;
            [self initRepositoryItems];
			[[self tableView] reloadData];
            [self dataSourceFinishedLoadingWithSuccess:YES];
        }
		// otherwise we're loading a child which needs to
		// be created and pushed onto the nav stack
		else
        {
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

- (void)folderItemsRequestFailed:(ASIHTTPRequest *)request
{
    [self dataSourceFinishedLoadingWithSuccess:NO];
	[self stopHUD];
}


#pragma mark - Instance Methods

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

- (void)downloadWasCancelled:(DownloadProgressBar *)down
{
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
    NSMutableArray *items = nil;
    
    if ([self.searchController isActive])
    {
        items = self.searchResultItems;
    }
    else
    {
        items = self.repositoryItems;
    }
    
    if (itemGuid != nil && items != nil)
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
        NSUInteger matchingIndex = [items indexOfObjectPassingTest:matchesRepostoryItem];
        if (matchingIndex != NSNotFound)
        {
            indexPath = [NSIndexPath indexPathForRow:matchingIndex inSection:0];
        }
    }
    
    return indexPath;
}

- (void)dataSourceFinishedLoadingWithSuccess:(BOOL) wasSuccessful
{
    [self.refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
    [self loadRightBarAnimated:YES];

    if (wasSuccessful)
    {
        [self setLastUpdated:[NSDate date]];
        [self.refreshHeaderView refreshLastUpdatedDate];
        // For non-iPad devices, re-hide the search view
        if (!IS_IPAD)
        {
            [[self tableView] setContentOffset:CGPointMake(0, 40) animated:YES];
        }
    }
}

- (BOOL)isEditing
{
    return [[self tableView] isEditing];
}

- (void)setEditing:(BOOL)editing
{
    [self setEditing:editing animated:YES];
}
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    // Multi-select: we toggle this here to maintain the swipe-to-delete ability
    [self.tableView setAllowsMultipleSelectionDuringEditing:editing];
    [self.tableView setEditing:editing animated:YES];
    [[self refreshHeaderView] setHidden:editing];

    if (editing)
    {
        [self.multiSelectToolbar didEnterMultiSelectMode];
        [self loadRightBarForEditMode];
    }
    else
    {
        [self.multiSelectToolbar didLeaveMultiSelectMode];
        [self loadRightBarAnimated:YES];
    }

    [self.navigationItem setHidesBackButton:editing animated:YES];
    [UIView beginAnimations:@"searchbar" context:nil];
    [searchController.searchBar setAlpha:(editing ? 0.7f : 1)];
    [UIView commitAnimations];
    [searchController.searchBar setUserInteractionEnabled:!editing];
}

#pragma mark - UploadFormDelegate

- (void)dismissUploadViewController:(UploadFormTableViewController *)recipeAddViewController didUploadFile:(BOOL)success
{
    [recipeAddViewController dismissModalViewControllerAnimated:YES];
}

#pragma mark - SavedDocumentPickerDelegate

- (void) savedDocumentPicker:(SavedDocumentPickerController *)picker didPickDocuments:(NSArray *)documentURLs {
    NSLog(@"User selected the documents %@", documentURLs);
    
    //Hide popover on iPad
    [self savedDocumentPickerDidCancel:picker];
    [[UploadsManager sharedManager] setExistingDocuments:[self existingDocuments] forUpLinkRelation:[[self.folderItems item] identLink]];
    
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
    if (IS_IPAD)
    {
		if ([popover isPopoverVisible]) 
        {
			[popover dismissPopoverAnimated:YES];
            [self setPopover:nil];
		}
	}
}

- (void)presentUploadFormWithItem:(UploadInfo *)uploadInfo andHelper:(id<UploadHelper>)helper;
{
    UploadFormTableViewController *formController = [[UploadFormTableViewController alloc] init];
    [formController setExistingDocumentNameArray:[self existingDocuments]];
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
    [formController release];
}

- (void)presentUploadFormWithMultipleItems:(NSArray *)infos andUploadType:(UploadFormType)uploadType
{
    UploadFormTableViewController *formController = [[UploadFormTableViewController alloc] init];
    [formController setExistingDocumentNameArray:[self existingDocuments]];
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
    [formController release];
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
    
    //Setting the name with the original date the photo/video was taken
    NSArray *existingDocuments = [[UploadsManager sharedManager] existingDocumentsForUplinkRelation:[[self.folderItems item] identLink]];
    NSDate *assetDate = [asset valueForProperty:ALAssetPropertyDate];
    [uploadInfo setFilenameWithDate:assetDate andExistingDocuments:existingDocuments];

    return [uploadInfo autorelease];
}

- (UploadInfo *)uploadInfoFromURL:(NSURL *)fileURL
{
    UploadInfo *uploadInfo = [[UploadInfo alloc] init];
    [uploadInfo setUploadFileURL:fileURL];
    [uploadInfo setUploadType:UploadFormTypeDocument];
    [uploadInfo setFilename:[[fileURL lastPathComponent] stringByDeletingPathExtension]];

    return [uploadInfo autorelease];
}

- (NSArray *)existingDocuments
{
    NSMutableArray *existingDocuments = [NSMutableArray arrayWithCapacity:[self.repositoryItems count]];
    for(RepositoryItemCellWrapper *wrapper in self.repositoryItems)
    {
        [existingDocuments addObject:[wrapper itemTitle]];
    }
    return [NSArray arrayWithArray:existingDocuments];
}

- (UITableView *)activeTableView
{
    UITableView *tableView = nil;
    
    if ([searchController isActive])
    {
        tableView = [self.searchController searchResultsTableView];
    }
    else
    {
        tableView = self.tableView;
    }
    return tableView;
}

- (RepositoryItemCellWrapper *)cellWrapperForIndexPath:(NSIndexPath *)indexPath
{
    RepositoryItemCellWrapper *cellWrapper = nil;
    
    if ([searchController isActive])
    {
        cellWrapper = [self.searchResultItems objectAtIndex:indexPath.row];
    }
    else
    {
        cellWrapper = [self.repositoryItems objectAtIndex:indexPath.row];
    }
    return cellWrapper;
}

- (RepositoryItemTableViewCell *)tableViewCellForIndexPath:(NSIndexPath *)indexPath
{
    RepositoryItemTableViewCell *cell = nil;
    
    if ([searchController isActive])
    {
        cell = (RepositoryItemTableViewCell *)[searchController.searchResultsTableView cellForRowAtIndexPath:indexPath];
    }
    else
    {
        cell = (RepositoryItemTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    }
    return cell;
}

#pragma mark - UploadFormTableViewController delegate method

- (void)uploadFormDidFinishWithItems:(NSArray *)items
{
    [self addUploadsToRepositoryItems:items insertCells:YES];
}

#pragma mark - SearchBarDelegate Protocol Methods

- (void)searchDisplayController:(UISearchDisplayController *)controller didShowSearchResultsTableView:(UITableView *)tableView
{
    [self fixSearchControllerFrame];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar 
{
    NSString *searchPattern = [[searchBar text] trimWhiteSpace];
    
    if ([searchPattern length] > 0)
    {
        NSLog(@"Start searching for %@", searchPattern);
        // Cancel if there's a current request
        if ([searchRequest isExecuting])
        {
            [searchRequest clearDelegatesAndCancel];
            [self stopHUD];
            [self setSearchRequest:nil];
        }
        
        [self startHUD];
        
        CMISSearchHTTPRequest *searchReq = [[[CMISSearchHTTPRequest alloc] initWithSearchPattern:searchPattern
                                                                                  folderObjectId:self.guid 
                                                                                     accountUUID:self.selectedAccountUUID
                                                                                        tenantID:self.tenantID] autorelease];
        [self setSearchRequest:searchReq];        
        [searchRequest setDelegate:self];
        [searchRequest setShow500StatusError:NO];
        [searchRequest startAsynchronous];
    }
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller 
{
    // Cleaning up the search results
    [self setSearchRequest:nil];
}

#pragma mark - MBProgressHUD Helper Methods

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
        NSLog(@"Reselecting document with nodeRef %@ at selectedIndex %@", fileMetadata.objectId, selectedIndex);
        [self.tableView selectRowAtIndexPath:selectedIndex animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kDetailViewControllerChangedNotification object:nil];
}

- (void) applicationWillResignActive:(NSNotification *) notification
{
    NSLog(@"applicationWillResignActive in RepositoryNodeViewController");
    [popover dismissPopoverAnimated:NO];
    self.popover = nil;
    
    [self cancelAllHTTPConnections];
}

- (void)uploadQueueChanged:(NSNotification *) notification
{
    // Something in the queue changed, we are interested if a current upload (ghost cell) was cleared
    NSMutableArray *indexPaths = [NSMutableArray array];
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (NSUInteger index = 0; index < [self.repositoryItems count]; index++)
    {
        RepositoryItemCellWrapper *cellWrapper = [self.repositoryItems objectAtIndex:index];
        // We keep the cells for finished uploads and failed uploads
        if (cellWrapper.uploadInfo && [cellWrapper.uploadInfo uploadStatus] != UploadInfoStatusUploaded && ![[UploadsManager sharedManager] isManagedUpload:cellWrapper.uploadInfo.uuid])
        {
            _GTMDevLog(@"We are displaying an upload that is not currently managed");
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            [indexPaths addObject:indexPath];
            [indexSet addIndex:index];
        }
    }
    
    if ([indexPaths count] > 0)
    {
        [self.repositoryItems removeObjectsAtIndexes:indexSet];
        [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:kDefaultTableViewRowAnimation];
    }
}

- (void)uploadFinished:(NSNotification *)notification
{
    BOOL reload = [[notification.userInfo objectForKey:@"reload"] boolValue];
    
    if (reload)
    {
        NSString *itemGuid = [notification.userInfo objectForKey:@"itemGuid"];
        NSPredicate *guidPredicate = [NSPredicate predicateWithFormat:@"guid == %@", itemGuid];
        NSArray *itemsMatch = [[self.folderItems children] filteredArrayUsingPredicate:guidPredicate];
        
        //An upload just finished in this node, we should reload the node to see the latest changes
        //See FileUrlHandler for an example where this notification gets posted
        if([itemsMatch count] > 0)
        {
            [self reloadFolderAction];
        }
    }
    else
    {
        UploadInfo *uploadInfo = [notification.userInfo objectForKey:@"uploadInfo"];
        if (uploadInfo.uploadStatus == UploadInfoStatusUploaded)
        {
            NSIndexPath *indexPath = [self indexPathForNodeWithGuid:uploadInfo.cmisObjectId];
            if (indexPath != nil)
            {
                UploadProgressTableViewCell *cell = (UploadProgressTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                [cell setUploadInfo:uploadInfo];
                // This cell is no longer valid to represent the uploaded file, we need to reload the cell
                [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
            }
        }

        if (self.isEditing)
        {
            [self loadRightBarForEditMode:NO];
        }
        else
        {
            [self loadRightBarAnimated:NO];
        }
    }
}

#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (![searchController isActive] && ![self isEditing])
    {
        [self.refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (![searchController isActive] && ![self isEditing])
    {
        [self.refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
    }
}

#pragma mark - EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view
{
    [self reloadFolderAction];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view
{
	return (HUD != nil);
}

- (NSDate *)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view
{
	return [self lastUpdated];
}

#pragma mark - MultiSelectActionsDelegate Methods

- (void)multiSelectItemsDidChange:(MultiSelectActionsToolbar *)msaToolbar items:(NSArray *)selectedItems
{
    BOOL downloadActionIsViable = ([selectedItems count] > 0);
    BOOL deleteActionIsViable = ([selectedItems count] > 0);
    
    for (RepositoryItem *item in selectedItems)
    {
        if ([item isFolder])
        {
            downloadActionIsViable = NO;
        }
        
        if (![item canDeleteObject])
        {
            deleteActionIsViable = NO;
        }
    }
    
    [self.multiSelectToolbar enableActionButtonNamed:kMultiSelectDownload isEnabled:downloadActionIsViable];
    [self.multiSelectToolbar enableActionButtonNamed:kMultiSelectDelete isEnabled:deleteActionIsViable];
}

- (void)multiSelectUserDidPerformAction:(MultiSelectActionsToolbar *)msaToolbar named:(NSString *)name withItems:(NSArray *)selectedItems atIndexPaths:(NSArray *)selectedIndexPaths
{
    if ([name isEqual:kMultiSelectDownload])
    {
        [[DownloadManager sharedManager] queueRepositoryItems:selectedItems withAccountUUID:selectedAccountUUID andTenantId:tenantID];
        [self setEditing:NO];
    }
    else if ([name isEqual:kMultiSelectDelete])
    {
        [itemsToDelete release];
        itemsToDelete = [[selectedItems copy] retain];
        [self askDeleteConfirmationForMultipleItems];
    }
}

#pragma mark - PreviewManagerDelegate Methods

- (void)previewManager:(PreviewManager *)manager downloadCancelled:(DownloadInfo *)info
{
    NSIndexPath *indexPath = [self indexPathForNodeWithGuid:info.repositoryItem.guid];
    RepositoryItemTableViewCell *cell = [self tableViewCellForIndexPath:indexPath];
    RepositoryItemCellWrapper *cellWrapper = [self cellWrapperForIndexPath:indexPath];

    [manager setProgressIndicator:nil];
    [cell.progressBar setHidden:YES];
    [cell.details setHidden:NO];
    [cellWrapper setIsDownloadingPreview:NO];

    [self.activeTableView setAllowsSelection:YES];
}

- (void)previewManager:(PreviewManager *)manager downloadFailed:(DownloadInfo *)info withError:(NSError *)error
{
    NSIndexPath *indexPath = [self indexPathForNodeWithGuid:info.repositoryItem.guid];
    RepositoryItemTableViewCell *cell = [self tableViewCellForIndexPath:indexPath];
    RepositoryItemCellWrapper *cellWrapper = [self cellWrapperForIndexPath:indexPath];

    [manager setProgressIndicator:nil];
    [cell.progressBar setHidden:YES];
    [cell.details setHidden:NO];
    [cellWrapper setIsDownloadingPreview:NO];

    [self.activeTableView setAllowsSelection:YES];
}

- (void)previewManager:(PreviewManager *)manager downloadFinished:(DownloadInfo *)info
{
    UITableView *tableView = [self activeTableView];
    NSIndexPath *indexPath = [self indexPathForNodeWithGuid:info.repositoryItem.guid];
    RepositoryItemTableViewCell *cell = [self tableViewCellForIndexPath:indexPath];
    RepositoryItemCellWrapper *cellWrapper = [self cellWrapperForIndexPath:indexPath];

    [manager setProgressIndicator:nil];
    [cell.progressBar setHidden:YES];
    [cell.details setHidden:NO];
    [cellWrapper setIsDownloadingPreview:NO];
    
	DocumentViewController *doc = [[DocumentViewController alloc] initWithNibName:kFDDocumentViewController_NibName bundle:[NSBundle mainBundle]];
	[doc setCmisObjectId:info.repositoryItem.guid];
    [doc setContentMimeType:info.repositoryItem.contentStreamMimeType];
    [doc setHidesBottomBarWhenPushed:YES];
    [doc setSelectedAccountUUID:selectedAccountUUID];
    [doc setTenantID:self.tenantID];
    
    DownloadMetadata *fileMetadata = info.downloadMetadata;
    NSString *filename = fileMetadata.key;
    [doc setFileMetadata:fileMetadata];
    [doc setFileName:filename];
    [doc setFilePath:info.tempFilePath];
    
	[IpadSupport pushDetailController:doc withNavigation:self.navigationController andSender:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(detailViewControllerChanged:) name:kDetailViewControllerChangedNotification object:nil];
    
	[doc release];
    
    [selectedIndex release];
    selectedIndex = willSelectIndex;
    willSelectIndex = nil;
    
    [tableView setAllowsSelection:YES];
}

- (void)previewManager:(PreviewManager *)manager downloadStarted:(DownloadInfo *)info
{
    NSIndexPath *indexPath = [self indexPathForNodeWithGuid:info.repositoryItem.guid];
    RepositoryItemTableViewCell *cell = [self tableViewCellForIndexPath:indexPath];
    RepositoryItemCellWrapper *cellWrapper = [self cellWrapperForIndexPath:indexPath];

    [manager setProgressIndicator:cell.progressBar];
    [cell.progressBar setProgress:manager.currentProgress];
    [cell.details setHidden:YES];
    [cell.progressBar setHidden:NO];
    [cellWrapper setIsDownloadingPreview:YES];
}

#pragma mark - Delete objects

- (void)askDeleteConfirmationForMultipleItems
{
    UIActionSheet *sheet = [[[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"delete.confirmation.multiple.message", @"Are you sure you want to delete x items"), [itemsToDelete count]]
                                                        delegate:self
                                               cancelButtonTitle:NSLocalizedString(@"cancelButton", @"Cancel")
                                          destructiveButtonTitle:NSLocalizedString(@"delete.confirmation.button", @"Delete")
                                               otherButtonTitles:nil, nil] autorelease];
    [self setActionSheet:sheet];
    // Need to use top-level view to host the action sheet, as the multi-select bar is on top of the tabBarController
    [sheet showInView:[[UIApplication sharedApplication] keyWindow]];
}

- (void)didConfirmMultipleDelete
{
    self.deleteQueueProgressBar = [DeleteQueueProgressBar createWithItems:itemsToDelete delegate:self andMessage:NSLocalizedString(@"Deleting Item", @"Deleting Item")];
    [self.deleteQueueProgressBar setSelectedUUID:selectedAccountUUID];
    [self.deleteQueueProgressBar setTenantID:tenantID];
    [self.deleteQueueProgressBar startDeleting];
}

#pragma mark - DeleteQueueProgressBar Delegate Methods

- (void)deleteQueue:(DeleteQueueProgressBar *)deleteQueueProgressBar completedDeletes:(NSArray *)deletedItems
{
    NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] init];
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:[deletedItems count]];
    for (RepositoryItem *item in deletedItems)
    {
        [indexPaths addObject:[self indexPathForNodeWithGuid:item.guid]];
        [indexes addIndex:[[indexPaths lastObject] row]];
    }
    
    [self.repositoryItems removeObjectsAtIndexes:indexes];
    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:kDefaultTableViewRowAnimation];
    [indexes release];
    
    [self setEditing:NO];
}

- (void)deleteQueueWasCancelled:(DeleteQueueProgressBar *)deleteQueueProgressBar
{
    self.deleteQueueProgressBar = nil;
    [self setEditing:NO];
}

@end
