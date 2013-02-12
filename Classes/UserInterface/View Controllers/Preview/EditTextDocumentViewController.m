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
//  EditTextDocumentViewController.m
//

#import "EditTextDocumentViewController.h"
#import "Theme.h"
#import "Utility.h"
#import "AlfrescoUtils.h"
#import "CMISAtomEntryWriter.h"
#import "FileUtils.h"
#import "NSNotificationCenter+CustomNotification.h"
#import "FileDownloadManager.h"
#import "DownloadMetadata.h"
#import "FavoriteManager.h"
#import "FavoriteFileDownloadManager.h"
#import "ConnectivityManager.h"
#import "DocumentViewController.h"
#import "AlfrescoAppDelegate.h"
#import "MoreViewController.h"
#import "IpadSupport.h"

NSInteger const kEditDocumentSaveConfirm = 1;
NSInteger const kEditDocumentOverwriteConfirm = 2;

@interface EditTextDocumentViewController ()

@end

@implementation EditTextDocumentViewController
@synthesize editView = _editView;
@synthesize documentPath = _documentPath;
@synthesize documentTempPath = _documentTempPath;
@synthesize objectId = _objectId;
@synthesize postProgressBar = _postProgressBar;
@synthesize documentName = _documentName;
@synthesize fileMetadata = _fileMetadata;
@synthesize selectedAccountUUID = _selectedAccountUUID;
@synthesize tenantID = _tenantID;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];

    [_editView release];
    [_documentPath release];
    [_documentTempPath release];
    [_objectId release];
    [_postProgressBar release];
    [_documentName release];
    [_fileMetadata release];
    [_selectedAccountUUID release];
    [_tenantID release];
    [super dealloc];
}


- (id)initWithObjectId:(NSString *)objectId andDocumentPath:(NSString *)documentPath
{
    self = [self initWithNibName:@"EditTextDocumentViewController" bundle:nil];
    if(self)
    {   
        _objectId = [objectId copy];
        _documentPath = [documentPath copy];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSError *error = nil;
    NSStringEncoding fileEncoding;
	NSString *content = [NSString stringWithContentsOfFile:self.documentPath usedEncoding:&fileEncoding error:&error];
    if(error)
    {
        NSLog(@"Cannot load document path %@ with error %@", self.documentPath, [error description]);
    }
    else 
    {
        [self.editView setText:content];
    }
    
    _documentIsEmpty = ![self.editView.text isNotEmpty];
    
    UIBarButtonItem *discardButton = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"edit-document.button.discard", @"Discard Changes button") style:UIBarButtonItemStyleBordered target:self action:@selector(discardButtonAction:)] autorelease];
    UIBarButtonItem *saveButton = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"edit-document.button.save", @"Save button") style:UIBarButtonItemStyleDone target:self action:@selector(saveButtonAction:)] autorelease];
    
    [self.navigationItem setLeftBarButtonItem:discardButton];
    [self.navigationItem setRightBarButtonItem:saveButton];
    if(self.documentName)
    {
        [self setTitle:self.documentName];
    }
    else
    {
        [self setTitle:[self.documentPath lastPathComponent]];
    }
    [Theme setThemeForUINavigationController:[self navigationController]];
    styleButtonAsDefaultAction(saveButton);
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
    
    // Observe keyboard hide and show notifications to resize the text view appropriately.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWillResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWillTerminateNotification:) name:UIApplicationWillTerminateNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.editView becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.editView resignFirstResponder];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)discardButtonAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        
        [self clearPasteBoard];
        [self.delegate editTextDocumentViewControllerDismissed];
    }];
}

- (void)saveButtonAction:(id)sender
{
    //We save the file into a temporary file first, on the upload success we update the original file
    [self setDocumentTempPath:[FileUtils pathToTempFile:[NSString stringWithFormat:@"%@.%@", [NSString generateUUID], [self.documentPath pathExtension]]]];
    //Update the local file with the current text
    NSError *error = nil;
    [[self.editView text] writeToFile:self.documentTempPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if(error)
    {
        NSLog(@"Cannot save document %@ with error %@", self.documentTempPath, [error description]);
        displayErrorMessageWithTitle(NSLocalizedString(@"edit-document.writefailed.message", @"Edit Document Write Failed Message"), NSLocalizedString(@"edit-document.failed.title", @"Edit Document Save Failed Title"));
        return;
    }
    
    FavoriteManager *favoriteManager = [FavoriteManager sharedManager];
    BOOL isSyncedFavorite = ([favoriteManager isSyncPreferenceEnabled] &&
                             [favoriteManager isNodeFavorite:self.objectId inAccount:self.selectedAccountUUID]);
    
    if (isSyncedFavorite)
    {
        FavoriteFileDownloadManager *fileManager = [FavoriteFileDownloadManager sharedInstance];
        NSDictionary *downloadInfo = [favoriteManager downloadInfoForDocumentWithID:self.objectId];
        NSString *generatedFileName = [fileManager generatedNameForFile:[downloadInfo objectForKey:@"filename"] withObjectID:self.objectId];
        NSString *syncedFilePath = [fileManager pathToFileDirectory:generatedFileName];
        
        [FileUtils saveFileFrom:self.documentTempPath toDestination:syncedFilePath overwriteExisting:YES];

        // Ensure the file list and preview are updated with the latest content
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:self.objectId, @"objectId",
                                  [self.fileMetadata repositoryItem], @"repositoryItem",
                                  syncedFilePath, @"newPath", nil];
        [[NSNotificationCenter defaultCenter] postDocumentUpdatedNotificationWithUserInfo:userInfo];
        
        [self dismissViewControllerAnimated:YES completion:^{
        
            [self clearPasteBoard];
            [self.delegate editTextDocumentViewControllerDismissed];
        }];
        
        [favoriteManager forceSyncForFileURL:[NSURL URLWithString:generatedFileName] objectId:self.objectId accountUUID:self.selectedAccountUUID];
    }
    else 
    {
        // extract node id from object id
        NSString *fileName = [self documentName];
        NSArray *idSplit = [self.objectId componentsSeparatedByString:@"/"];
        NSString *nodeId = [idSplit objectAtIndex:3];
        
        // check we've got an internet connection
        if ([[ConnectivityManager sharedManager] hasInternetConnection])
        {
            // build CMIS setContent PUT request
            AlfrescoUtils *alfrescoUtils = [AlfrescoUtils sharedInstanceForAccountUUID:self.selectedAccountUUID];
            NSURL *putLink = nil;
            if (self.tenantID == nil)
            {
                putLink = [alfrescoUtils setContentURLforNode:nodeId];
            }
            else
            {
                putLink = [alfrescoUtils setContentURLforNode:nodeId tenantId:self.tenantID];
            }
            
            NSLog(@"putLink = %@", putLink);
            
            NSString *putFile = [CMISAtomEntryWriter generateAtomEntryXmlForFilePath:self.documentTempPath uploadFilename:fileName];
            
            // upload the updated content to the repository showing progress
            self.postProgressBar = [PostProgressBar createAndStartWithURL:putLink
                                                              andPostFile:putFile
                                                                 delegate:self
                                                                  message:NSLocalizedString(@"postprogressbar.update.document", @"Updating Document")
                                                              accountUUID:self.selectedAccountUUID
                                                            requestMethod:@"PUT"
                                                           suppressErrors:YES
                                                                graceTime:0.0f];
            [self.postProgressBar setSuppressErrors:YES];
            self.postProgressBar.fileData = [NSURL fileURLWithPath:self.documentTempPath];
        }
        else
        {
            [self presentSaveFailedAlert];
        }
    }
}

#pragma mark -
#pragma mark PostProgressBar delegate methods

- (void)post:(PostProgressBar *)bar completeWithData:(NSData *)data
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:self.objectId, @"objectId",
                              [bar repositoryItem], @"repositoryItem", 
                              [self documentTempPath], @"newPath", nil];
    [[NSNotificationCenter defaultCenter] postDocumentUpdatedNotificationWithUserInfo:userInfo];
    
    [self dismissViewControllerAnimated:YES completion:^{
        
        [self clearPasteBoard];
        [self.delegate editTextDocumentViewControllerDismissed];
    }];
}

- (void)post:(PostProgressBar *)bar failedWithData:(NSData *)data
{
    [self presentSaveFailedAlert];
}

- (void)presentSaveFailedAlert
{
    UIAlertView *saveFailed = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"edit-document.failed.title", @"Edit Document Save Failed Title")
                                                          message:NSLocalizedString(@"edit-document.savefailed.message", @"Edit Document Save Failed Message")
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"No", @"No")
                                                otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil
                                ] autorelease];
    [saveFailed setTag:kEditDocumentSaveConfirm];
    [saveFailed show];
}

- (void)textViewDidChange:(UITextView *)textView
{
    // If the document is originally empty there must be text
    // before we can save it
    if(!_documentIsEmpty || [textView.text isNotEmpty])
    {
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
    }
    else 
    {
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
    }
}

#pragma mark -
#pragma mark Responding to keyboard events

//From the Apple sample application KeyboardAccessory
//http://developer.apple.com/library/ios/#samplecode/KeyboardAccessory/Introduction/Intro.html#//apple_ref/doc/uid/DTS40009462
- (void)keyboardWillShow:(NSNotification *)notification 
{
    /*
     Reduce the size of the text view so that it's not obscured by the keyboard.
     Animate the resize so that it's in sync with the appearance of the keyboard.
     */
    
    NSDictionary *userInfo = [notification userInfo];
    
    // Get the origin of the keyboard when it's displayed.
    NSValue* aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    
    // Get the top of the keyboard as the y coordinate of its origin in self's view's coordinate system. The bottom of the text view's frame should align with the top of the keyboard's final position.
    CGRect keyboardRect = [aValue CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    
    CGFloat keyboardTop = keyboardRect.origin.y;
    CGRect newTextViewFrame = self.view.bounds;
    newTextViewFrame.size.height = keyboardTop - self.view.bounds.origin.y;
    
    // Get the duration of the animation.
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    // Animate the resize of the text view's frame in sync with the keyboard's appearance.
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    self.editView.frame = newTextViewFrame;
    
    [UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)notification 
{
    NSDictionary* userInfo = [notification userInfo];
    
    /*
     Restore the size of the text view (fill self's view).
     Animate the resize so that it's in sync with the disappearance of the keyboard.
     */
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    self.editView.frame = self.view.bounds;
    
    [UIView commitAnimations];
}

#pragma mark - UIAlertView delegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView tag] == kEditDocumentSaveConfirm && buttonIndex != [alertView cancelButtonIndex])
    {
        if ([[FileDownloadManager sharedInstance] downloadExistsForKey:self.documentName]) {
            UIAlertView *overwritePrompt = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"documentview.overwrite.download.prompt.title", @"")
                                                                       message:NSLocalizedString(@"documentview.overwrite.download.prompt.message", @"Yes/No Question")
                                                                      delegate:self 
                                                             cancelButtonTitle:NSLocalizedString(@"No", @"No") 
                                                             otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil] autorelease];
            
            [overwritePrompt setTag:kEditDocumentOverwriteConfirm];
            [overwritePrompt show];
        }
        else 
        {
            [self saveFileLocally];
        }
    }
    else if ([alertView tag] == kEditDocumentOverwriteConfirm && buttonIndex != [alertView cancelButtonIndex])
    {
        [self saveFileLocally];
    }
}

- (void)saveFileLocally 
{
    NSString *savedFile = [[FileDownloadManager sharedInstance] setDownload:self.fileMetadata.downloadInfo forKey:self.documentName withFilePath:[self.documentTempPath lastPathComponent]];
    [self dismissViewControllerAnimated:YES completion:^{
        [self displayContentsOfFileWithURL:[NSURL fileURLWithPath:[FileUtils pathToSavedFile:savedFile]]];
        displayInformationMessage(NSLocalizedString(@"documentview.download.confirmation.title", @"Document saved"));
        
        [self clearPasteBoard];
        [self.delegate editTextDocumentViewControllerDismissed];
    }];
}

- (void)displayContentsOfFileWithURL:(NSURL *)url
{
    NSString *incomingFilePath = [url path];
	NSString *incomingFileName = [[incomingFilePath pathComponents] lastObject];
    
    DocumentViewController *viewController = [[[DocumentViewController alloc]
                                               initWithNibName:kFDDocumentViewController_NibName bundle:[NSBundle mainBundle]] autorelease];
    
    NSString *filename = incomingFileName;
    AlfrescoAppDelegate *appDelegate = (AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [viewController setIsDownloaded:YES];
    
    // Ensure DownloadsViewController is either visible (iPad) or in the navigation stack (iPhone)
    UINavigationController *moreNavController = appDelegate.moreNavController;
    [moreNavController popToRootViewControllerAnimated:NO];
    
    MoreViewController *moreViewController = (MoreViewController *)moreNavController.topViewController;
    [moreViewController view]; // Ensure the controller's view is loaded
    [moreViewController showDownloadsViewWithSelectedFileURL:[NSURL fileURLWithPath:incomingFilePath]];
    [moreViewController showDownloadsView];
    [appDelegate.tabBarController setSelectedViewController:moreNavController];
    
    if (IS_IPAD)
    {
        [IpadSupport clearDetailController];
        [IpadSupport showMasterPopover];
    }
    
    NSData *fileData = [NSData dataWithContentsOfFile:incomingFilePath];
    [viewController setFileName:filename];
    [viewController setFileData:fileData];
    [viewController setFilePath:incomingFilePath];
    [viewController setHidesBottomBarWhenPushed:YES];
    
    UINavigationController *currentNavController = [appDelegate.tabBarController.viewControllers objectAtIndex:appDelegate.tabBarController.selectedIndex];
	[IpadSupport pushDetailController:viewController withNavigation:currentNavController andSender:self];
}

- (void)clearPasteBoard
{
    if (self.isRestrictedDocument)
    {
        UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
        [pasteBoard setValue:@"" forPasteboardType:UIPasteboardNameGeneral];
    }
    
}

#pragma mark - Notification Methods

- (void)handleWillResignActiveNotification:(NSNotification *)notification
{
    [self clearPasteBoard];
}

- (void)handleWillTerminateNotification:(NSNotification *)notification
{
    [self clearPasteBoard];
}

@end
