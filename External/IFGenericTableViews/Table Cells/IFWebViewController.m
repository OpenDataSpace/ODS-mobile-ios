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
//  IFWebViewController.m
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

