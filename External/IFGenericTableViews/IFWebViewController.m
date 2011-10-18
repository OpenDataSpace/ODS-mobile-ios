//
//  IFWebViewController.m
//  XpenserUtility
//
//  Created by Bindu Wavell on 1/13/10.
//  Copyright 2010 City and County of Denver. All rights reserved.
//

#import "IFWebViewController.h"

@implementation IFWebViewController
@synthesize request;
@synthesize webView;
@synthesize backgroundColor;

- (void)dealloc {
    [webView release];
	[backgroundColor release];
    [super dealloc];
}

- (void)loadView
{
    UIView *theView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.view = theView;
    [theView release];
}

- (void)viewWillAppear:(BOOL)animated
{
	CGRect f = [[self view] frame];
	UIWebView *theWebView = [[UIWebView alloc] initWithFrame:f];
	self.webView = theWebView;
	[theWebView loadRequest:request];
	[theWebView setScalesPageToFit:YES];
	[theWebView release];
	[self.view addSubview:theWebView];
    
	if (nil != backgroundColor) {
		self.view.backgroundColor = backgroundColor;
	} else {
		self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
	}
	
	NSString *safariLabel = NSLocalizedString(@"Safari",@"Label for button that opens web pages in Safari");
	UIBarButtonItem *safari = [[UIBarButtonItem alloc] initWithTitle:safariLabel style:UIBarButtonItemStyleDone target:self action:@selector(openInSafari:)];
	self.navigationItem.rightBarButtonItem = safari;
	[safari release];
	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
	CGRect f = [[self view] frame];
	self.webView.frame = f;
}

- (IBAction)openInSafari:(id)sender
{
	[[UIApplication sharedApplication] openURL:[request URL]];
}

@end

