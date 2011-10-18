//
//  DocumentViewController.m
//  Alfresco
//
//  Created by Michael Muller on 9/3/09.
//  Copyright 2009 Zia Consulting. All rights reserved.
//

#import "DocumentViewController.h"
#import "SavedDocument.h"
#import "DocumentCommentsTableViewController.h"
#import "CommentsHttpRequest.h"
#import "NodeRef.h"
#import "IFTemporaryModel.h"
#import "RepositoryServices.h"

#define kWebViewTag 1234
#define kToolbarSpacerWidth 15.0f
#define kFrameLoadCodeError 102

#define kAlertViewOverwriteConfirmation 1
#define kAlertViewDeleteConfirmation 2

@implementation DocumentViewController
@synthesize cmisObjectId;
@synthesize fileData;
@synthesize fileName;
@synthesize contentMimeType;
@synthesize isFavorite;
@synthesize documentToolbar;
@synthesize favoriteButton;
@synthesize webView;
@synthesize docInteractionController;


- (void)dealloc {
    [cmisObjectId release];
	[fileData release];
	[fileName release];
    [contentMimeType release];
	[documentToolbar release];
	[favoriteButton release];
	[webView release];
	[docInteractionController release];


    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    NSError *error = nil;
	NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:self.fileName];
    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    if (error)
        NSLog(@"Error removing temporary file at path %@.  Error: %@", path, error);
    [super viewDidUnload];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    BOOL usingAlfresco = [[RepositoryServices shared] isCurrentRepositoryVendorNameEqualTo:kAlfrescoRepositoryVendorName];
    
    NSMutableArray *updatedItemsArray = [NSMutableArray arrayWithArray:[documentToolbar items]];
	
    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction 
                                                                                  target:self 
                                                                                  action:@selector(actionButtonPressed:)];
    [updatedItemsArray insertObject:[self iconSpacer] atIndex:1];
    [updatedItemsArray insertObject:actionButton atIndex:1];
    [actionButton release];
    
    if (self.cmisObjectId) {
        if (usingAlfresco && ![[[RepositoryServices shared] currentRepositoryInfo] isPreReleaseCmis])
        {
            UIBarButtonItem *commentButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"comments.png"]
                                                                              style:UIBarButtonItemStylePlain 
                                                                             target:self action:@selector(commentsButtonPressed:)];
            [updatedItemsArray addObject:[self iconSpacer]];
            [updatedItemsArray addObject:commentButton];
            [commentButton release];
        }
        

        UIBarButtonItem *downloadButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"download.png"] 
                                                                           style:UIBarButtonItemStylePlain 
                                                                          target:self action:@selector(downloadButtonPressed)];
        [updatedItemsArray addObject:[self iconSpacer]];
        [updatedItemsArray addObject:downloadButton];
        [downloadButton release];
    }
    else {
        UIBarButtonItem *trashButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash 
                                                                                     target:self action:@selector(trashButtonPressed)];
        [updatedItemsArray addObject:[self iconSpacer]];
        [updatedItemsArray addObject:trashButton];
        [trashButton release];
    }
    
    [self.documentToolbar setItems:updatedItemsArray];
    
//////////////
    
	[webView setScalesPageToFit:YES];

	// write the file contents to the file system
	NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:self.fileName];
	[self.fileData writeToFile:path atomically:NO];
	
	// get a URL that points to the file on the filesystemw
	NSURL *url = [NSURL fileURLWithPath:path];
    if (contentMimeType) {
        [webView loadData:fileData MIMEType:contentMimeType textEncodingName:@"utf-8" baseURL:url];
    } 
    else {
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [webView loadRequest:request];
    }
	
	
	// load the document into the view

	
	[self setTitle:fileName];
}

- (UIBarButtonItem *)iconSpacer
{        
    UIBarButtonItem *iconSpacer = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace 
                                                                                 target:nil action:nil] autorelease];
    [iconSpacer setWidth:kToolbarSpacerWidth];
    return iconSpacer;
}
    

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}


#pragma mark -
#pragma mark Action Selectors

- (IBAction)sendMail {
	MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
	
	[mailer addAttachmentData:[NSData dataWithContentsOfFile:[SavedDocument pathToTempFile:fileName]] 
					 mimeType:[SavedDocument mimeTypeForFilename:fileName] fileName:fileName];	
	[mailer setSubject:fileName];
	[mailer setMessageBody:NSLocalizedString(@"sendMailBodyText", 
                                             @"Sent from my document repository using Fresh Docs, the native iPhone client for Alfresco.") 
                    isHTML:NO];
	
	[self presentModalViewController:mailer animated:YES];
	mailer.mailComposeDelegate = self;
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)addToFavorites {
	if ([SavedDocument isSaved:fileName]) {
		[SavedDocument unsave:fileName];
		[self.favoriteButton setImage:[UIImage imageNamed:@"favorite-unchecked.png"]];
	}
	else {
		[SavedDocument save:fileName];
		[self.favoriteButton setImage:[UIImage imageNamed:@"favorite-checked.png"]];
	}
}

- (IBAction)actionButtonPressed:(UIBarButtonItem *)sender 
{
    if (docInteractionController == nil) {
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:self.fileName];
        NSURL *url = [NSURL fileURLWithPath:path];
        [self setDocInteractionController:[UIDocumentInteractionController interactionControllerWithURL:url]];
        [[self docInteractionController] setDelegate:self];
    }
    else {
        [docInteractionController dismissMenuAnimated:YES];
    }
    
    if ( ![[self docInteractionController] presentOpenInMenuFromBarButtonItem:sender animated:YES] ) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"noAppsAvailableDialogTitle", @"No Applications Available")
                                                        message:NSLocalizedString(@"noAppsAvailableDialogMessage", @"There are no applications that are capable of opening this file on this device")
                                                       delegate:nil 
                                              cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK Button Text")
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}


- (void)downloadButtonPressed
{
    if ([SavedDocument isSaved:fileName]) {
        UIAlertView *overwritePrompt = [[[UIAlertView alloc] initWithTitle:@"" 
                                                                  message:NSLocalizedString(@"There is already a downloaded file with the same name.  Do you want to overwrite the existing file?", @"")
                                                                 delegate:self 
                                                        cancelButtonTitle:NSLocalizedString(@"No", @"No Button Text") 
                                                         otherButtonTitles:NSLocalizedString(@"Yes", @"Yes BUtton Text"), nil] autorelease];
        
        [overwritePrompt setTag:kAlertViewOverwriteConfirmation];
        [overwritePrompt show];
    }
    else {
        [self saveFileLocally];
    }
}

- (void)saveFileLocally 
{
    [SavedDocument save:fileName];
    UIAlertView *saveConfirmationAlert = [[UIAlertView alloc] initWithTitle:@"" 
                                                                    message:NSLocalizedString(@"The document has been saved to your device", @"")
                                                                   delegate:nil 
                                                          cancelButtonTitle:NSLocalizedString(@"closeButtonText", @"Close")
                                                          otherButtonTitles:nil, nil];
    [saveConfirmationAlert show];
    [saveConfirmationAlert release];
}

- (void)trashButtonPressed
{
    UIAlertView *deleteConfirmationAlert = [[[UIAlertView alloc] initWithTitle:@"" 
                                                                       message:NSLocalizedString(@"Do you want to remove this document from your device?", @"Do you want to remove this document from your device?")
                                                                      delegate:self 
                                                             cancelButtonTitle:NSLocalizedString(@"No", @"No Button Text") 
                                                             otherButtonTitles:NSLocalizedString(@"Yes", @"Yes BUtton Text"), nil] autorelease];
    [deleteConfirmationAlert setTag:kAlertViewDeleteConfirmation];
    [deleteConfirmationAlert show];
}


#pragma mark -
#pragma mark UIAlertViewDelegate methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case kAlertViewOverwriteConfirmation:
        {
            if (buttonIndex != alertView.cancelButtonIndex) {
                [self saveFileLocally];
            }
            break;
        }
        case kAlertViewDeleteConfirmation:
        {
            if (buttonIndex != alertView.cancelButtonIndex) {
                NSLog(@"User confirmed removal of file %@", fileName);
                [SavedDocument unsave:fileName];
            }
            break;
        }
        default:
            NSLog(@"Unknown AlertView!");
            break;
    }
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}


#pragma mark -
#pragma View Comments Button and related methods

- (IBAction)commentsButtonPressed:(id)sender
{
    if (self.cmisObjectId && ([self.cmisObjectId length] > 0)) {
        NSLog(@"Comment Button Pressed, retrieving Comments From Alfresco");
        CommentsHttpRequest *request = [CommentsHttpRequest commentsHttpGetRequestWithNodeRef:[NodeRef nodeRefFromCmisObjectId:self.cmisObjectId]];
        [request setDelegate:self];
        [request setDidFinishSelector:@selector(commentsHttpRequestDidFinish:)];
        [request setDidFailSelector:@selector(commentsHttpRequestDidFail:)];
        [request startAsynchronous];
    }
    else {
        NSLog(@"NodeRef not available");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" 
                                                            message:NSLocalizedString(@"Comments Not Available", @"Comments not available")
                                                           delegate:nil 
                                                  cancelButtonTitle:NSLocalizedString(@"closeButtonText", @"closeButtonText") 
                                                  otherButtonTitles:nil, nil];
        [alertView show];
        [alertView release];
    }
}

- (void)commentsHttpRequestDidFinish:(id)sender
{
    NSLog(@"commentsHttpRequestDidFinish");
    CommentsHttpRequest * request = (CommentsHttpRequest *)sender;
//    int statusCode = [request responseStatusCode];
//    NSString *statusMessage = [request responseStatusMessage];
    
    DocumentCommentsTableViewController *viewController = [[DocumentCommentsTableViewController alloc] initWithCMISObjectId:self.cmisObjectId];
    [viewController setModel:[[[IFTemporaryModel alloc] initWithDictionary:request.commentsDictionary] autorelease]];    
    [self.navigationController pushViewController:viewController animated:YES];
    [viewController release];
}

-(void)commentsHttpRequestDidFail:(id)sender
{
    NSLog(@"commentsHttpRequestDidFail!");
}



#pragma mark -
#pragma Like/Unlike button methods and related methods

- (IBAction)likeButtonPressed:(id)sender 
{	
    NSLog(@"Like Button Pressed");
}


#pragma mark -
#pragma mark UIDocumentInteractionControllerDelegate Methods

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)interactionController
{
    return self;
}

#pragma mark -
#pragma mark UIWebViewDelegate

/* We want to know when the document cannot be rendered
 UIWebView throws two errors when a document cannot be previewed
 code:100 message: "Operation could not be completed. (NSURLErrorDomain error 100.)"
 code:102 message: "Frame load interrupted"
 */
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if([error code] == kFrameLoadCodeError) { 
        NSLog(@"Failed to load preview: %@", [error description]);
        [self performSelectorOnMainThread:@selector(previewLoadFailed) withObject:nil waitUntilDone:NO];
    }
    
}

- (void)previewLoadFailed {
    UIAlertView *failureAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"documentview.preview.failure.title", @"")
                                                           message:NSLocalizedString(@"documentview.preview.failure.message", @"Failed to preview the document" )
                                                          delegate:nil 
                                                 cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK")
                                                 otherButtonTitles:nil, nil];
    [failureAlert show];
    [failureAlert release];
}

@end
