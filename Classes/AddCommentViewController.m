//
//  ***** BEGIN LICENSE BLOCK *****
//  Version: MPL 1.1
//
//  The contents of this file are subject to the Mozilla Public License Version
//  1.1 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS" basis,
//  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
//  for the specific language governing rights and limitations under the
//  License.
//
//  The Original Code is the Alfresco Mobile App.
//  The Initial Developer of the Original Code is Zia Consulting, Inc.
//  Portions created by the Initial Developer are Copyright (C) 2011
//  the Initial Developer. All Rights Reserved.
//
//
//  ***** END LICENSE BLOCK *****
//
//
//  AddCommentViewController.m
//

#import "AddCommentViewController.h"
#import "CommentsHttpRequest.h"

@implementation AddCommentViewController
@synthesize textArea;
@synthesize commentText;
@synthesize placeholder;
@synthesize delegate;
@synthesize nodeRef;


#pragma mark -
#pragma mark Memory Management
- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
	
	[textArea release];
    [commentText release];
	[placeholder release];
    [nodeRef release];
	
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

#pragma mark Initialization
- (id)initWithNodeRef:(NodeRef *)aNodeRef
{
    self = [super init];
    if (self) {
        [self setNodeRef:aNodeRef];
    }
    return self;
}


#pragma mark -
#pragma mark View Life Cycle

- (void)viewDidUnload {
    [super viewDidUnload];
	
	self.textArea = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)loadView
{
	UIView *theView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	[theView setAutoresizesSubviews:YES];
	[theView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight)];
	[self setView:theView];
	[theView release];
}

- (void)viewDidLoad {
	CGRect textViewRect = self.view.frame;
	TextViewWithPlaceholder *textView = [[TextViewWithPlaceholder alloc] initWithFrame:textViewRect];
	[textView setAutoresizesSubviews:YES];
	[textView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight)];
	[textView setUserInteractionEnabled:YES];
	[textView setEditable:YES];
	[textView setDelegate:self];
	[textView setEnablesReturnKeyAutomatically:YES];
	[textView setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
	[textView setAutocorrectionType:UITextAutocorrectionTypeDefault];
	[textView setKeyboardType:UIKeyboardTypeDefault];
	[textView setReturnKeyType:UIReturnKeyDefault];
	[textView setPlaceholder:placeholder];
	[self setTextArea:textView];
	[[self view] addSubview:textView];
	[textView release];
    
    if (self.commentText) {
        [self.textArea setText:self.commentText];
    }
		
	UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"cancelButton", @"Cancel button text")
                                                                     style:UIBarButtonItemStyleBordered
                                                                    target:self 
                                                                    action:@selector(cancelButtonPressed)];
	[[self navigationItem] setLeftBarButtonItem:cancelButton];
	[cancelButton release];
	
    
	UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"comments.save.button", @"Comment Button Save") 
																   style:UIBarButtonItemStyleDone 
																  target:self 
																  action:@selector(saveCommentButtonPressed)];
	[[self navigationItem] setRightBarButtonItem:saveButton];
	[saveButton release];
	
	[self registerForKeyboardNotifications];
	
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[textArea becomeFirstResponder];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

#pragma mark -
#pragma mark Keyboard Event Handling
- (void)registerForKeyboardNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
	NSDictionary *userInfo = [notification userInfo];
	
	CGRect keyboardFrame;
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 30200
	CGRect kbEndFrame;
	[[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&kbEndFrame];
	keyboardFrame = [self.view convertRect:kbEndFrame toView:nil];
#else
	[[userInfo objectForKey:UIKeyboardBoundsUserInfoKey] getValue:&keyboardFrame];
#endif
	
    CGRect newFrame = [self.view frame];
	newFrame.size.height -= keyboardFrame.size.height;
	
    // Get the duration of the animation.
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    // Animate the resize of the text view's frame in sync with the keyboard's appearance.
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
	
	[self.textArea setFrame:newFrame];
    
    [UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)notification
{	
    NSDictionary* userInfo = [notification userInfo];
    
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    [self.textArea setFrame:[self.view frame]];
    
    [UIView commitAnimations];
}

#pragma mark Action Selectors
- (void)cancelButtonPressed
{
    NSLog(@"Comment Cancel Button Pressed");
    if (delegate && [delegate respondsToSelector:@selector(didCancelComment:)])
        [delegate didCancelComment];
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)saveCommentButtonPressed
{
    NSLog(@"Save button pressed");
    NSString *userInput = [textArea text];    
    CommentsHttpRequest *request = [CommentsHttpRequest CommentsHttpPostRequestForNodeRef:self.nodeRef comment:userInput];
    [request setDelegate:self];
    [request startAsynchronous];
}

- (void)saveAndExit
{
	NSString *userInput = ([textArea hasText] ? [textArea text] : nil);
    if (delegate && [delegate respondsToSelector:@selector(didSubmitComment:)])
        [delegate didSubmitComment:userInput];
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark ASIHttpRequestDelegate
-(void)requestFailed:(CommentsHttpRequest *)request
{
    NSLog(@"failed to post comment request failed");
    if ( [NSThread isMainThread] ) {
        UIAlertView *failureAlert = [[UIAlertView alloc] initWithTitle:@"" 
                                                               message:NSLocalizedString(@"Failed to add new comment, please try again", @"Failed to add new comment message")
                                                              delegate:nil 
                                                     cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel") 
                                                     otherButtonTitles:nil, nil];
        [failureAlert show];
        [failureAlert release];
    } else {
        [self performSelectorOnMainThread:@selector(requestFailed:) withObject:request waitUntilDone:NO];
    }
}

-(void)requestFinished:(CommentsHttpRequest *)request
{
    NSLog(@"comment post request finished");
    [self performSelectorOnMainThread:@selector(saveAndExit) withObject:nil waitUntilDone:NO];
}

@end
