//
//  DatePickerViewController.m
//  FreshDocs
//
//  Created by Tijs Rademakers on 24/08/2012.
//  Copyright (c) 2012 U001b. All rights reserved.
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
