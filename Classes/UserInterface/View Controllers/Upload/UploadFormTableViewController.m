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

@interface UploadFormTableViewController  (private)

- (NSString *) uploadTypeTitleLabel: (UploadFormType) type;
- (NSString *) uploadTypeCellLabel: (UploadFormType) type;
- (NSString *) uploadTypeProgressBarTitle: (UploadFormType) type;
- (BOOL)validateName:(NSString *)name;
- (void)nameValueChanged:(id)sender;
@end


@implementation UploadFormTableViewController
@synthesize upLinkRelation;
@synthesize postProgressBar;
@synthesize createTagTextField;
@synthesize availableTagsArray;
@synthesize updateAction;
@synthesize updateTarget;
@synthesize existingDocumentNameArray;
@synthesize delegate;
@synthesize presentedAsModal;
@synthesize uploadType;
@synthesize selectedAccountUUID;
@synthesize tenantID;
@synthesize textCellController;
@synthesize asyncRequests;

- (void)dealloc
{
    [upLinkRelation release];
    [postProgressBar release];
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
        uploadType = UploadFormTypePhoto;
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
    [self.navigationItem setTitle:NSLocalizedString([self uploadTypeTitleLabel:uploadType], @"Title for the form based view controller for photo uploads")];
    
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
    
    [self setAsyncRequests:[[NSMutableArray alloc] init]];
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
    
    // Make sure we have all required values.
    UIImage *photo = [self.model objectForKey:@"media"];
    NSURL *filePath = nil;
    
    if(uploadType == UploadFormTypeDocument) {
        filePath = [NSURL URLWithString:[self.model objectForKey:@"filePath"]];
    } else if(uploadType == UploadFormTypeVideo) {
        filePath = [self.model objectForKey:@"mediaURL"];
    } else if(uploadType == UploadFormTypeAudio) {
        filePath = [self.model objectForKey:@"mediaURL"];
        //We have to use the fileURLWithPath instead of the URLWithPath in order to read the file ???
        if(filePath) {
            filePath = [NSURL fileURLWithPath:[filePath absoluteString]];
        }
    }

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
    
    BOOL hasDocument = ( (photo != nil && uploadType == UploadFormTypePhoto) ||
                            (filePath != nil && uploadType == UploadFormTypeAudio) || 
                            (filePath != nil && uploadType == UploadFormTypeDocument) || 
                            (filePath != nil && uploadType == UploadFormTypeVideo) ); 
    
    if (!hasDocument || (name == nil || [name length] == 0)) {
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
    
    int ct = 0;
    NSString *filename = [name copy];
    NSString *extension = nil;
    BOOL useJPEG = [[AppProperties propertyForKey:kUUseJPEG] boolValue];
    
    switch (uploadType) {
        case UploadFormTypeDocument:
        case UploadFormTypeAudio:
        case UploadFormTypeVideo:
            extension = [[filePath pathExtension] lowercaseString];
            break;
        default:
            if(useJPEG) {
                extension = @"jpg";
            } else {
                extension = @"png";
            }
            break;
    }
    
    //We remove the extension if the user typed it
    if([[filename pathExtension] isEqualToString:extension]) {
        NSString *newName = [filename stringByDeletingPathExtension];
        [filename release];
        filename = [newName retain];
    }
    
    while ([existingDocumentNameArray containsObject:[filename stringByAppendingPathExtension:extension]]) {
        NSLog(@"File with name %@.%@ exists, incrementing and trying again", filename, extension);
        [filename release];
        filename = [[NSString alloc] initWithFormat:@"%@-%d", name, ++ct];
    }
    name = [[filename copy] autorelease];
    [filename release];
    NSLog(@"New Filename: %@.%@", name, extension);
    
//    // Make sure the document name is not duplicated as we cannot 'overwrite' a document using cmis without versioning
//    NSLog(@"Checking for duplicates: %@ in %@", [name stringByAppendingPathExtension:@"png"], existingDocumentNameArray	);
//    if ([existingDocumentNameArray containsObject:[name stringByAppendingPathExtension:@"png"]]) {
//        NSLog(@"Name '%@' exists, preventing upload submission", name);
//        NSString *msg = [NSString stringWithFormat:@"A document named '%@' already exists.  Please enter a different name.", name];
//        UIAlertView *duplicateNameWarning = [[UIAlertView alloc] initWithTitle:@"" 
//                                                                       message:msg
//                                                                      delegate:nil 
//                                                             cancelButtonTitle:NSLocalizedString(@"closeButtonText", @"") 
//                                                             otherButtonTitles:nil, nil];
//        [duplicateNameWarning show];
//        [duplicateNameWarning release];
//        
//        return;
//    }
    
    
    if (hasDocument) {
        NSData *documentData = nil;
        NSString *mimeType = mimeTypeForFilename([NSString stringWithFormat:@"%@.%@", name, extension]);
        
        UIImage *originalImage = [self.model objectForKey:@"originalMedia"];
        if(originalImage) {
            photo = originalImage;
        }
        
        switch (uploadType) {
            case UploadFormTypeDocument:
                if ([mimeType isEqualToString:@"text/plain"])
                {
                    // make sure we read the text files using their current encoding
                    NSString *fileContents = [NSString stringWithContentsOfFile:[filePath path] usedEncoding:NULL error:NULL];
                    documentData = [fileContents dataUsingEncoding:NSUTF8StringEncoding];
                }
                else
                {
                    documentData = [NSData dataWithContentsOfURL:filePath];
                }
                break;
            case UploadFormTypeVideo:
            case UploadFormTypeAudio:
                documentData = [NSData dataWithContentsOfURL:filePath];
                break;
            default:
                if(useJPEG) {
                    documentData = UIImageJPEGRepresentation(photo, 0.50);
                } else {
                    documentData = UIImagePNGRepresentation(photo);
                }
                
                break;
        }
        
        NSString *postBody  = [NSString stringWithFormat:@""
                               "<?xml version=\"1.0\" ?>"
                               "<entry xmlns=\"http://www.w3.org/2005/Atom\" xmlns:app=\"http://www.w3.org/2007/app\" xmlns:cmisra=\"http://docs.oasis-open.org/ns/cmis/restatom/200908/\">"
                               "<cmisra:content>"
                               "<cmisra:mediatype>%@</cmisra:mediatype>"
                               "<cmisra:base64>%@</cmisra:base64>"
                               "</cmisra:content>"
                               "<cmisra:object xmlns:cmis=\"http://docs.oasis-open.org/ns/cmis/core/200908/\">"
                               "<cmis:properties>"
                               "<cmis:propertyId propertyDefinitionId=\"cmis:objectTypeId\"><cmis:value>cmis:document</cmis:value></cmis:propertyId>"
                               "</cmis:properties>"
                               "</cmisra:object>"
                               "<title>%@.%@</title>"
                               "</entry>",
                               mimeType,
                               [documentData base64EncodedString],
                               [name gtm_stringBySanitizingAndEscapingForXML],
                               [extension gtm_stringBySanitizingAndEscapingForXML]
                               ];
        
        NSLog(@"POST: %@", upLinkRelation);
        upLinkRelation = [upLinkRelation stringByAppendingFormat:@"?versionState=major"];
        
        self.postProgressBar = 
        [PostProgressBar createAndStartWithURL:[NSURL URLWithString:upLinkRelation]
                                   andPostBody:postBody
                                      delegate:self 
                                       message:NSLocalizedString([self uploadTypeProgressBarTitle:uploadType], 
                                                                 @"Uploading Photo or Document")
                                        accountUUID:selectedAccountUUID];

    }
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
    switch (uploadType) {
        case UploadFormTypeDocument:
            cellController = [[DocumentIconNameCellController alloc] initWithLabel:NSLocalizedString([self uploadTypeCellLabel:uploadType], @"Document")  atKey:@"media" inModel:self.model];
            break;
        case UploadFormTypeVideo:
            cellController = [[VideoCellController alloc] initWithLabel:NSLocalizedString([self uploadTypeCellLabel:uploadType], @"Video") atKey:@"mediaURL" inModel:self.model];
            break;
        case UploadFormTypeAudio:
            cellController = [[AudioCellController alloc] initWithLabel:NSLocalizedString([self uploadTypeCellLabel:uploadType], @"Audio") atKey:@"mediaURL" inModel:self.model];
            break;
        default:
            cellController = [[IFPhotoCellController alloc] initWithLabel:NSLocalizedString([self uploadTypeCellLabel:uploadType], @"Photo")  atKey:@"media" inModel:self.model];
            break;
    }
    
    [uploadFormCellGroup addObject:cellController];
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
#pragma mark PostProgressBarDelegate
- (void) post:(PostProgressBar *)bar completeWithData:(NSData *)data
{
    NSLog(@"%@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
    
    NSString *tags = [model objectForKey:@"tags"];
    if ((tags == nil) || ([tags isEqualToString:@""])) {
        [self popViewController];
        return; 
    }
    
    //
    // TODO FIXME IMPLEMENT ME:  IF cmis:objectId is nil here then we failed to create new upload file
    //
    //
    
    NSLog(@"cmis:objectId=%@", bar.cmisObjectId);
    NSArray *tagsArray = [tags componentsSeparatedByString:@","];
    TaggingHttpRequest *request = [TaggingHttpRequest httpRequestAddTags:tagsArray
                                                                  toNode:[NodeRef nodeRefFromCmisObjectId:bar.cmisObjectId] 
                                                             accountUUID:selectedAccountUUID 
                                                                tenantID:self.tenantID];
    [request setDelegate:self];
    
    HUD = [[MBProgressHUD alloc] initWithWindow:[(AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate] window]];
    [HUD showWhileExecuting:@selector(startAsynchronous) onTarget:request withObject:nil animated:YES];
    popViewControllerOnHudHide = YES;
}

- (void) post:(PostProgressBar *)bar failedWithData:(NSData *)data
{
    NSLog(@"WARNING: post:failedWithData not implemented!");
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
    else if ([request.apiMethod isEqualToString:kAddTagsToNode]) 
    {
        NSLog(@"TAGS POSTED");
        [request clearDelegatesAndCancel];
        [self popViewController];
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
    switch (uploadType) {
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
    switch (uploadType) {
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
    switch (uploadType) {
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
