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
#import "NSString+Utils.h"

@interface EditTextDocumentViewController ()

@end

@implementation EditTextDocumentViewController
@synthesize editView = _editView;
@synthesize documentPath = _documentPath;
@synthesize documentTempPath = _documentTempPath;
@synthesize objectId = _objectId;
@synthesize postProgressBar = _postProgressBar;
@synthesize documentName = _documentName;
@synthesize selectedAccountUUID = _selectedAccountUUID;
@synthesize tenantID = _tenantID;

- (void)dealloc
{
    [_editView release];
    [_documentPath release];
    [_documentTempPath release];
    [_objectId release];
    [_postProgressBar release];
    [_documentName release];
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
	NSString *content = [NSString stringWithContentsOfFile:self.documentPath encoding:NSUTF8StringEncoding error:&error];
    if(error)
    {
        NSLog(@"Cannot load document path %@ with error %@", self.documentPath, [error description]);
    }
    else 
    {
        [self.editView setText:content];
    }
    
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
    
    // Observe keyboard hide and show notifications to resize the text view appropriately.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [self setEditView:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)discardButtonAction:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)saveButtonAction:(id)sender
{
    //We save the file into a temporal file first, on the uploda success we update the original file
    [self setDocumentTempPath:[FileUtils pathToTempFile:[NSString generateUUID]]];
    //Update the local file with the current text
    NSError *error = nil;
    [[self.editView text] writeToFile:self.documentTempPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if(error)
    {
        NSLog(@"Cannot save document %@ with error %@", self.documentTempPath, [error description]);
        UIAlertView *saveFailed = [[[UIAlertView alloc] initWithTitle:@"Save Failed" message:@"Could not save" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil] autorelease];
        [saveFailed show];
        return;
    }
    // extract node id from object id
	NSString *fileName = [[self.documentPath pathComponents] lastObject];
    NSArray *idSplit = [self.objectId componentsSeparatedByString:@"/"];
    NSString *nodeId = [idSplit objectAtIndex:3];
    
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
    self.postProgressBar.fileData = [NSURL fileURLWithPath:self.documentTempPath];
}

#pragma mark -
#pragma mark PostProgressBar delegate methods

- (void)post:(PostProgressBar *)bar completeWithData:(NSData *)data
{
    //Updating the original file will cause a refresh in the DocumentViewController's webview
    NSError *error = nil;
    [[self.editView text] writeToFile:self.documentPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if(error)
    {
        NSLog(@"Cannot save document %@ with error %@", self.documentPath, [error description]);
    }
    [self dismissModalViewControllerAnimated:YES];
}

- (void)post:(PostProgressBar *)bar failedWithData:(NSData *)data
{
    UIAlertView *saveFailed = [[[UIAlertView alloc] initWithTitle:@"Save Failed" message:@"Could not save" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles:nil] autorelease];
    [saveFailed show];
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

@end
