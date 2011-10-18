//
//  IFTextAreaViewController.h
//  FreshDocs
//
//  Created by Gi Hyun Lee on 7/23/11.
//  Copyright 2011 Zia Consulting. All rights reserved.
//

#import "IFTextAreaViewController.h"

@implementation IFTextAreaViewController
@synthesize textArea;
@synthesize key;
@synthesize model;
@synthesize placeholder;
@synthesize isRequired;

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
	
	[textArea release];
	[key release];
	[model release];
	[placeholder release];
	
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

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
	
	NSString *storedText = [model objectForKey:key];
	if (storedText) {
		[textView setText:storedText];
	}
	
	UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" 
																   style:UIBarButtonSystemItemCancel
																  target:self 
																  action:@selector(cancelButtonPressed)];
	[[self navigationItem] setLeftBarButtonItem:cancelButton];
	[cancelButton release];
	

	UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" 
																   style:UIBarButtonItemStyleDone 
																  target:self 
																  action:@selector(saveAndExit)];
	[[self navigationItem] setRightBarButtonItem:saveButton];
	if (isRequired) {
		[saveButton setEnabled:[textArea hasText]];
	}
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

#pragma mark Action Methods
- (void)cancelButtonPressed
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)saveAndExit
{
	NSString *userInput = ([textArea hasText] ? [textArea text] : nil);
	[model setObject:userInput forKey:key];
	[self.navigationController popViewControllerAnimated:YES];
}



#pragma mark -
#pragma mark UITextView Delegate Methods
- (void)textViewDidChange:(UITextView *)textView
{
	if (isRequired) {
		[[self.navigationItem rightBarButtonItem] setEnabled:[textView hasText]];
	}
}

@end
