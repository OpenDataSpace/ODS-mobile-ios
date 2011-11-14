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
 * Portions created by the Initial Developer are Copyright (C) 2011
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  IFDateViewController.m
//

#import "IFDateViewController.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
#define IS_IPAD ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
#endif

@implementation IFDateViewController
@synthesize datePicker;
@synthesize model;
@synthesize key;
@synthesize datePickerMode;
@synthesize backgroundColor;

- (void)dealloc {
    [datePicker release];
    [model release];
    [key release];
	[backgroundColor release];
    [super dealloc];
}

- (IBAction)dateChanged
{
	[model setObject:[datePicker date] forKey:key];
}

- (void)loadView
{
    UIView *theView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.view = theView;
    [theView release];
}

- (void)viewWillAppear:(BOOL)animated
{
	CGFloat cw = 320.0f;
	CGFloat ch = 216.0f;
	CGRect  frame;
	
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	if (IS_IPAD) {
		frame = CGRectMake(0, -1, cw, ch);
	} else
#endif
	{
		CGRect f = [[self view] frame];
		frame = CGRectMake((f.size.width / 2.0f) - (cw / 2.0f), (f.size.height / 2.0f) - (ch / 2.0f), cw, ch);
	}
		
	UIDatePicker *theDatePicker = [[UIDatePicker alloc] initWithFrame:frame];
	self.datePicker = theDatePicker;
	[theDatePicker setDate:[model objectForKey:key]];
	[theDatePicker setDatePickerMode:datePickerMode];
	[theDatePicker release];
    [datePicker addTarget:self action:@selector(dateChanged) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:datePicker];
    
	if (nil != backgroundColor) {
		self.view.backgroundColor = backgroundColor;
	} else {
		self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	if (IS_IPAD) {
	} else
#endif
	{
		CGFloat cw = 320.0f;
		CGFloat ch = 216.0f;
		CGRect f = [[self view] frame];
		CGRect frame = [[self datePicker] frame];
		frame.origin.x = (f.size.width / 2.0f) - (cw / 2.0f);
		frame.origin.y = (f.size.height / 2.0f) - (ch / 2.0f);
		self.datePicker.frame = frame;
	}
}

@end

