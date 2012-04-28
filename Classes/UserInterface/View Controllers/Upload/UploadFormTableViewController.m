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
#import "NSData+Base64.h"
#import "IFMultilineCellController.h"
#import "IFChoiceCellController.h"
#import "IFButtonCellController.h"
#import "TaggingHttpRequest.h"
#import "MBProgressHUD.h"
#import "AlfrescoAppDelegate.h"
#import "VideoCellController.h"
#import "AudioCellController.h"
#import "DocumentIconNameCellController.h"
#import "AppProperties.h"
#import "GTMNSString+XML.h"
#import "NSString+Utils.h"
#import "IpadSupport.h"
#import "UploadInfo.h"
#import "UploadsManager.h"

NSString * const kPhotoQualityKey = @"photoQuality";

@interface UploadFormTableViewController  (private)

- (NSString *) uploadTypeTitleLabel: (UploadFormType) type;
- (NSString *) uploadTypeCellLabel: (UploadFormType) type;
- (NSString *) uploadTypeProgressBarTitle: (UploadFormType) type;
- (BOOL)validateName:(NSString *)name;
- (void)nameValueChanged:(id)sender;
- (BOOL)array:(NSArray *)array containsInsensitiveString:(NSString *)string;
@end


@implementation UploadFormTableViewController
@synthesize createTagTextField;
@synthesize availableTagsArray;
@synthesize updateAction;
@synthesize updateTarget;
@synthesize existingDocumentNameArray;
@synthesize delegate;
@synthesize presentedAsModal;
@synthesize uploadHelper;
@synthesize uploadInfo;
@synthesize selectedAccountUUID;
@synthesize tenantID;
@synthesize textCellController;
@synthesize asyncRequests;

- (void)dealloc
{
    [createTagTextField release];
    [availableTagsArray release];
    [existingDocumentNameArray release];
    [selectedAccountUUID release];
    [tenantID release];
    [textCellController release];
    [asyncRequests release];
    
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
    
    if(self) {
        shouldSetResponder = YES;
    }
    
    return self;
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{   
    [super viewDidLoad];
    // Theme
    [Theme setThemeForUINavigationBar:self.navigationController.navigationBar];
    
    // Title
    [self.navigationItem setTitle:NSLocalizedString([self uploadTypeTitleLabel:self.uploadInfo.uploadType], @"Title for the form based view controller for photo uploads")];
    
    // Buttons
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed)];
    [self.navigationItem setLeftBarButtonItem:cancelButton];
    [cancelButton release];
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Upload", @"Upload") 
                                                                   style:UIBarButtonItemStyleDone 
                                                                  target:self 
                                                                  action:@selector(saveButtonPressed)];
    styleButtonAsDefaultAction(saveButton);
    [self.navigationItem setRightBarButtonItem:saveButton];
    [saveButton release];
    
    //Enables/Disables the save button if there's a valid/invalid name
    [self nameValueChanged:nil];
    
    [self setAsyncRequests:[NSMutableArray array]];
}

- (void)viewWillAppear:(BOOL)animated
{
    // Retrieve Tags
    HUD = [[MBProgressHUD alloc] initWithWindow:[(AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate] window]];
    TaggingHttpRequest *request = [TaggingHttpRequest httpRequestListAllTagsWithAccountUUID:selectedAccountUUID tenantID:self.tenantID];
    [[self asyncRequests] addObject:request];
    [request setDelegate:self];
    [HUD showWhileExecuting:@selector(startAsynchronous) onTarget:request withObject:nil animated:YES];
    
    popViewControllerOnHudHide = NO;
    
    [super viewWillAppear:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
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

- (void) notifyCellControllers
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
    NSLog(@"CANCEL BUTTON PRESSED!");

    [self notifyCellControllers];
    if(self.delegate  && self.presentedAsModal) {
        [self.delegate dismissUploadViewController:self didUploadFile:NO];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)saveButtonPressed
{
    NSLog(@"SAVE BUTTON PRESSED!");
    NSString *name = [self.model objectForKey:@"name"];
    
    if(![self validateName:name]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"uploadview.name.invalid.title", @"") 
                                                            message:NSLocalizedString(@"uploadview.name.invalid.message", 
                                                                                      @"Invalid characters in name") 
                                                           delegate:nil 
                                                  cancelButtonTitle:NSLocalizedString(@"closeButtonText", @"") 
                                                  otherButtonTitles:nil, nil];
        [alertView show];
        [alertView release];
        
        return;
    }
    
    //The audio is the only one that the user generates from this viewController
    if(self.uploadInfo.uploadType == UploadFormTypeAudio)
    {
        NSURL *audioUrl = [self.model objectForKey:@"previewURL"];
        [self.uploadInfo setUploadFileURL:audioUrl];
    }
    
    if (!self.uploadInfo.uploadFileURL || (name == nil || [name length] == 0)) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"uploadview.required.fields.missing.dialog.title", @"") 
                                                            message:NSLocalizedString(@"uploadview.required.fields.missing.dialog.message", 
                                                                                      @"Please fill in all required fields") 
                                                           delegate:nil 
                                                  cancelButtonTitle:NSLocalizedString(@"closeButtonText", @"") 
                                                  otherButtonTitles:nil, nil];
        [alertView show];
        [alertView release];
        
        return;
    }

    //We remove the extension if the user typed it
    if([[name pathExtension] isEqualToString:self.uploadInfo.extension]) {
        name = [name stringByDeletingPathExtension];
    }
    
    [self.uploadInfo setFilename:name];
    
    int ct = 0;
    NSString *newName = [[name copy] autorelease];
    while ([self array:existingDocumentNameArray containsInsensitiveString:[self.uploadInfo completeFileName]]) {
        NSLog(@"File with name %@ exists, incrementing and trying again", [self.uploadInfo completeFileName]);
        
        newName = [NSString stringWithFormat:@"%@-%d", name, ++ct];
        [self.uploadInfo setFilename:newName];
    }
    
    name = newName;

    NSLog(@"New Filename: %@", [self.uploadInfo completeFileName]);
    
    
    NSString *tags = [model objectForKey:@"tags"];
    if ((tags != nil) && ![tags isEqualToString:@""]) {
        NSArray *tagsArray = [tags componentsSeparatedByString:@","];
        [uploadInfo setTags:tagsArray];
        [uploadInfo setTenantID:self.tenantID];
    }
    
    // We call the helper to perform any last action before uploading, like resizing an image with a quality parameter
    [self.uploadHelper preUpload];
    [[UploadsManager sharedManager] queueUpload:self.uploadInfo];
    
    // Alerting the user that the upload will continue in the background
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Uploads"
                                                        message:@"Your upload has been started and will run in the background"
                                                       delegate:nil 
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"") 
                                              otherButtonTitles:nil, nil];
    [alertView show];
    [alertView release];
    [self popViewController];
}

- (void)uploadDocumentWithData:(NSData *)data
{
    
}

- (BOOL)array:(NSArray *)array containsInsensitiveString:(NSString *)string
{
    for(NSString *element in array)
    {
        if([element isEqualToCaseInsensitiveString:string])
        {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)validateName:(NSString *)name
{
    
    name = [name trimWhiteSpace];
    NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"?/\\:*?\"<>|#"];
    
    return ![name isEqualToString:[NSString string]] && [name rangeOfCharacterFromSet:set].location == NSNotFound;
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


#pragma mark -
#pragma mark FIX to enable the name field to become the first responder after a reload
- (void)updateAndReload
{
    [super updateAndReload];
    shouldSetResponder = YES;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *originalCell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    NSUInteger section = indexPath.section;
	NSUInteger row = indexPath.row;
	NSArray *cells = [tableGroups objectAtIndex:section];
	id<IFCellController> controller = [cells objectAtIndex:row];
    
    if(shouldSetResponder && [textCellController isEqual:controller])
    {
        [textCellController becomeFirstResponder];
        shouldSetResponder = NO;
    }
    
    return originalCell;
}

#pragma mark -
#pragma mark Generic Table View Methods

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

    /**
     * Name field
     */
    self.textCellController = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"uploadview.tablecell.name.label", @"Name")
                                                            andPlaceholder:NSLocalizedString(@"uploadview.tablecell.name.placeholder", @"Enter a name")
                                                                     atKey:@"name" inModel:self.model] autorelease];
    [textCellController setEditChangedAction:@selector(nameValueChanged:)];
    [textCellController setUpdateTarget:self];
    [uploadFormCellGroup addObject:textCellController];

    /**
     * Upload type-specific field
     */
    id cellController;
    switch (self.uploadInfo.uploadType) {
        case UploadFormTypeDocument:
        {
            cellController = [[DocumentIconNameCellController alloc] initWithLabel:NSLocalizedString([self uploadTypeCellLabel:self.uploadInfo.uploadType], @"Document")  atKey:@"previewURL" inModel:self.model];
            [uploadFormCellGroup addObject:cellController];
            break;
        }
        case UploadFormTypeVideo:
        {
            [IpadSupport clearDetailController];
            cellController = [[VideoCellController alloc] initWithLabel:NSLocalizedString([self uploadTypeCellLabel:self.uploadInfo.uploadType], @"Video") atKey:@"previewURL" inModel:self.model];
            [uploadFormCellGroup addObject:cellController];
            break;
        }
        case UploadFormTypeAudio:
        {
            cellController = [[AudioCellController alloc] initWithLabel:NSLocalizedString([self uploadTypeCellLabel:self.uploadInfo.uploadType], @"Audio") atKey:@"previewURL" inModel:self.model];
            [uploadFormCellGroup addObject:cellController];
            break;
        }
        default:
        {
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:self.uploadInfo.uploadFileURL] ];
            [self.model setObject:image forKey:@"media"];
            cellController = [[IFPhotoCellController alloc] initWithLabel:NSLocalizedString([self uploadTypeCellLabel:self.uploadInfo.uploadType], @"Photo")  atKey:@"media" inModel:self.model];
            
            NSArray *imageUploadSizing = [AppProperties propertyForKey:kImageUploadSizingOptionValues];
            NSString *userSelectedSizing = [[FDKeychainUserDefaults standardUserDefaults] objectForKey:@"ImageUploadSizingOption"];
            if(!userSelectedSizing || ![imageUploadSizing containsObject:userSelectedSizing])
            {
                userSelectedSizing = [AppProperties propertyForKey:kImageUploadSizingOptionDefault];
            }
            [self.model setObject:userSelectedSizing forKey:kPhotoQualityKey];
            
            IFChoiceCellController *qualityChoiceCell = [[IFChoiceCellController alloc] initWithLabel:NSLocalizedString(@"uploadview.tablecell.photoQuality.label", @"Photo Quality") andChoices:imageUploadSizing atKey:kPhotoQualityKey inModel:self.model];
            [qualityChoiceCell setUpdateTarget:self];
            [qualityChoiceCell setUpdateAction:@selector(qualitySettingsChanged:)];
            
            [uploadFormCellGroup addObject:cellController];
            [uploadFormCellGroup addObject:qualityChoiceCell];
            [qualityChoiceCell release];
            break;
        }
    }
    
    
    [cellController release];
    
    [headers addObject:@""];
	[groups addObject:uploadFormCellGroup];
	[footers addObject:@""];
    
    
    //    NSMutableArray *optionalFormCellGroup = [NSMutableArray array];
    //    
    //    textCellController = [[IFTextCellController alloc] initWithLabel:@"Title" andPlaceholder:@"" atKey:@"Title" inModel:self.model];
    //    [optionalFormCellGroup addObject:textCellController];
    //    [textCellController release];
    //    
    //    textCellController = [[IFTextCellController alloc] initWithLabel:@"Description" andPlaceholder:@"" atKey:@"Description" inModel:self.model];
    //    [optionalFormCellGroup addObject:textCellController];
    //    [textCellController release];
    //    
    //    
    //    [headers addObject:@"Optional"];
    //	[groups addObject:optionalFormCellGroup];
    //	[footers addObject:@""];
    
    /**
     * Tagging fields
     */
    NSMutableArray *tagsCellGroup = [NSMutableArray array];
    
    IFChoiceCellController *tagsCellController = [[IFChoiceCellController alloc ] initWithLabel:NSLocalizedString(@"uploadview.tablecell.tags.label", @"Tags")
                                                                                     andChoices:availableTagsArray atKey:@"tags" inModel:self.model];
    [tagsCellController setSeparator:@","];
    [tagsCellController setSelectionOptional:YES];
    [tagsCellGroup addObject:tagsCellController];
    [tagsCellController release];
    
    IFButtonCellController *addNewTagCellController = [[IFButtonCellController alloc] initWithLabel:NSLocalizedString(@"uploadview.tablecell.addnewtag.label", @"Add New Tag")
                                                                                         withAction:@selector(addNewTagButtonPressed) 
                                                                                           onTarget:self];
    [tagsCellGroup addObject:addNewTagCellController];
    [addNewTagCellController release];
    
    [headers addObject:@""];
	[groups addObject:tagsCellGroup];
	[footers addObject:@""];
    
    
    
    tableGroups = [groups retain];
	tableHeaders = [headers retain];
	tableFooters = [footers retain];
    
	[self assignFirstResponderHostToCellControllers];
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
    UIAlertView *alert = [[UIAlertView alloc] 
                          initWithTitle:NSLocalizedString(@"uploadview.tablecell.addnewtag.label", @"Add New Tag")
                          message:@" \r\n "
                          delegate:self 
                          cancelButtonTitle:NSLocalizedString(@"closeButtonText", @"Cancel Button Text")
                          otherButtonTitles:NSLocalizedString(@"Add", @"Add"), nil];
    
    [self setCreateTagTextField:[[[UITextField alloc] initWithFrame:CGRectMake(12.0, 45.0, 260.0, 25.0)] autorelease]];
    [createTagTextField setBackgroundColor:[UIColor whiteColor]];
    [createTagTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];	
    
    [alert addSubview:createTagTextField];
    [alert show];
    [alert release];
}

- (void)popViewController
{
    if (updateTarget && [updateTarget respondsToSelector:updateAction]) {
        [updateTarget performSelector:updateAction];
    }

    NSLog(@"RELOAD FOLDER LIST");

    [self notifyCellControllers];
    if(self.delegate && self.presentedAsModal) {
        [self.delegate dismissUploadViewController:self didUploadFile:NO];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
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
        [self updateAndReload];
    }
}

#pragma mark -
#pragma mark UIAlertViewDelegate Methods

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
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"uploadview.error.invalidtag.title", @"Invalid Tag")
                                                            message:NSLocalizedString(@"uploadview.error.invalidtag.message", @"Tags must contain text") 
                                                           delegate:nil 
                                                  cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"Okay")
                                                  otherButtonTitles:nil, nil];
            [alert show];
            [alert release];
            NSLog(@"Empty Tag ERROR");
        }
        else 
        {
            newTag = [[newTag lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if ([availableTagsArray containsObject:newTag]) {
                [self addAndSelectNewTag:newTag];
            }
            else {
                NSLog(@"Create Tag: %@", newTag);
                // Tag does not exist, tag must be added
                TaggingHttpRequest *request = [TaggingHttpRequest httpRequestCreateNewTag:newTag accountUUID:selectedAccountUUID tenantID:self.tenantID];
                [request setDelegate:self];
                HUD = [[MBProgressHUD alloc] initWithWindow:self.tableView.window];
                [HUD showWhileExecuting:@selector(startAsynchronous) onTarget:request withObject:nil animated:YES];
            }
        }
    }
    
    [createTagTextField resignFirstResponder];
    [self setCreateTagTextField:nil];
}



#pragma mark -
#pragma mark ASIHTTPRequestDelegate Methods
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
        [self updateAndReload];
    }
    else if ([request.apiMethod isEqualToString:kCreateTag])
    {
        NSString *newTag = [request.userDictionary objectForKey:@"tag"];
        [self addAndSelectNewTag:newTag];
    }
}

- (void)requestFailed:(TaggingHttpRequest *)request
{
    // Remove the request if it's been stored
    [[self asyncRequests] removeObject:request];

    [self setAvailableTagsArray:[NSMutableArray array]];
    NSLog(@"Failed to retrieve tags: %@", request.apiMethod);
    
    if ([request.apiMethod isEqualToString:kCreateTag])
    {
        NSString *newTag = [request.userDictionary objectForKey:@"tag"];
        UIAlertView *createTagFailureAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"uplaodview.error.title", @"Error")
                                                                        message:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"uploadview.error.requestfailed.message", @"Failed to create tag [tagname]"), newTag]
                                                                       delegate:nil 
                                                              cancelButtonTitle:NSLocalizedString(@"closeButtonText", @"Close") 
                                                              otherButtonTitles:nil, nil];
        [createTagFailureAlert show];
        [createTagFailureAlert release];
        [request clearDelegatesAndCancel];
    }

}


#pragma mark -
#pragma mark MBProgressHUDDelegate
- (void)hudWasHidden
{
    // Remove HUD from screen when the HUD was hidded
    [HUD removeFromSuperview];
    [HUD release];
    HUD = nil;
    
    if (popViewControllerOnHudHide) {
        [self popViewController];
    }
}

- (NSString *) uploadTypeTitleLabel: (UploadFormType) type {
    switch (type) {
        case UploadFormTypeDocument:
            return @"upload.document.view.title";
            break;
        case UploadFormTypeVideo:
            return @"upload.video.view.title";
            break;
        case UploadFormTypeAudio:
            return @"upload.audio.view.title";
            break;
        default:
            return @"upload.photo.view.title";
            break;
    }
}

- (NSString *) uploadTypeCellLabel: (UploadFormType) type {
    switch (type) {
        case UploadFormTypeDocument:
            return @"uploadview.tablecell.document.label";
            break;
        case UploadFormTypeVideo:
            return @"uploadview.tablecell.video.label";
            break;
        case UploadFormTypeAudio:
            return @"uploadview.tablecell.audio.label";
            break;
        default:
            return @"uploadview.tablecell.photo.label";
            break;
    }
}

- (NSString *) uploadTypeProgressBarTitle: (UploadFormType) type {
    switch (type) {
        case UploadFormTypeDocument:
            return @"postprogressbar.upload.document";
            break;
        case UploadFormTypeVideo:
            return @"postprogressbar.upload.video";
            break;
        case UploadFormTypeAudio:
            return @"postprogressbar.upload.audio";
            break;
        default:
            return @"postprogressbar.upload.picture";
            break;
    }
}



@end
