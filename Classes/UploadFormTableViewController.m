//
//  UploadFormTableViewController.m
//  FreshDocs
//
//  Created by Gi Hyun Lee on 7/26/11.
//  Copyright 2011 Zia Consulting. All rights reserved.
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


@implementation UploadFormTableViewController
@synthesize upLinkRelation;
@synthesize postProgressBar;
@synthesize createTagTextField;
@synthesize availableTagsArray;
@synthesize updateAction;
@synthesize updateTarget;
@synthesize existingDocumentNameArray;


- (void)dealloc
{
    [upLinkRelation release];
    [postProgressBar release];
    [createTagTextField release];
    [availableTagsArray release];
    [existingDocumentNameArray release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
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
    [self.navigationItem setTitle:NSLocalizedString(@"upload.photo.view.title", @"Title for the form based view controller for photo uploads")];
    
    // Buttons
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed)];
    [self.navigationItem setLeftBarButtonItem:cancelButton];
    [cancelButton release];
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Upload", @"Upload") style:UIBarButtonItemStyleDone target:self action:@selector(saveButtonPressed)];
    [self.navigationItem setRightBarButtonItem:saveButton];
    [saveButton release];
    
    NSLog(@"GHLXXX viewDidLoad");
}

- (void)viewWillAppear:(BOOL)animated
{
    // Retrieve Tags
    HUD = [[MBProgressHUD alloc] initWithWindow:[(AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate] window]];
    TaggingHttpRequest *request = [TaggingHttpRequest httpRequestListAllTags];
    [request setDelegate:self];
    [HUD showWhileExecuting:@selector(startAsynchronous) onTarget:request withObject:nil animated:YES];
    
    popViewControllerOnHudHide = NO;
    
    [super viewWillAppear:YES];
    
    NSLog(@"GHLXXX viewWillAppear");
}

- (void)cancelButtonPressed
{
    NSLog(@"CANCEL BUTTON PRESSED!");
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)saveButtonPressed
{
    NSLog(@"SAVE BUTTON PRESSED!");
    
    // Make sure we have all required values.
    UIImage *photo = [self.model objectForKey:@"media"];
    NSString *name = [[self.model objectForKey:@"name"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (photo == nil || (name == nil || [name length] == 0)) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" 
                                                            message:@"Please fill in all required fields" 
                                                           delegate:nil 
                                                  cancelButtonTitle:NSLocalizedString(@"cancelButton", @"") 
                                                  otherButtonTitles:nil, nil];
        [alertView show];
        [alertView release];
        
        return;
    }
    
    int ct = 0;
    NSString *filename = [[NSString alloc] initWithString:name];
    while ([existingDocumentNameArray containsObject:[filename stringByAppendingPathExtension:@"png"]]) {
        NSLog(@"File with name %@.png exists, incrementing and trying again", filename);
        [filename release];
        filename = [[NSString alloc] initWithFormat:@"%@-%d", name, ++ct];
    }
    name = [[filename copy] autorelease];
    NSLog(@"New Filename: %@.png", name);
    
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
    
    
    if (nil != photo) {
        NSData *imageData = UIImagePNGRepresentation(photo);
        NSString *postBody  = [NSString stringWithFormat:@""
                               "<?xml version=\"1.0\" ?>"
                               "<entry xmlns=\"http://www.w3.org/2005/Atom\" xmlns:app=\"http://www.w3.org/2007/app\" xmlns:cmisra=\"http://docs.oasis-open.org/ns/cmis/restatom/200908/\">"
                               "<cmisra:content>"
                               "<cmisra:mediatype>image/png</cmisra:mediatype>"
                               "<cmisra:base64>%@</cmisra:base64>"
                               "</cmisra:content>"
                               "<cmisra:object xmlns:cmis=\"http://docs.oasis-open.org/ns/cmis/core/200908/\">"
                               "<cmis:properties>"
                               "<cmis:propertyId propertyDefinitionId=\"cmis:objectTypeId\"><cmis:value>cmis:document</cmis:value></cmis:propertyId>"
                               "</cmis:properties>"
                               "</cmisra:object>"
                               "<title>%@.png</title>"
                               "</entry>",
                               [imageData base64EncodedString],
                               name
                               ];
        
        NSLog(@"POST: %@", upLinkRelation);
        upLinkRelation = [upLinkRelation stringByAppendingFormat:@"?versionState=major"];
        
        self.postProgressBar = 
        [PostProgressBar createAndStartWithURL:[NSURL URLWithString:upLinkRelation]
                                   andPostBody:postBody
                                      delegate:self 
                                       message:NSLocalizedString(@"Uploading Photo", @"Uploading Photo")];

    }
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
    
    IFPhotoCellController *cellController = [[IFPhotoCellController alloc] initWithLabel:@"Photo" atKey:@"media" inModel:self.model];
    [uploadFormCellGroup addObject:cellController];
    [cellController release];
    
    IFTextCellController *textCellController = nil;
    
    textCellController = [[IFTextCellController alloc] initWithLabel:@"Name" andPlaceholder:@"Enter a name" atKey:@"name" inModel:self.model];
    [uploadFormCellGroup addObject:textCellController];
    [textCellController release];
    
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
    
    NSMutableArray *tagsCellGroup = [NSMutableArray array];
    
    IFChoiceCellController *tagsCellController = [[IFChoiceCellController alloc ] initWithLabel:@"Tags" 
                                                                                     andChoices:availableTagsArray atKey:@"tags" inModel:self.model];
    [tagsCellController setSeparator:@","];
    [tagsCellController setSelectionOptional:YES];
    [tagsCellGroup addObject:tagsCellController];
    [tagsCellController release];
    
    IFButtonCellController *addNewTagCellController = [[IFButtonCellController alloc] initWithLabel:@"Add New Tag" 
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

- (void)addNewTagButtonPressed
{   
    UIAlertView *alert = [[UIAlertView alloc] 
                          initWithTitle:@"Add New Tag"
                          message:@" \r\n "
                          delegate:self 
                          cancelButtonTitle:NSLocalizedString(@"cancelButton", @"Cancel Button Text")
                          otherButtonTitles:@"Add", nil];
    
    [self setCreateTagTextField:[[UITextField alloc] initWithFrame:CGRectMake(12.0, 45.0, 260.0, 25.0)]];
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
    [self.navigationController popViewControllerAnimated:YES];

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
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid Tag" message:@"Tags must contain text" 
                                                           delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
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
                TaggingHttpRequest *request = [TaggingHttpRequest httpRequestCreateNewTag:newTag];
                [request setDelegate:self];
                HUD = [[MBProgressHUD alloc] initWithWindow:self.tableView.window];
                [HUD showWhileExecuting:@selector(startAsynchronous) onTarget:request withObject:nil animated:YES];
            }
        }
    }
    
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
    // TODO:  IF cmis:objectId is nil here then we failed to create new upload file
    //
    //
    
    NSLog(@"cmis:objectId=%@", bar.cmisObjectId);
    NSArray *tagsArray = [tags componentsSeparatedByString:@","];
    TaggingHttpRequest *request = [TaggingHttpRequest httpRequestAddTags:tagsArray
                                                                  toNode:[NodeRef nodeRefFromCmisObjectId:bar.cmisObjectId]];
    [request setDelegate:self];
    
    HUD = [[MBProgressHUD alloc] initWithWindow:[(AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate] window]];
    [HUD showWhileExecuting:@selector(startAsynchronous) onTarget:request withObject:nil animated:YES];
    popViewControllerOnHudHide = YES;
}


#pragma mark -
#pragma mark ASIHTTPRequestDelegate Methods
-(void)requestFinished:(TaggingHttpRequest *)request
{   
    if ([request.apiMethod isEqualToString:kListAllTags] ) 
    {
        NSArray *parsedTags = [TaggingHttpRequest tagsArrayWithResponseString:[request responseString]];

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
    [self setAvailableTagsArray:nil];
    NSLog(@"Failed to retrieve tags: %@", request.apiMethod);
    
    if ([request.apiMethod isEqualToString:kCreateTag])
    {
        NSString *newTag = [request.userDictionary objectForKey:@"tag"];
        UIAlertView *createTagFailureAlert = [[UIAlertView alloc] initWithTitle:@"Error" 
                                                                        message:[NSString stringWithFormat:@"%@ %@", @"Failed to create tag", newTag]
                                                                       delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil, nil];
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

@end
