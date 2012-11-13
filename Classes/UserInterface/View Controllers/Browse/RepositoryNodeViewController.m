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

#import "RepositoryNodeViewController.h"
#import "Utility.h"
#import "Theme.h"
#import "AppProperties.h"
#import "IFTemporaryModel.h"
#import "FileUtils.h"
#import "IpadSupport.h"
#import "ThemeProperties.h"
#import "FileDownloadManager.h"
#import "FolderDescendantsRequest.h"
#import "AssetUploadItem.h"
#import "AGImagePickerController.h"
#import "UploadProgressTableViewCell.h"
#import "RepositoryItemCellWrapper.h"
#import "UploadsManager.h"
#import "AlfrescoAppDelegate.h"
#import "DocumentsNavigationController.h"
#import "BrowseRepositoryNodeDelegate.h"
#import "SearchRepositoryNodeDelegate.h"

NSInteger const kDownloadFolderAlert = 1;
NSInteger const kConfirmMultipleDeletePrompt = 4;
UITableViewRowAnimation const kDefaultTableViewRowAnimation = UITableViewRowAnimationFade;
NSInteger const kAddActionSheetTag = 100;
NSInteger const kUploadActionSheetTag = 101;
NSInteger const kDeleteActionSheetTag = 103;

NSString * const kMultiSelectDownload = @"downloadAction";
NSString * const kMultiSelectDelete = @"deleteAction";

@interface RepositoryNodeViewController ()
@property (nonatomic, retain) UIActionSheet *actionSheet;
@end

@interface RepositoryNodeViewController (PrivateMethods)
- (void)loadRightBar;
- (void)loadRightBarForEditMode;
- (void)cancelAllHTTPConnections;
- (void)processAddActionSheetWithButtonTitle:(NSString *)buttonLabel;
- (void)processUploadActionSheetWithButtonTitle:(NSString *)buttonLabel;
- (void)processDeleteActionSheetWithButtonTitle:(NSString *)buttonLabel;
- (void)presentModalViewControllerHelper:(UIViewController *)modalViewController;
- (void)presentModalViewControllerHelper:(UIViewController *)modalViewController animated:(BOOL)animated;
- (void)dismissModalViewControllerHelper;
- (void)dismissModalViewControllerHelper:(BOOL)animated;
- (void)dismissPopover;
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
- (UploadInfo *)uploadInfoFromAsset:(ALAsset *)asset andExistingDocs:(NSArray *)existingDocs;
- (UploadInfo *)uploadInfoFromURL:(NSURL *)fileURL;
- (NSArray *)existingDocuments;
@end

@implementation RepositoryNodeViewController

@synthesize guid = _guid;
@synthesize folderItems = _folderItems;
@synthesize downloadQueueProgressBar = _downloadQueueProgressBar;
@synthesize deleteQueueProgressBar = _deleteQueueProgressBar;
@synthesize postProgressBar = _postProgressBar;
@synthesize folderDescendantsRequest = _folderDescendantsRequest;
@synthesize popover = _popover;
@synthesize alertField = _alertField;
@synthesize HUD = _HUD;
@synthesize photoSaver = _photoSaver;
@synthesize tableView = _tableView;
@synthesize selectedAccountUUID = _selectedAccountUUID;
@synthesize tenantID = _tenantID;
@synthesize actionSheetSenderControl = _actionSheetSenderControl;
@synthesize refreshHeaderView = _refreshHeaderView;
@synthesize lastUpdated = _lastUpdated;
@synthesize multiSelectToolbar = _multiSelectToolbar;
@synthesize actionSheet = _actionSheet;
@synthesize browseDelegate = _browseDelegate;
@synthesize browseDataSource = _browseDataSource;
@synthesize searchDelegate = _searchDelegate;
@synthesize imagePickerController = _imagePickerController;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self cancelAllHTTPConnections];
    [self.popover dismissPopoverAnimated:NO];
    [_multiSelectToolbar removeFromSuperview];
    [[PreviewManager sharedManager] setDelegate:nil];
    [[PreviewManager sharedManager] setProgressIndicator:nil];
    
    [_guid release];
    [_folderItems release];
    [_downloadQueueProgressBar release];
    [_deleteQueueProgressBar release];
    [_postProgressBar release];
    [_folderDescendantsRequest release];
    [_popover release];
    [_alertField release];
    [_HUD release];
    [_photoSaver release];
    [_tableView release];
    [_selectedAccountUUID release];
    [_tenantID release];
    [_actionSheetSenderControl release];
    [_refreshHeaderView release];
    [_lastUpdated release];
    [_multiSelectToolbar release];
    [_actionSheet release];
    [_browseDelegate release];
    [_browseDataSource release];
    [_searchDelegate release];
    [_imagePickerController release];

    [_childsToDownload release];
    [_childsToOverwrite release];
    [_itemsToDelete release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super init];
    if(self)
    {
        _tableViewStyle = style;
    }
    return self;
}

- (void)loadView
{
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:_tableViewStyle];
    
    [tableView setAutoresizesSubviews:YES];
    [tableView setAutoresizingMask:UIViewAutoresizingNone];
    [self setView:tableView];
    [self setTableView:tableView];
    [tableView release];
    
    // Multi-select toolbar
    [self setMultiSelectToolbar:[[[MultiSelectActionsToolbar alloc] initWithParentViewController:self] autorelease]];
    [self.multiSelectToolbar setMultiSelectDelegate:self];
    [self.multiSelectToolbar addActionButtonNamed:kMultiSelectDownload withLabelKey:@"multiselect.button.download" atIndex:0];
    [self.multiSelectToolbar addActionButtonNamed:kMultiSelectDelete withLabelKey:@"multiselect.button.delete" atIndex:1 isDestructive:YES];
    
    //TableView's delegate and datasource
    BrowseRepositoryNodeDelegate *browseDelegate = [[[BrowseRepositoryNodeDelegate alloc] initWithViewController:self] autorelease];
    [browseDelegate setMultiSelectToolbar:self.multiSelectToolbar];
    [browseDelegate setScrollViewDelegate:self];
    RepositoryNodeDataSource *browseDataSource = [[RepositoryNodeDataSource alloc] initWithRepositoryItem:[self.folderItems item] andSelectedAccount:[self selectedAccountUUID]];
    [browseDataSource preLoadChildren:[self.folderItems children]];
    [browseDataSource setTableView:[self tableView]];
    [browseDataSource setDelegate:self];
    [self.tableView setDelegate:browseDelegate];
    [self.tableView setDataSource:browseDataSource];
    [self setBrowseDelegate:browseDelegate];
    [self setBrowseDataSource:browseDataSource];
    [browseDataSource release];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    [self updateCurrentRowSelection];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (self.actionSheet.window)
    {
        [self.actionSheet dismissWithClickedButtonIndex:self.actionSheet.cancelButtonIndex animated:animated];
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self name:kDetailViewControllerChangedNotification object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    // if going to landscape, use the screen height as the popover width and screen width as the popover height
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
    {
        self.popover.contentViewController.contentSizeForViewInPopover = CGSizeMake(screenRect.size.height, screenRect.size.width);
    }
    else
    {
        self.popover.contentViewController.contentSizeForViewInPopover = CGSizeMake(screenRect.size.width, screenRect.size.height);
    }
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
    SearchRepositoryNodeDelegate *searchDelegate = [[SearchRepositoryNodeDelegate alloc] initWithViewController:self];
    [searchDelegate setRepositoryNodeGuid:[self guid]];
    [self setSearchDelegate:searchDelegate];
    [searchDelegate release];

	[Theme setThemeForUIViewController:self];
    [self.tableView setRowHeight:kDefaultTableCellHeight];
    
    [self loadRightBar];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadFinished:) name:kNotificationUploadFinished object:nil];

	// Pull to Refresh
    self.refreshHeaderView = [[[EGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)
                                                                arrowImageName:@"pull-to-refresh.png"
                                                                     textColor:[ThemeProperties pullToRefreshTextColor]] autorelease];
    [self.refreshHeaderView setDelegate:self];
    [self setLastUpdated:[NSDate date]];
    [self.refreshHeaderView refreshLastUpdatedDate];
    [self.tableView addSubview:self.refreshHeaderView];
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
    self.imagePickerController = nil;
    
    [self cancelAllHTTPConnections];
}

- (void)cancelAllHTTPConnections
{    
    [self.folderItems clearDelegatesAndCancel];
    [self.folderDescendantsRequest clearDelegatesAndCancel];
    [self stopHUD];
}

- (void)loadRightBar
{
    [self loadRightBarAnimated:YES];
}

- (void)loadRightBarAnimated:(BOOL)animated
{
    BOOL showAddButton = ([[AppProperties propertyForKey:kBShowAddButton] boolValue] && nil != [self.folderItems item]
                          && ([self.folderItems item].canCreateFolder || [self.folderItems item].canCreateDocument));
    BOOL showEditButton = ([[AppProperties propertyForKey:kBShowEditButton] boolValue]
                           && ([self.browseDataSource.repositoryItems count] > 0));
    
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
                                                                                        action:@selector(performAddAction:event:)] autorelease];
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
//            AlfrescoAppDelegate *appDelegate = (AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate];
//            [appDelegate.splitViewController showMasterPopover:nil];
        }
    }
}

- (void)performAddAction:(id)sender event:(UIEvent *)event
{
	if (IS_IPAD)
    {
		[self dismissPopover];
	}

    UIActionSheet *sheet = [[UIActionSheet alloc]
                            initWithTitle:@""
                            delegate:self 
                            cancelButtonTitle:nil
                            destructiveButtonTitle:nil 
                            otherButtonTitles: nil];
    
    if (self.folderItems.item.canCreateDocument)
    {
        [sheet addButtonWithTitle:NSLocalizedString(@"create.actionsheet.text-file", @"Create Text file")];
    }
    
    if (self.folderItems.item.canCreateFolder)
    {
        [sheet addButtonWithTitle:NSLocalizedString(@"add.actionsheet.create-folder", @"Create Folder")];
    }
    
	if (self.folderItems.item.canCreateDocument)
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
	
	[sheet setCancelButtonIndex:[sheet addButtonWithTitle:NSLocalizedString(@"add.actionsheet.cancel", @"Cancel")]];
    
    if (IS_IPAD)
    {
        [self setActionSheetSenderControl:sender];
        [sheet setActionSheetStyle:UIActionSheetStyleDefault];

        UIBarButtonItem *actionButton = (UIBarButtonItem *)sender;
        if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]))
        {
            [sheet showFromBarButtonItem:sender animated:YES];
        }
        else
        {
            // iOS 5.1 bug workaround
            CGRect actionButtonRect = [(UIView *)[event.allTouches.anyObject view] frame];
            [sheet showFromRect:actionButtonRect inView:self.view.window animated:YES];
        }
        [actionButton setEnabled:NO];
    }
    else
    {
        [sheet showInView:[[self tabBarController] view]];
    }
	
    [sheet setTag:kAddActionSheetTag];
    [self setActionSheet:sheet];
	[sheet release];
}

- (void)performEditAction:(id)sender
{
	if (IS_IPAD)
    {
		[self dismissPopover];
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

	if (buttonIndex != [actionSheet cancelButtonIndex]) 
    {
        switch ([actionSheet tag])
        {
            case kAddActionSheetTag:
                [self processAddActionSheetWithButtonTitle:buttonLabel];
                break;
            case kUploadActionSheetTag:
                [self processUploadActionSheetWithButtonTitle:buttonLabel];
                break;
            case kDeleteActionSheetTag:
                [self processDeleteActionSheetWithButtonTitle:buttonLabel];
                break;
            default:
                break;
        }
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex)
    {
        [self.actionSheetSenderControl setEnabled:YES];
    }
}

- (void)processAddActionSheetWithButtonTitle:(NSString *)buttonLabel
{
    if ([buttonLabel isEqualToString:NSLocalizedString(@"add.actionsheet.take-photo", @"Take Photo")] || [buttonLabel isEqualToString:NSLocalizedString(@"add.actionsheet.take-photo-video", @"Take Photo or Video")]) 
    {
        if (IS_IPAD)
        {
            UIViewController *pickerContainer = [[UIViewController alloc] init];
            if (!self.imagePickerController)
            {
                self.imagePickerController = [[[UIImagePickerController alloc] init] autorelease];
            }
            [pickerContainer setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
            [self.imagePickerController setSourceType:UIImagePickerControllerSourceTypeCamera];
            [self.imagePickerController setMediaTypes:[UIImagePickerController availableMediaTypesForSourceType:self.imagePickerController.sourceType]];
            [self.imagePickerController setDelegate:self];
            [pickerContainer.view addSubview:self.imagePickerController.view];
            
            [self presentModalViewControllerHelper:pickerContainer];
            [self.popover setPopoverContentSize:self.imagePickerController.view.frame.size animated:YES];
            [self.popover setPassthroughViews:[NSArray arrayWithObjects:[[UIApplication sharedApplication] keyWindow], self.imagePickerController.view, nil]];
            
            CGRect rect = self.popover.contentViewController.view.frame;
            self.imagePickerController.view.frame = rect;
            [pickerContainer release];
        }
        else
        {
            if (!self.imagePickerController)
            {
                self.imagePickerController = [[[UIImagePickerController alloc] init] autorelease];
            }
            [self.imagePickerController setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
            [self.imagePickerController setSourceType:UIImagePickerControllerSourceTypeCamera];
            [self.imagePickerController setMediaTypes:[UIImagePickerController availableMediaTypesForSourceType:self.imagePickerController.sourceType]];
            [self.imagePickerController setDelegate:self];
            
            [self presentModalViewControllerHelper:self.imagePickerController];
        }
        
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        
    }
    else if ([buttonLabel isEqualToString:NSLocalizedString(@"add.actionsheet.create-folder", @"Create Folder")]) 
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"add.create-folder.prompt.title", @"Name: ")
                                                        message:@" \r\n "
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"closeButtonText", @"Cancel Button Text")
                                              otherButtonTitles:NSLocalizedString(@"okayButtonText", @"OK Button Text"), nil];
        
        self.alertField = [[[UITextField alloc] initWithFrame:CGRectMake(16.0, 55.0, 252.0, 25.0)] autorelease];
        [self.alertField setBackgroundColor:[UIColor whiteColor]];
        [alert addSubview:self.alertField];
        [alert show];
        [alert release];
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
        
        [sheet setTag:kUploadActionSheetTag];
        [self.actionSheetSenderControl setEnabled:NO];
        [self setActionSheet:sheet];
        [sheet release];
    }
    else if([buttonLabel isEqualToString:NSLocalizedString(@"create.actionsheet.text-file", @"Create Text file")]) 
    {
        NSString *templatePath = [[NSBundle mainBundle] pathForResource:kCreateDocumentTemplateFilename ofType:kCreateDocumentTextExtension];
        NSString *documentName = NSLocalizedString(@"create-document.text-file.template-name", @"My Text file");    
        
        UploadInfo *uploadInfo = [[[UploadInfo alloc] init] autorelease];
        [uploadInfo setUploadFileURL:[NSURL fileURLWithPath:templatePath]];
        [uploadInfo setUploadType:UploadFormTypeCreateDocument];
        [uploadInfo setFilename:documentName];
        [self presentUploadFormWithItem:uploadInfo andHelper:nil];
    }
}

- (void)processUploadActionSheetWithButtonTitle:(NSString *)buttonLabel
{
    if ([buttonLabel isEqualToString:NSLocalizedString(@"add.actionsheet.choose-photo", @"Choose Photo from Library")])
    {
        __block RepositoryNodeViewController *blockSelf = self;
        
        AGImagePickerController *imagePickerController = [[AGImagePickerController alloc] initWithFailureBlock:^(NSError *error) 
         {
             NSLog(@"Fail. Error: %@", error);
             
             if (error == nil) 
             {
                 NSLog(@"User has cancelled.");
                 [blockSelf dismissModalViewControllerHelper];
             } 
             else 
             {
                 // We need to wait for the view controller to appear first.
                 double delayInSeconds = 0.5;
                 dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                 dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                     [blockSelf dismissModalViewControllerHelper:NO];
                     //Fallback in the UIIMagePickerController if the AssetsLibrary is not accessible
                     UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                     [picker setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
                     [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
                     [picker setMediaTypes:[UIImagePickerController availableMediaTypesForSourceType:picker.sourceType]];
                     [picker setDelegate:blockSelf];
                     
                     [blockSelf presentModalViewControllerHelper:picker animated:NO];
                     
                     [picker release];
                 });
             }
             
             [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
             
         } andSuccessBlock:^(NSArray *info) {
             [blockSelf startHUD];
             NSLog(@"User finished picking %d library assets", info.count);
             //It is always NO because we will show the UploadForm next
             //Only affects iPhone, in the iPad the popover dismiss is always animated
             [blockSelf dismissModalViewControllerHelper:NO];
             
             dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                 NSMutableArray *existingDocs = [NSMutableArray arrayWithArray:[blockSelf existingDocuments]];
                 
                 if([info count] == 1)
                 {
                     ALAsset *asset = [info lastObject];
                     UploadInfo *uploadInfo = [blockSelf uploadInfoFromAsset:asset andExistingDocs:existingDocs];
                     [[UploadsManager sharedManager] setExistingDocuments:existingDocs forUpLinkRelation:[[blockSelf.folderItems item] identLink]];
                     dispatch_async(dispatch_get_main_queue(), ^{
                         [blockSelf presentUploadFormWithItem:uploadInfo andHelper:[uploadInfo uploadHelper]];
                         [blockSelf stopHUD];
                     });
                 } 
                 else if([info count] > 1)
                 {
                     NSMutableArray *uploadItems = [NSMutableArray arrayWithCapacity:[info count]];
                     for (ALAsset *asset in info)
                     {
                         @autoreleasepool
                         {
                             UploadInfo *uploadInfo = [blockSelf uploadInfoFromAsset:asset andExistingDocs:existingDocs];
                             [uploadItems addObject:uploadInfo];
                             //Updated the existingDocs array so that uploadInfoFromAsset:andExistingDocs: can choose
                             //the right name
                             [existingDocs addObject:[uploadInfo completeFileName]];
                         }
                     }
                     
                     [[UploadsManager sharedManager] setExistingDocuments:existingDocs forUpLinkRelation:[[blockSelf.folderItems item] identLink]];
                     dispatch_async(dispatch_get_main_queue(), ^{
                         [blockSelf presentUploadFormWithMultipleItems:uploadItems andUploadType:UploadFormTypeLibrary];
                         [blockSelf stopHUD];
                     });
                 }
             });
             
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
    else if([buttonLabel isEqualToString:NSLocalizedString(@"add.actionsheet.upload-document", @"Upload Document from Saved Docs")]) 
    {
        SavedDocumentPickerController *picker = [[SavedDocumentPickerController alloc] initWithMultiSelection:YES];
        [picker setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
        [picker setDelegate:self];
        
        [self presentModalViewControllerHelper:picker];
        [picker release];
    }
}

- (void)processDeleteActionSheetWithButtonTitle:(NSString *)buttonLabel
{
    if ([buttonLabel isEqualToString:NSLocalizedString(@"delete.confirmation.button", @"Delete")])
    {
        [self didConfirmMultipleDelete];
    }
}

- (void) presentModalViewControllerHelper:(UIViewController *)modalViewController
{
    [self presentModalViewControllerHelper:modalViewController animated:YES];
}

- (void)presentModalViewControllerHelper:(UIViewController *)modalViewController animated:(BOOL)animated 
{
    if (IS_IPAD)
    {
        UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:modalViewController];
        [self setPopover:popoverController];
        [popoverController release];
        
        UIView *actionSheetSenderControlView = [self.actionSheetSenderControl valueForKey:@"view"];
        
        if(actionSheetSenderControlView.window != nil)
        {
          [self.popover presentPopoverFromBarButtonItem:self.actionSheetSenderControl
                        permittedArrowDirections:UIPopoverArrowDirectionUp animated:animated];
        }
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
		[self dismissPopover];
	}
    else 
    {
        [self dismissModalViewControllerAnimated:animated];
    }
}

- (void)dismissPopover
{
    if ([self.popover isPopoverVisible])
    {
        [self.popover dismissPopoverAnimated:YES];
        [self setPopover:nil];
    }

}

- (void)updateCurrentRowSelection
{
    BOOL isSearching = [self.searchDelegate.searchController isActive];
    NSIndexPath *selectedRow = [self.tableView indexPathForSelectedRow];
    
    // Retrieving the selectedItem. We want to deselect a folder when the view appears even if we're on the iPad
    // We only set it when working in the main tableView since the search doesn't return folders
    RepositoryItem *selectedItem = nil;
    if (!isSearching && selectedRow)
    {
        RepositoryItemCellWrapper *cellWrapper = [self.browseDataSource.repositoryItems objectAtIndex:selectedRow.row];
        selectedItem = [cellWrapper repositoryItem];
    }
    
    if (!IS_IPAD || [selectedItem isFolder])
    {
        [[self tableView] deselectRowAtIndexPath:selectedRow animated:YES];
        [self.searchDelegate.searchController.searchResultsTableView deselectRowAtIndexPath:selectedRow animated:YES];
    }
    
    if (IS_IPAD)
    {
        NSIndexPath *indexPath = [self indexPathForNodeWithGuid:[IpadSupport getCurrentDetailViewControllerObjectID]];
        if (self.tableView)
        {
            if (indexPath)
            {
                [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            }
            else if (self.tableView.indexPathForSelectedRow)
            {
                [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
            }
        }
    }
    else
    {
        // For non-iPad devices we'll hide the search view to save screen real estate
        [self.tableView setContentOffset:CGPointMake(0, 40)];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(detailViewControllerChanged:) name:kDetailViewControllerChangedNotification object:nil];
}

#pragma mark - Download all items in folder methods

- (void)prepareDownloadAllDocuments 
{    
    BOOL downloadFolderTree = [[AppProperties propertyForKey:kBDownloadFolderTree] boolValue];
    if(downloadFolderTree) {
        [self startHUD];
        
        FolderDescendantsRequest *down = [FolderDescendantsRequest folderDescendantsRequestWithItem:[self.folderItems item] accountUUID:self.selectedAccountUUID];
        [self setFolderDescendantsRequest:down];
        [down setDelegate:self];
        [down startAsynchronous];
    } else {
        NSMutableArray *repositoryItems = [self.browseDataSource repositoryItems];
        NSMutableArray *allDocuments = [NSMutableArray arrayWithCapacity:[repositoryItems count]];
        for (RepositoryItemCellWrapper *cellWrapper in repositoryItems) {
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
    
    [self loadRightBarAnimated:NO];
    [self stopHUD];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    [self.tableView setAllowsSelection:YES];
    [self stopHUD];
}

- (void)downloadAllCheckOverwrite:(NSArray *)allItems {
    RepositoryItem *child;
    [_childsToDownload release];
    _childsToDownload = [[NSMutableArray array] retain];
    [_childsToOverwrite release];
    _childsToOverwrite = [[NSMutableArray array] retain];
    
    for(child in allItems) {
        if(![child isFolder]) {
            if([[NSFileManager defaultManager] fileExistsAtPath:[FileUtils pathToSavedFile:child.title]]) {
                [_childsToOverwrite addObject:child];
            } else {
                [_childsToDownload addObject:child];
            }
        }
    }
    
    [self downloadAllDocuments];
}

- (void)overwritePrompt:(NSString *)filename
{
    UIAlertView *overwritePrompt = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"documentview.overwrite.download.prompt.title", @"")
                                message:[NSString stringWithFormat:NSLocalizedString(@"documentview.overwrite.filename.prompt.message", @"Yes/No Question"), filename]
                               delegate:self 
                      cancelButtonTitle:NSLocalizedString(@"No", @"No") 
                      otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil] autorelease];
    [overwritePrompt setTag:kDownloadFolderAlert];
    [overwritePrompt show];
}

- (void)noFilesToDownloadPrompt
{
    displayErrorMessage(NSLocalizedString(@"documentview.download.noFilesToDownload", @"There are no files to download"));
}

- (void)downloadAllDocuments {
    if([_childsToOverwrite count] > 0) {
        RepositoryItem *lastChild = [_childsToOverwrite lastObject];
        [self overwritePrompt:lastChild.title];
        return;
    }
    
    if([_childsToDownload count] <= 0) {
        [self noFilesToDownloadPrompt];
    } else {
        NSLog(@"Begin downloading %d files", [_childsToDownload count]);
        //download all childs
        self.downloadQueueProgressBar = [DownloadQueueProgressBar createWithNodes:_childsToDownload delegate:self andMessage:NSLocalizedString(@"Downloading Document", @"Downloading Document")];
        [self.downloadQueueProgressBar setSelectedUUID:self.selectedAccountUUID];
        [self.downloadQueueProgressBar startDownloads];
    }
}

- (void) continueDownloadFromAlert: (UIAlertView *) alert clickedButtonAtIndex:(NSInteger)buttonIndex {
    RepositoryItem *lastChild = [_childsToOverwrite lastObject];
    [_childsToOverwrite removeObject:lastChild];
    
    if (buttonIndex != alert.cancelButtonIndex) {
        [_childsToDownload addObject:lastChild];
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
    
    if(successCount == [_childsToDownload count]) 
    {
        message = NSLocalizedString(@"browse.downloadFolder.success", @"All documents had been saved to your device");
    } 
    else if(successCount != 0) 
    {
        NSInteger documentsMissed = [_childsToDownload count] - successCount;
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

- (void) fireNotificationAlert:(NSString *)message
{
    displayErrorMessage(message);
}

#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    BOOL mediaHasJustBeenCaptured = picker.sourceType == UIImagePickerControllerSourceTypeCamera;
    [self dismissModalViewControllerHelper:NO];
    
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage])
    {
        if (mediaHasJustBeenCaptured)
        {
            //When we take an image with the camera we should add manually the EXIF metadata
            //The PhotoCaptureSaver will save the image with metadata into the user's camera roll
            //and return the url to the asset
            [self startHUD];
            [self setPhotoSaver:[[[PhotoCaptureSaver alloc] initWithPickerInfo:info andDelegate:self] autorelease]];
            [self.photoSaver startSavingImage];
        }
        else
        {
            NSLog(@"Image picked from Photo Library with Location Services off/unavailable");
            [self startHUD];

            // We need to save the image into a file in the temp folder
            NSString *tempImageName = [[NSString generateUUID] stringByAppendingPathExtension:kDefaultImageExtension];
            NSString *tempImagePath = [FileUtils pathToTempFile:tempImageName];
            UIImage *originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
            NSData *imageData = UIImageJPEGRepresentation(originalImage, 1.0);
            NSFileManager *fileManager = [NSFileManager defaultManager];
            BOOL success = [fileManager createFileAtPath:tempImagePath contents:imageData attributes:nil];
            if (success)
            {
                AssetUploadItem *assetUploadHelper =  [[[AssetUploadItem alloc] initWithAssetURL:nil] autorelease];
                [assetUploadHelper setTempImagePath:tempImagePath];
                UploadInfo *uploadInfo = [[[UploadInfo alloc] init] autorelease];
                [uploadInfo setUploadFileURL:[[[NSURL alloc] initFileURLWithPath:tempImagePath] autorelease]];
                [uploadInfo setUploadType:UploadFormTypePhoto];
                [uploadInfo setUploadFileIsTemporary:YES];
                [self presentUploadFormWithItem:uploadInfo andHelper:assetUploadHelper];
            }
            else
            {
                displayErrorMessageWithTitle(NSLocalizedString(@"postprogressbar.error.uploadfailed.message", @"The upload failed, please try again"), NSLocalizedString(@"upload.photo.view.title", @"Upload Photo"));
            }
            [self stopHUD];
        }
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
    [self dismissModalViewControllerHelper:YES];
}

- (void)photoCaptureSaver:(PhotoCaptureSaver *)photoSaver didFinishSavingWithAssetURL:(NSURL *)assetURL
{
    AssetUploadItem *assetUploadHelper =  [[[AssetUploadItem alloc] initWithAssetURL:assetURL] autorelease];
    [assetUploadHelper createPreview:^(NSURL *previewURL)
    {
        UploadInfo *uploadInfo = [[[UploadInfo alloc] init] autorelease];
        [uploadInfo setUploadFileURL:previewURL];
        [uploadInfo setUploadType:UploadFormTypePhoto];
        [uploadInfo setUploadFileIsTemporary:YES];
        [self presentUploadFormWithItem:uploadInfo andHelper:assetUploadHelper];
        [self stopHUD];
    }];
}

//This will be called when location services are not enabled
- (void)photoCaptureSaver:(PhotoCaptureSaver *)photoSaver didFinishSavingWithURL:(NSURL *)imageURL
{
    AssetUploadItem *assetUploadHelper =  [[[AssetUploadItem alloc] initWithAssetURL:nil] autorelease];
    [assetUploadHelper setTempImagePath:[imageURL path]];
    UploadInfo *uploadInfo = [[[UploadInfo alloc] init] autorelease];
    [uploadInfo setUploadFileURL:imageURL];
    [uploadInfo setUploadType:UploadFormTypePhoto];
    [uploadInfo setUploadFileIsTemporary:YES];
    [self presentUploadFormWithItem:uploadInfo andHelper:assetUploadHelper];
    [self stopHUD];
}

- (void)photoCaptureSaver:(PhotoCaptureSaver *)photoSaver didFailWithError:(NSError *)error
{
    [self stopHUD];
    displayErrorMessageWithTitle(NSLocalizedString(@"browse.capturephoto.failed.message", @"Photo capture failed alert message"), NSLocalizedString(@"browse.capturephoto.failed.title", @"Photo capture failed alert title"));
}

- (void)didPresentAlertView:(UIAlertView *)alertView {
	[self.alertField becomeFirstResponder];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (IS_IPAD)
    {
		[self dismissPopover];
	}
    
    if (alertView.tag == kDownloadFolderAlert) 
    {
        [self continueDownloadFromAlert:alertView clickedButtonAtIndex:buttonIndex];
        return;
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
    
	NSString *userInput = [self.alertField text];
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
        
        RepositoryItem *item = [self.folderItems item];
        NSString *location   = [item identLink];
        NSLog(@"TO LOCATION: %@", location);
        
        self.postProgressBar = 
        [PostProgressBar createAndStartWithURL:[NSURL URLWithString:location]
                                   andPostBody:postBody
                                      delegate:self 
                                       message:NSLocalizedString(@"postprogressbar.create.folder", @"Creating Folder")
                                   accountUUID:self.selectedAccountUUID];
	}
}

- (void)post:(PostProgressBar *)bar completeWithData:(NSData *)data 
{
    [self.browseDataSource reloadDataSource];
}

- (void) post:(PostProgressBar *)bar failedWithData:(NSData *)data
{
    NSLog(@"WARNING - not implemented post:failedWithData:");
}

- (NSIndexPath *)indexPathForNodeWithGuid:(NSString *)itemGuid
{
    NSIndexPath *indexPath = nil;
    NSArray *items = nil;
    
    if ([self.searchDelegate.searchController isActive])
    {
        items = self.searchDelegate.repositoryItems;
    }
    else
    {
        items = self.browseDataSource.repositoryItems;
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

- (void)dataSourceFinishedLoadingWithSuccess:(BOOL)wasSuccessful
{
    [self.refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
    [self loadRightBarAnimated:YES];

    if (wasSuccessful)
    {
        [self setLastUpdated:[NSDate date]];
        [self.refreshHeaderView refreshLastUpdatedDate];

        if (IS_IPAD)
        {
            NSIndexPath *indexPath = [self indexPathForNodeWithGuid:[IpadSupport getCurrentDetailViewControllerObjectID]];
            if (indexPath && self.tableView)
            {
                [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            }
        }
        else
        {
            // For non-iPad devices, re-hide the search view
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
    
    if([self.navigationController isKindOfClass:[DocumentsNavigationController class]])
    {
        DocumentsNavigationController *navController = (DocumentsNavigationController *)[self navigationController];
        editing ? [navController hidePanels] : [navController showPanels];
    }

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

    UISearchBar *searchBar = [self.searchDelegate.searchController searchBar];
    [self.navigationItem setHidesBackButton:editing animated:YES];
    [UIView beginAnimations:@"searchbar" context:nil];
    [searchBar setAlpha:(editing ? 0.7f : 1)];
    [UIView commitAnimations];
    [searchBar setUserInteractionEnabled:!editing];
}

#pragma mark - SavedDocumentPickerDelegate

- (void)savedDocumentPicker:(SavedDocumentPickerController *)picker didPickDocuments:(NSArray *)documentURLs {
    NSLog(@"User selected the documents %@", documentURLs);
    
    //Hide popover on iPad
    [self dismissModalViewControllerHelper:NO];
    
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
    [self dismissModalViewControllerHelper:YES];
}

- (void)presentUploadFormWithItem:(UploadInfo *)uploadInfo andHelper:(id<UploadHelper>)helper;
{
    [[UploadsManager sharedManager] setExistingDocuments:[self existingDocuments] forUpLinkRelation:[[self.folderItems item] identLink]];
    UploadFormTableViewController *formController = [[UploadFormTableViewController alloc] init];
    [formController setExistingDocumentNameArray:[self existingDocuments]];
    [formController setUploadType:uploadInfo.uploadType];
    [formController setUpdateAction:@selector(uploadFormDidFinishWithItems:)];
    [formController setUpdateTarget:self];
    [formController setSelectedAccountUUID:self.selectedAccountUUID];
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
    // We want to present the UploadFormTableViewController modally in ipad
    // and in iphone we want to push it into the current navigation controller
    // IpadSupport helper method provides this logic
    [IpadSupport presentModalViewController:formController withNavigation:self.navigationController];
    [formController release];
}

- (void)presentUploadFormWithMultipleItems:(NSArray *)infos andUploadType:(UploadFormType)uploadType
{
    [[UploadsManager sharedManager] setExistingDocuments:[self existingDocuments] forUpLinkRelation:[[self.folderItems item] identLink]];
    UploadFormTableViewController *formController = [[UploadFormTableViewController alloc] init];
    [formController setExistingDocumentNameArray:[self existingDocuments]];
    [formController setUploadType:uploadType];
    [formController setUpdateAction:@selector(uploadFormDidFinishWithItems:)];
    [formController setUpdateTarget:self];
    [formController setSelectedAccountUUID:self.selectedAccountUUID];
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
    // We want to present the UploadFormTableViewController modally in ipad
    // and in iphone we want to push it into the current navigation controller
    // IpadSupport helper method provides this logic
    [IpadSupport presentModalViewController:formController withNavigation:self.navigationController];
    [formController release];
}

- (UploadInfo *)uploadInfoFromAsset:(ALAsset *)asset andExistingDocs:(NSArray *)existingDocs
{
    UploadInfo *uploadInfo = [[[UploadInfo alloc] init] autorelease];
    NSURL *previewURL = [AssetUploadItem createPreviewFromAsset:asset];
    [uploadInfo setUploadFileURL:previewURL];
    [uploadInfo setUploadFileIsTemporary:YES];
    
    if(isVideoExtension([previewURL pathExtension]))
    {
        [uploadInfo setUploadType:UploadFormTypeVideo];
    }
    else 
    {
        [uploadInfo setUploadType:UploadFormTypePhoto];
    }
    
    //Setting the name with the original date the photo/video was taken
    NSDate *assetDate = [asset valueForProperty:ALAssetPropertyDate];
    [uploadInfo setFilenameWithDate:assetDate andExistingDocuments:existingDocs];
    
    return uploadInfo;
}

- (UploadInfo *)uploadInfoFromURL:(NSURL *)fileURL
{
    UploadInfo *uploadInfo = [[[UploadInfo alloc] init] autorelease];
    [uploadInfo setUploadFileURL:fileURL];
    [uploadInfo setUploadType:UploadFormTypeDocument];
    [uploadInfo setFilename:[[fileURL lastPathComponent] stringByDeletingPathExtension]];

    return uploadInfo;
}

- (NSArray *)existingDocuments
{
    NSMutableArray *repositoryItems = [self.browseDataSource repositoryItems];
    NSMutableArray *existingDocuments = [NSMutableArray arrayWithCapacity:[repositoryItems count]];
    for (RepositoryItemCellWrapper *wrapper in repositoryItems)
    {
        [existingDocuments addObject:[wrapper itemTitle]];
    }
    return [NSArray arrayWithArray:existingDocuments];
}

#pragma mark - UploadFormTableViewController delegate method

- (void)uploadFormDidFinishWithItems:(NSArray *)items
{
    [self.browseDataSource addUploadsToRepositoryItems:items insertCells:YES];
}

#pragma mark - MBProgressHUD Helper Methods

- (void)startHUD
{
    _hudCount++;
	if (!self.HUD)
    {
        self.HUD = createAndShowProgressHUDForView(self.tableView);
    }
}

- (void)stopHUD
{
    _hudCount--;
    
	if (self.HUD && _hudCount <= 0)
    {
        stopProgressHUD(self.HUD);
		self.HUD = nil;
	}
}

#pragma mark - NotificationCenter methods

- (void)detailViewControllerChanged:(NSNotification *)notification 
{
    id sender = [notification object];
    if (sender && ![sender isEqual:self]) 
    {
        [self updateCurrentRowSelection];
    }
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    NSLog(@"applicationWillResignActive in RepositoryNodeViewController");
    [self.popover dismissPopoverAnimated:NO];
    self.popover = nil;
    
    [self cancelAllHTTPConnections];
}

- (void)uploadFinished:(NSNotification *)notification
{
    BOOL reload = [[notification.userInfo objectForKey:@"reload"] boolValue];
    
    if (reload)
    {
        NSString *itemGuid = [notification.userInfo objectForKey:@"itemGuid"];
        NSPredicate *guidPredicate = [NSPredicate predicateWithFormat:@"guid == %@", itemGuid];
        NSArray *itemsMatch = [[self.browseDataSource nodeChildren] filteredArrayUsingPredicate:guidPredicate];
        
        //An upload just finished in this node, we should reload the node to see the latest changes
        //See FileUrlHandler for an example where this notification gets posted
        if([itemsMatch count] > 0)
        {
            [self.browseDataSource reloadDataSource];
        }
    }
    else
    {
        UploadInfo *uploadInfo = [notification.userInfo objectForKey:@"uploadInfo"];
        NSIndexPath *indexPath = [self indexPathForNodeWithGuid:uploadInfo.cmisObjectId];
        if (indexPath != nil)
        {
            UploadProgressTableViewCell *cell = (UploadProgressTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            [cell setUploadInfo:uploadInfo];
            // This cell is no longer valid to represent the uploaded file, we need to reload the cell
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
            
            //Selecting the created document
            //Special case when creating a document we need to select the cell
            if (uploadInfo.uploadStatus == UploadInfoStatusUploaded 
                && [uploadInfo uploadType] == UploadFormTypeCreateDocument
                && [uploadInfo repositoryItem]
                && [self.folderItems.item.identLink isEqualToString:[uploadInfo upLinkRelation]])
            {
                [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
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
    if (![self isEditing])
    {
        [self.refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (![self isEditing])
    {
        [self.refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
    }
}

#pragma mark - EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view
{
    [self.browseDataSource reloadDataSource];
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view
{
	return [self.browseDataSource isReloading];
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
        [[DownloadManager sharedManager] queueRepositoryItems:selectedItems withAccountUUID:self.selectedAccountUUID andTenantId:self.tenantID];
        [self setEditing:NO];
    }
    else if ([name isEqual:kMultiSelectDelete])
    {
        [_itemsToDelete release];
        _itemsToDelete = [selectedItems copy];
        [self askDeleteConfirmationForMultipleItems];
    }
}

#pragma mark - Delete objects

- (void)askDeleteConfirmationForMultipleItems
{
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"delete.confirmation.multiple.message", @"Are you sure you want to delete x items"), [_itemsToDelete count]];
    UIActionSheet *sheet = [[[UIActionSheet alloc] initWithTitle:title
                                                        delegate:self
                                               cancelButtonTitle:NSLocalizedString(@"cancelButton", @"Cancel")
                                          destructiveButtonTitle:NSLocalizedString(@"delete.confirmation.button", @"Delete")
                                               otherButtonTitles:nil] autorelease];
    [sheet setTag:kDeleteActionSheetTag];
    [self setActionSheet:sheet];
    // Display on the tabBar in order to maintain device rotation
    [sheet showFromTabBar:[[(AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate] tabBarController] tabBar]];
}

- (void)didConfirmMultipleDelete
{
    self.deleteQueueProgressBar = [DeleteQueueProgressBar createWithItems:_itemsToDelete delegate:self andMessage:NSLocalizedString(@"Deleting Item", @"Deleting Item")];
    [self.deleteQueueProgressBar setSelectedUUID:self.selectedAccountUUID];
    [self.deleteQueueProgressBar setTenantID:self.tenantID];
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
    
    for (RepositoryItem *item in deletedItems)
    {
        if (IS_IPAD && [item.guid isEqualToString:[IpadSupport getCurrentDetailViewControllerObjectID]]) {
            
            [IpadSupport clearDetailController];
        }
    }

    [self.browseDataSource.repositoryItems removeObjectsAtIndexes:indexes];
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
