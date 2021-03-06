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
//  UploadFormTableViewController.m
//

#import "UploadFormTableViewController.h"
#import "Theme.h"
#import "IFPhotoCellController.h"
#import "IFTextCellController.h"
#import "IFTemporaryModel.h"
#import "IFChoiceCellController.h"
#import "IFButtonCellController.h"
#import "TaggingHttpRequest.h"
#import "AlfrescoAppDelegate.h"
#import "VideoCellController.h"
#import "AudioCellController.h"
#import "DocumentIconNameCellController.h"
#import "AppProperties.h"
#import "IpadSupport.h"
#import "UploadsManager.h"
#import "TableCellViewController.h"
#import "AssetUploadItem.h"
#import "IFLabelValuePair.h"

NSString * const kPhotoQualityKey = @"photoQuality";

@interface UploadFormTableViewController  (private)
- (BOOL)saveSingleUpload;
- (BOOL)saveMultipleUpload;
- (IFChoiceCellController *)qualityChoiceCell;
- (NSString *)uploadTypeTitleLabel: (UploadFormType) type;
- (NSString *)uploadTypeCellLabel: (UploadFormType) type;
- (NSString *)uploadTypeProgressBarTitle: (UploadFormType) type;
- (BOOL)validateName:(NSString *)name;
- (void)nameValueChanged:(id)sender;
- (NSString *)multipleItemsDetailLabel;
- (BOOL)containsPhoto;
- (BOOL)isMultiUpload;
@end


@implementation UploadFormTableViewController
@synthesize createTagTextField;
@synthesize availableTagsArray;
@synthesize updateAction;
@synthesize updateTarget;
@synthesize existingDocumentNameArray;
@synthesize presentedAsModal;
@synthesize uploadHelper;
@synthesize uploadInfo;
@synthesize multiUploadItems;
@synthesize uploadType;
@synthesize selectedAccountUUID;
@synthesize tenantID;
@synthesize textCellController;
@synthesize tagsCellController;
@synthesize HUD;
@synthesize asyncRequests;
@synthesize tagsCellIndexPath;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [createTagTextField release];
    [availableTagsArray release];
    [existingDocumentNameArray release];
    [uploadHelper release];
    [uploadInfo release];
    [multiUploadItems release];
    [selectedAccountUUID release];
    [tenantID release];
    [textCellController release];
    [tagsCellController release];
    [HUD release];
    [asyncRequests release];
    [tagsCellIndexPath release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (id) init {
    self = [super init];
    
    if (self)
    {
        uploadType = UploadFormTypePhoto;
        shouldSetResponder = YES;
        asyncRequests = [[NSMutableArray alloc] init];
    }
    
    return self;
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{   
    [super viewDidLoad];
    // Theme
    [Theme setThemeForUINavigationBar:self.navigationController.navigationBar];
    
    // Title
    [self.navigationItem setTitle:NSLocalizedString([self uploadTypeTitleLabel:self.uploadType], @"Title for the form based view controller for photo uploads")];
    
    // Buttons
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed)];
    [self.navigationItem setLeftBarButtonItem:cancelButton];
    [cancelButton release];
    
    NSString *saveButtonTitle = nil;
    
    if ([self uploadType] != UploadFormTypeCreateDocument)
    {
        saveButtonTitle = NSLocalizedString(@"Upload", @"Upload");
    }
    else 
    {
        saveButtonTitle = NSLocalizedString(@"Create", @"Create");
    }
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:saveButtonTitle
                                                                   style:UIBarButtonItemStyleDone
                                                                  target:self
                                                                  action:@selector(saveButtonPressed)];;
    styleButtonAsDefaultAction(saveButton);
    [self.navigationItem setRightBarButtonItem:saveButton];
    [saveButton release];
    
    //Enables/Disables the save button if there's a valid/invalid name
    [self nameValueChanged:nil];
    
    [self setAsyncRequests:[NSMutableArray array]];
}

- (void)setFirstResponder {
    [textCellController becomeFirstResponder];
    shouldSetResponder = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Set first responder here if the table cell renderer hasn't done it already
    if (shouldSetResponder)
    {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0 && IS_IPAD)
        {
            [self performSelector:@selector(setFirstResponder) withObject:nil afterDelay:0.2];
        }else{
            [self setFirstResponder];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // A pattern for cancelling outstanding async requests as the view disappears
    for (BaseHTTPRequest *httpRequest in [self asyncRequests])
    {
        if (httpRequest != nil)
        {
            [httpRequest cancel];
            [[self asyncRequests] removeObject:httpRequest];
        }
    }
}

- (void)notifyCellControllers
{
    // Tell cell controllers that this modal dialog is about to be dismissed.
    // This is used, for example, to stop any video currently playing
    for (NSArray *tableGroup in tableGroups)
    {
        for (NSObject *cellController in tableGroup)
        {
            // We don't check with conformsToProtocol here, as the controllerWillBeDismissed is @optional
            if ([cellController respondsToSelector:@selector(controllerWillBeDismissed:)])
            {
                [cellController performSelector:@selector(controllerWillBeDismissed:) withObject:self];
            }
        }
    }
}

- (void)cancelButtonPressed
{
    AlfrescoLogDebug(@"UploadFormTableViewController: Cancelled");
    
    if([self.uploadInfo uploadStatus] == UploadInfoStatusFailed)
    {
        [[UploadsManager sharedManager] clearUpload:[self.uploadInfo uuid]];
    }
    [self dismissViewControllerWithBlock:NULL];
}

- (void)saveButtonPressed
{
    AlfrescoLogDebug(@"UploadFormTableViewController: Upload");
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
    if ([self isMultiUpload])
    {
        [self saveMultipleUpload];
    }
    else 
    {
        [self saveSingleUpload];
    }
}

- (BOOL)saveSingleUpload
{
    __block NSString *name = [self.model objectForKey:@"name"];
    
    if(![self validateName:name])
    {
        displayErrorMessageWithTitle(NSLocalizedString(@"uploadview.name.invalid.message", @"Invalid characters in name"), NSLocalizedString(@"uploadview.name.invalid.title", @""));
        
        return NO;
    }
    
    //The audio is the only one that the user generates from this viewController
    if(self.uploadType == UploadFormTypeAudio)
    {
        NSURL *audioUrl = [self.model objectForKey:@"previewURL"];
        [self.uploadInfo setUploadFileURL:audioUrl];
    }
    
    //For the rtf creation we don't have a file to upload so we need to let that case slip
    //The check for the uploadFileURL is mostly for the Audio recording since the user might hit save 
    //before actually recording any audio
    if ((!self.uploadInfo.uploadFileURL && [self uploadType] != UploadFormTypeCreateDocument) || (name == nil || [name length] == 0))
    {
        displayErrorMessageWithTitle(NSLocalizedString(@"uploadview.required.fields.missing.dialog.message", @"Please fill in all required fields"), NSLocalizedString(@"uploadview.required.fields.missing.dialog.title", @""));
        [self.navigationItem.rightBarButtonItem setEnabled:[self validateName:name]];
        return NO;
    }
    
    [self startHUD];
    
    // Need to determine the final filename before calling the update action
    // We remove the extension if the user typed it
    if ([[name pathExtension] isEqualToString:self.uploadInfo.extension])
    {
        name = [name stringByDeletingPathExtension];
    }
    [self.uploadInfo setFilename:name];
    [self.uploadInfo setTenantID:self.tenantID];
    
    void (^uploadBlock)(void) = ^
    {
        NSString *newName = [FileUtils nextFilename:[self.uploadInfo completeFileName] inNodeWithDocumentNames:self.existingDocumentNameArray];
        if(![newName isEqualToCaseInsensitiveString:[self.uploadInfo completeFileName]])
        {
            name = [newName stringByDeletingPathExtension];
            [self.uploadInfo setFilename:name];
        }
        
        AlfrescoLogDebug(@"New Filename: %@", [self.uploadInfo completeFileName]);
        
        
        NSString *tags = [model objectForKey:@"tags"];
        if ((tags != nil) && ![tags isEqualToString:@""])
        {
            NSArray *tagsArray = [tags componentsSeparatedByString:@","];
            [uploadInfo setTags:tagsArray];
        }
        
        // We call the helper to perform any last action before uploading, like resizing an image with a quality parameter
        //[self.uploadHelper preUpload];
        [[UploadsManager sharedManager] queueUpload:self.uploadInfo];
        [self callUpdateActionOnTarget];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self stopHUD];
        });
    };
    
    if([self uploadType] != UploadFormTypeCreateDocument)
    {
        //Async experience when uploading any document
        [self dismissViewControllerWithBlock:^{
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), uploadBlock);
        }];
    }
    else 
    {
        
        //Sync experience when creating a document
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadFinished:) name:kNotificationUploadFinished object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadFailed:) name:kNotificationUploadFailed object:nil];
        if([self.uploadInfo uploadStatus] != UploadInfoStatusFailed)
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), uploadBlock);
        }
        else 
        {
            [[UploadsManager sharedManager] retryUpload:[self.uploadInfo uuid]];
        }
        
    }
    
    return YES;
}

- (BOOL)saveMultipleUpload
{
    [self startHUD];

    // Need to determine the final filenames before calling the update action
    NSMutableArray *updatedDocumentsNameArray = [[self.existingDocumentNameArray mutableCopy] autorelease];
    for (UploadInfo *upload in self.multiUploadItems)
    {
        NSString *newName = [FileUtils nextFilename:[upload completeFileName] inNodeWithDocumentNames:updatedDocumentsNameArray];
        [updatedDocumentsNameArray addObject:newName];
        
        if (![newName isEqualToCaseInsensitiveString:[upload completeFileName]])
        {
            NSString *name = [newName stringByDeletingPathExtension];
            [upload setFilename:name];
        }
    }

    [self callUpdateActionOnTarget];

    [self dismissViewControllerWithBlock:^{
        //This code could resize a batch of large images and if it runs in the main thread
        //it can potentially block the user interface for quite some time
        //Instead we show a HUD and allow the user to use other parts of the app while 
        //the images are being processed
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // The tags will apply to all uploads
            NSString *tags = [model objectForKey:@"tags"];
            if ((tags != nil) && ![tags isEqualToString:@""])
            {
                NSArray *tagsArray = [tags componentsSeparatedByString:@","];
                for (UploadInfo *upload in self.multiUploadItems)
                {
                    [upload setTags:tagsArray];
                    [upload setTenantID:self.tenantID];
                }
            }

            for (UploadInfo *upload in self.multiUploadItems)
            {
                if (upload.uploadType == UploadFormTypePhoto)
                {
                    AssetUploadItem *resizeHelper = [[[AssetUploadItem alloc] init] autorelease];
                    [resizeHelper setTempImagePath:[upload.uploadFileURL path]];
                    [resizeHelper preUpload];
                }
            }
            
            UploadInfo *anyUpload = [self.multiUploadItems lastObject];
            // All uploads must be selected to be upload in the SAME repository node (upLinkRelations)
            [[UploadsManager sharedManager] setExistingDocuments:self.existingDocumentNameArray forUpLinkRelation:anyUpload.upLinkRelation];
            [[UploadsManager sharedManager] queueUploadArray:self.multiUploadItems];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self stopHUD];
            });
        });
    }];
    
    return YES;
}

- (BOOL)validateName:(NSString *)name
{
    name = [name trimWhiteSpace];
    NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"?/\\:*?\"<>|#"];
    
    return [self isMultiUpload] || (![name isEqualToString:[NSString string]] && [name rangeOfCharacterFromSet:set].location == NSNotFound);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - FIX to enable the name field to become the first responder after a reload

- (void)updateAndReloadSettingFirstResponder:(BOOL)setResponder
{
    [super updateAndReload];
    shouldSetResponder = setResponder;
}

#pragma mark - Generic Table View Methods

- (void)constructTableGroups
{
    if (![self.model isKindOfClass:[IFTemporaryModel class]]) {
        IFTemporaryModel *tempModel = [[IFTemporaryModel alloc] init];
        [self setModel:tempModel];
        [tempModel release];
	}
    
    if (availableTagsArray == nil) {
        [self setAvailableTagsArray:[NSMutableArray array]];
    }
    
    // Arrays for section headers, bodies and footers
	NSMutableArray *headers = [NSMutableArray array];
	NSMutableArray *groups =  [NSMutableArray array];
	NSMutableArray *footers = [NSMutableArray array];
    NSMutableArray *uploadFormCellGroup = [NSMutableArray array];

    if(self.uploadType != UploadFormTypeLibrary && self.uploadType != UploadFormTypeMultipleDocuments)
    {
        /**
         * Name field
         */
        self.textCellController = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"uploadview.tablecell.name.label", @"Name")
                                                                andPlaceholder:NSLocalizedString(@"uploadview.tablecell.name.placeholder", @"Enter a name")
                                                                         atKey:@"name" inModel:self.model] autorelease];
        [textCellController setEditChangedAction:@selector(nameValueChanged:)];
        [textCellController setUpdateTarget:self];
        [uploadFormCellGroup addObject:textCellController];
    }

    /**
     * Upload type-specific field
     */
    id cellController = nil;
    switch (self.uploadType) {
        case UploadFormTypeDocument:
        {
            cellController = [[DocumentIconNameCellController alloc] initWithLabel:NSLocalizedString([self uploadTypeCellLabel:self.uploadType], @"Document")  atKey:@"previewURL" inModel:self.model];
            [uploadFormCellGroup addObject:cellController];
            break;
        }
        case UploadFormTypeVideo:
        {
            [IpadSupport clearDetailController];
            cellController = [[VideoCellController alloc] initWithLabel:NSLocalizedString([self uploadTypeCellLabel:self.uploadType], @"Video") atKey:@"previewURL" inModel:self.model];
            [uploadFormCellGroup addObject:cellController];
            break;
        }
        case UploadFormTypeAudio:
        {
            cellController = [[AudioCellController alloc] initWithLabel:NSLocalizedString([self uploadTypeCellLabel:self.uploadType], @"Audio") atKey:@"previewURL" inModel:self.model];
            [uploadFormCellGroup addObject:cellController];
            break;
        }
        case UploadFormTypeLibrary:
        case UploadFormTypeMultipleDocuments:
        {
            // We only show the count of photos, videos and documents when it's a multi document upload
            TableCellViewController *defaultCell = [[TableCellViewController alloc] initWithAction:nil onTarget:nil];
            [defaultCell setCellStyle:UITableViewCellStyleValue1];
            [defaultCell.textLabel setText:NSLocalizedString([self uploadTypeCellLabel:self.uploadType], @"")];
            [defaultCell.textLabel setFont:[UIFont boldSystemFontOfSize:17.0f]];
            [defaultCell.detailTextLabel setText:[self multipleItemsDetailLabel]];
            [defaultCell.detailTextLabel setFont:[UIFont systemFontOfSize:17.0f]];
            
            cellController = defaultCell;
            [uploadFormCellGroup addObject:cellController];
            
//            if([self containsPhoto])
//            {
//                [uploadFormCellGroup addObject:[self qualityChoiceCell]];
//            }
            break;
        }
        case UploadFormTypePhoto:
        {
            //In the photo upload, besides showing the photo preview, we give the user the option to choose the image quality, decreasing
            //the photo size for slower connections
            ALAsset *asset = [AssetUploadItem assetFromURL:self.uploadInfo.uploadFileURL];
            
            if (asset) {
                UIImage *image = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullResolutionImage]];
                [self.model setObject:image forKey:@"media"];
                [asset release];
            }
            cellController = [[IFPhotoCellController alloc] initWithLabel:NSLocalizedString([self uploadTypeCellLabel:self.uploadType], @"Photo")  atKey:@"media" inModel:self.model];
            [cellController setSelectionStyle:UITableViewCellSelectionStyleNone];
            [cellController setAccessoryType:UITableViewCellAccessoryNone];
            
            [uploadFormCellGroup addObject:cellController];
//            [uploadFormCellGroup addObject:[self qualityChoiceCell]];
            /*UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:self.uploadInfo.uploadFileURL] ];
            [self.model setObject:image forKey:@"media"];
            cellController = [[IFPhotoCellController alloc] initWithLabel:NSLocalizedString([self uploadTypeCellLabel:self.uploadType], @"Photo")  atKey:@"media" inModel:self.model];
            [cellController setSelectionStyle:UITableViewCellSelectionStyleNone];
            [cellController setAccessoryType:UITableViewCellAccessoryNone];

            [uploadFormCellGroup addObject:cellController];
            [uploadFormCellGroup addObject:[self qualityChoiceCell]];*/
            break;
        }
        default:
        {
            
        }
    }

    [cellController release];
    
    [headers addObject:@""];
	[groups addObject:uploadFormCellGroup];
	[footers addObject:@""];
    
    /**
     * Tagging fields
     */
    /*NSMutableArray *tagsCellGroup = [NSMutableArray array];
    
    IFChoiceCellController *tagsController = [[[IFChoiceCellController alloc ] initWithLabel:NSLocalizedString(@"uploadview.tablecell.tags.label", @"Tags")
                                                                                     andChoices:availableTagsArray atKey:@"tags" inModel:self.model] autorelease];
    [tagsController setSeparator:@","];
    [tagsController setSelectionOptional:YES];
    [tagsController setRefreshAction:@selector(tagsCellAction:)];
    [tagsController setRefreshTarget:self];
    [tagsController setSelectionStyle:UITableViewCellSelectionStyleBlue];
    [self setTagsCellController:tagsController];
    [tagsCellGroup addObject:tagsController];
    */
    /*IFButtonCellController *addNewTagCellController = [[IFButtonCellController alloc] initWithLabel:NSLocalizedString(@"uploadview.tablecell.addnewtag.label", @"Add New Tag")
                                                                                         withAction:@selector(addNewTagButtonPressed) 
                                                                                           onTarget:self];
    [tagsCellGroup addObject:addNewTagCellController];
    [addNewTagCellController release];
    */
    //[headers addObject:@""];
	//[groups addObject:tagsCellGroup];
	//[footers addObject:@""];
    //[self setTagsCellIndexPath:[NSIndexPath indexPathForRow:0 inSection:[groups indexOfObject:tagsCellGroup]]];
    
    
    tableGroups = [groups retain];
	tableHeaders = [headers retain];
	tableFooters = [footers retain];
    
	[self assignFirstResponderHostToCellControllers];
}

- (IFChoiceCellController *)qualityChoiceCell
{
    NSArray *imageUploadSizing = [AppProperties propertyForKey:kImageUploadSizingOptionValues];
    NSString *userSelectedSizing = [[FDKeychainUserDefaults standardUserDefaults] objectForKey:@"ImageUploadSizingOption"];
    if(!userSelectedSizing || ![imageUploadSizing containsObject:userSelectedSizing])
    {
        userSelectedSizing = [AppProperties propertyForKey:kImageUploadSizingOptionDefault];
    }
    [self.model setObject:userSelectedSizing forKey:kPhotoQualityKey];
    
    NSMutableArray *valuePairChoices = [NSMutableArray arrayWithCapacity:[imageUploadSizing count]];
    for(NSString *sizeValue in imageUploadSizing)
    {
        IFLabelValuePair *valuePair = [[IFLabelValuePair alloc] initWithLabel:NSLocalizedString(sizeValue, @"Localized sizing option") andValue:sizeValue];
        [valuePairChoices addObject:valuePair];
        [valuePair release];
    }
    
    IFChoiceCellController *qualityChoiceCell = [[IFChoiceCellController alloc] initWithLabel:NSLocalizedString(@"uploadview.tablecell.photoQuality.label", @"Photo Quality") andChoices:valuePairChoices atKey:kPhotoQualityKey inModel:self.model];
    [qualityChoiceCell setUpdateTarget:self];
    [qualityChoiceCell setUpdateAction:@selector(qualitySettingsChanged:)];
    return [qualityChoiceCell autorelease];
}

- (void)qualitySettingsChanged:(UITableView *)tableView
{
    [[FDKeychainUserDefaults standardUserDefaults] setObject:[self.model objectForKey:kPhotoQualityKey] forKey:@"ImageUploadSizingOption"];
    [[FDKeychainUserDefaults standardUserDefaults] synchronize];
}

- (void)nameValueChanged:(id)sender
{
    NSString *name = [self.model objectForKey:@"name"];
    [self.navigationItem.rightBarButtonItem setEnabled:[self validateName:name]];
}

- (void)addNewTagButtonPressed
{   
    if(!hasFetchedTags)
    {
        addTagWasSelected = YES;
        [self tagsCellAction:nil];
        return;
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"uploadview.tablecell.addnewtag.label", @"Add New Tag")
                                                    message:@""
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"closeButtonText", @"Cancel Button Text")
                                          otherButtonTitles:NSLocalizedString(@"Add", @"Add"), nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [self setCreateTagTextField:[alert textFieldAtIndex:0]];//[[[UITextField alloc] initWithFrame:CGRectMake(12.0, 45.0, 260.0, 25.0)] autorelease]];
    //[createTagTextField setBackgroundColor:[UIColor whiteColor]];
    //[createTagTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    
    //[alert addSubview:createTagTextField];
    [alert show];
    [alert release];
}

- (void)callUpdateActionOnTarget
{
    if (updateTarget && [updateTarget respondsToSelector:updateAction])
    {
        NSArray *uploads = nil;
        if(self.multiUploadItems)
        {
            uploads = self.multiUploadItems;
        }
        else 
        {
            uploads = [NSArray arrayWithObject:self.uploadInfo];
        }
        [updateTarget performSelector:updateAction withObject:uploads];
    }
}

- (void)dismissViewControllerWithBlock:(void(^)(void))block
{
    [self notifyCellControllers];
    if (self.presentedAsModal)
    {
        [self dismissViewControllerAnimated:YES completion:block];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
        if (block)
        {
            block();
        }
    }
}

- (void)addAndSelectNewTag:(NSString *)newTag
{
    if ( ! [availableTagsArray containsObject:newTag] ) {
        [availableTagsArray addObject:newTag];
    }
    NSString *selectedTags = (NSString *)[self.model objectForKey:@"tags"];
    if ( ! [[selectedTags componentsSeparatedByString:@","] containsObject:newTag] ) 
    {
        if ((selectedTags == nil) || ([selectedTags length] == 0)) 
        {
            selectedTags = [NSString stringWithString:newTag];
        } else {
            selectedTags = [NSString stringWithFormat:@"%@,%@", selectedTags, newTag];
        }
        
        [model setObject:selectedTags forKey:@"tags"];
        [self updateAndReloadSettingFirstResponder:NO];
    }
}

- (void)tagsCellAction:(id)sender
{
    if(!hasFetchedTags)
    {
        hasFetchedTags = YES;
        
        // Retrieve Tags
        TaggingHttpRequest *request = [TaggingHttpRequest httpRequestListAllTagsWithAccountUUID:selectedAccountUUID tenantID:self.tenantID];
        [request setPasswordPromptPresenter:self];
        [request setSuppressAllErrors:YES];
        [[self asyncRequests] addObject:request];
        [request setDelegate:self];
        [request startAsynchronous];
        [self startHUD];
    }
}

#pragma mark - UIAlertViewDelegate Methods

- (void)didPresentAlertView:(UIAlertView *)alertView 
{
    if (createTagTextField) {
        [createTagTextField becomeFirstResponder];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex > 0) // Ok button clicked
    { 
        // Check that user actually provided text
        NSString *newTag = createTagTextField.text;
        if ((newTag == nil) || ([[newTag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length]==0)) 
        { // No text found, alert
            displayErrorMessageWithTitle(NSLocalizedString(@"uploadview.error.invalidtag.message", @"Tags must contain text"), NSLocalizedString(@"uploadview.error.invalidtag.title", @"Invalid Tag"));
            AlfrescoLogDebug(@"Empty Tag ERROR");
        }
        else 
        {
            newTag = [[newTag lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if ([availableTagsArray containsObject:newTag])
            {
                [self addAndSelectNewTag:newTag];
            }
            else
            {
                AlfrescoLogDebug(@"Create Tag: %@", newTag);
                // Tag does not exist, tag must be added
                TaggingHttpRequest *request = [TaggingHttpRequest httpRequestCreateNewTag:newTag accountUUID:selectedAccountUUID tenantID:self.tenantID];
                [request setDelegate:self];

                [self showHUDInView:self.view forAsyncRequest:request];
            }
        }
    }
    
    [createTagTextField resignFirstResponder];
    [self setCreateTagTextField:nil];
}

#pragma mark - ASIHTTPRequestDelegate Methods

-(void)requestFinished:(TaggingHttpRequest *)request
{
    // Remove the request if it's been stored
    [[self asyncRequests] removeObject:request];
    
    if ([request.apiMethod isEqualToString:kListAllTags] ) 
    {
        NSArray *parsedTags = [TaggingHttpRequest tagsArrayWithResponseString:[request responseString] accountUUID:selectedAccountUUID];

        if (availableTagsArray == nil) {
            [self setAvailableTagsArray:[NSMutableArray array]];
        }
        [availableTagsArray removeAllObjects];
        [availableTagsArray addObjectsFromArray:parsedTags];
        [self.tagsCellController setChoices:self.availableTagsArray];
        
        [self.tagsCellController setSelectionStyle:UITableViewCellSelectionStyleBlue];
        [self updateAndRefresh];
        
        if(!addTagWasSelected)
        {
            //We need to emulate cell selection from the user after the tags are loaded
            [self.tagsCellController tableView:self.tableView didSelectRowAtIndexPath:self.tagsCellIndexPath];
        }
        else
        {
            //We should present the add new tag dialog
            [self addNewTagButtonPressed];
            addTagWasSelected = NO;
        }
    }
    else if ([request.apiMethod isEqualToString:kCreateTag])
    {
        NSString *newTag = [request.userDictionary objectForKey:@"tag"];
        [self addAndSelectNewTag:newTag];
    }
    
    [self stopHUD];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
        [textCellController becomeFirstResponder];
    });
}

- (void)requestFailed:(TaggingHttpRequest *)request
{
    // Remove the request if it's been stored
    [[self asyncRequests] removeObject:request];

    [self setAvailableTagsArray:[NSMutableArray array]];
    AlfrescoLogDebug(@"Failed to retrieve tags: %@", request.apiMethod);
    
    if ([request.apiMethod isEqualToString:kCreateTag])
    {
        NSString *newTag = [request.userDictionary objectForKey:@"tag"];
        displayErrorMessageWithTitle([NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"uploadview.error.requestfailed.message", @"Failed to create tag [tagname]"), newTag], NSLocalizedString(@"uploadview.error.title", @"Error"));
        [request clearDelegatesAndCancel];
    }

    [self stopHUD];
}

#pragma mark - MBProgressHUD Helper Methods

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    // Remove HUD from screen when the HUD was hidden
    [self stopHUD];
}

- (void)showHUDInView:(UIView *)view forAsyncRequest:(id)request
{
	if (!self.HUD)
    {
        self.HUD = createProgressHUDForView(view);
        [self.HUD setDelegate:self];
        [self.HUD showWhileExecuting:@selector(startAsynchronous) onTarget:request withObject:nil animated:YES];
	}
}

- (void)stopHUD
{
	if (self.HUD)
    {
        stopProgressHUD(self.HUD);
		self.HUD = nil;
	}
}

- (void)startHUD
{
	if (!self.HUD)
    {
        self.HUD = createProgressHUDForView(self.view);
        [self.HUD setGraceTime:0];
        [self.HUD show:YES];
	}
}

#pragma mark - Label helpers

- (NSString *)uploadTypeTitleLabel:(UploadFormType)type
{
    NSString *label = nil;
    switch (type)
    {
        case UploadFormTypeDocument:
            label = @"upload.document.view.title";
            break;

        case UploadFormTypeCreateDocument:
            label = @"upload.create-document.view.title";
            break;

        case UploadFormTypeVideo:
            label = @"upload.video.view.title";
            break;

        case UploadFormTypeAudio:
            label = @"upload.audio.view.title";
            break;

        case UploadFormTypeLibrary:
            label = [NSString stringWithFormat:NSLocalizedString(@"upload.library.title", ""), [self.multiUploadItems count]];
            break;

        case UploadFormTypeMultipleDocuments:
            label = [NSString stringWithFormat:NSLocalizedString(@"upload.multiple.title", ""), [self.multiUploadItems count]];
            break;
        
        default:
            label = @"upload.photo.view.title";
            break;
    }
    return label;
}

- (NSString *)uploadTypeCellLabel: (UploadFormType) type 
{
    NSString *label = nil;
    switch (type)
    {
        case UploadFormTypeDocument:
            label = @"uploadview.tablecell.document.label";
            break;

        case UploadFormTypeVideo:
            label = @"uploadview.tablecell.video.label";
            break;

        case UploadFormTypeAudio:
            label = @"uploadview.tablecell.audio.label";
            break;

        case UploadFormTypeLibrary:
            label = @"uploadview.tablecell.library.label";
            break;

        case UploadFormTypeMultipleDocuments:
            label = @"uploadview.tablecell.multiple.label";
            break;

        default:
            label = @"uploadview.tablecell.photo.label";
            break;
    }
    return label;
}

- (NSString *)uploadTypeProgressBarTitle:(UploadFormType)type
{
    NSString *label = nil;
    switch (type)
    {
        case UploadFormTypeDocument:
            label = @"postprogressbar.upload.document";
            break;

        case UploadFormTypeVideo:
            label = @"postprogressbar.upload.video";
            break;

        case UploadFormTypeAudio:
            label = @"postprogressbar.upload.audio";
            break;
        
        default:
            label = @"postprogressbar.upload.picture";
            break;
    }
    return label;
}

- (NSString *)multipleItemsDetailLabel
{
    NSMutableDictionary *counts = [NSMutableDictionary dictionaryWithCapacity:3];
    for(UploadInfo *anUploadInfo in self.multiUploadItems)
    {
        NSInteger count = [[counts objectForKey:[NSNumber numberWithInt:anUploadInfo.uploadType]] intValue];
        count++;
        [counts setObject:[NSNumber numberWithInt:count] forKey:[NSNumber numberWithInt:anUploadInfo.uploadType]];
    }
    
    BOOL first = YES;
    NSString *label = [NSString string];
    for(NSNumber *type in [counts allKeys])
    {
        NSInteger typeCount = [[counts objectForKey:type] intValue];
        NSString *comma = nil;
        if(!first)
        {
            comma = @", "; 
        }
        else 
        {
            comma = [NSString string];
            first = NO;
        }
        
        
        BOOL plural = typeCount > 1;
        NSString *mediaType = [UploadInfo typeDescription:[type intValue] plural:plural];
        label = [NSString stringWithFormat:@"%@%@%d %@", label, comma, typeCount, mediaType];
    }
    return label;
}

- (BOOL)containsPhoto
{
    for(UploadInfo *anUploadInfo in self.multiUploadItems)
    {
        if(anUploadInfo.uploadType == UploadFormTypePhoto)
        {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isMultiUpload
{
    return self.uploadType == UploadFormTypeMultipleDocuments || self.uploadType == UploadFormTypeLibrary;
}

#pragma mark - Upload Notification Center Methods

- (void)uploadFinished:(NSNotification *)notification
{
    UploadInfo *notifUpload = [[notification userInfo] objectForKey:@"uploadInfo"];
    if([self uploadType] == UploadFormTypeCreateDocument && [notifUpload uuid] == [self.uploadInfo uuid])
    {
        [self stopHUD];
        if (self.presentedAsModal)
        {
            //We are dismissing a modal and the new document will be pushed in the Detail view
            //There is no problem if we animate the dismiss
            [self dismissModalViewControllerAnimated:YES];
        }
        else
        {
            //We are going to push the new document in the same navigation stack
            //no animation to dismiss this controller should occur
            [self.navigationController popViewControllerAnimated:NO];
        }
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

- (void)uploadFailed:(NSNotification *)notification
{
    UploadInfo *notifUpload = [[notification userInfo] objectForKey:@"uploadInfo"];
    if([self uploadType] == UploadFormTypeCreateDocument && [notifUpload uuid] == [self.uploadInfo uuid])
    {
        [self stopHUD];
        //Enabling the create button if it fails to upload
        NSString *name = [self.model objectForKey:@"name"];
        [self.navigationItem.rightBarButtonItem setEnabled:[self validateName:name]];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];

        displayErrorMessageWithTitle(NSLocalizedString(@"create-document.upload-error.message", @"Error creating the document message"), NSLocalizedString(@"create-document.upload-error.title", @"Error creating the document title"));
    }
}
@end
