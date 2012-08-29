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
//  DatePickerViewController.m
//

#import "DatePickerViewController.h"
#import "Theme.h"
#import "DatePickerViewCell.h"

@interface DatePickerViewController ()

@property (nonatomic, retain) NSDate *initializeWithDate;
@property (nonatomic, retain) UIDatePicker *datePicker;

@end

@implementation DatePickerViewController

@synthesize initializeWithDate = _initializeWithDate;
@synthesize datePicker = _datePicker;
@synthesize delegate = _delegate;

- (id)initWithNSDate:(NSDate *)date
{
    self = [super init];
    if (self) {
        self.initializeWithDate = date;
    }
    return self;
}

- (void)dealloc
{
    [_initializeWithDate release];
    [_datePicker release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [Theme setThemeForUIViewController:self];
    
    [self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                              target:self
                                                                                              action:@selector(cancelEdit:)] autorelease]];
    
    [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                              target:self
                                                                                              action:@selector(done:)] autorelease]];
    
    if (IS_IPAD)
    {
        self.datePicker = [[[UIDatePicker alloc] initWithFrame:CGRectMake(0, 0, 540, 250)] autorelease];
    }
    else 
    {
        self.datePicker = [[[UIDatePicker alloc] initWithFrame:CGRectMake(0, 0, 325, 250)] autorelease];
    }
    self.datePicker.datePickerMode = UIDatePickerModeDate;
    self.datePicker.hidden = NO;
    if (self.initializeWithDate)
    {
        self.datePicker.date = self.initializeWithDate;
    }
    else 
    {
        self.datePicker.date = [NSDate date];
    }
    [self.view addSubview:self.datePicker];
}

- (void)done:(id)sender
{
    if (self.delegate)
    {
        [self.delegate datePicked:[self.datePicker date]];
        self.delegate = nil;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)cancelEdit:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
