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

@end

@implementation DatePickerViewController

@synthesize initializeWithDate = _initializeWithDate;
@synthesize delegate = _delegate;

- (id)initWithStyle:(UITableViewStyle)style andNSDate:(NSDate *)date
{
    self = [super initWithStyle:style];
    if (self) {
        self.initializeWithDate = date;
        self.tableView.dataSource = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [Theme setThemeForUITableViewController:self];
    
    [self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                              target:self
                                                                                              action:@selector(cancelEdit:)] autorelease]];
    
    [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                              target:self
                                                                                              action:@selector(done:)] autorelease]];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1)
    {
        return 260.0;
    }
    else 
    {
        return 54.0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (indexPath.section == 0)
    {
        static NSString *CellIdentifier = @"Cell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil)
        {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        }
        
        //Use NSDateFormatter to write out the date in a friendly format
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        df.dateStyle = NSDateFormatterMediumStyle;
        if (self.initializeWithDate)
        {
            cell.textLabel.text = [NSString stringWithFormat:@"%@", [df stringFromDate:self.initializeWithDate]];
        }
        else 
        {
            cell.textLabel.text = [NSString stringWithFormat:@"%@", [df stringFromDate:[NSDate date]]];
        }
        [df release];
    }
    else
    {
        static NSString *CellIdentifier = @"DatePickerCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil)
        {
            cell = [[[DatePickerViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        }
        
        if (self.initializeWithDate)
        {
            [((DatePickerViewCell *) cell).datePicker setDate:self.initializeWithDate];
        }
        [((DatePickerViewCell *) cell).datePicker addTarget:self
                            action:@selector(changeDateInLabel:)
                  forControlEvents:UIControlEventValueChanged];
    }
    
    return cell;
}

- (void)done:(id)sender
{
    if (self.delegate)
    {
        DatePickerViewCell *datePickerCell = (DatePickerViewCell *) [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
        [self.delegate datePicked:[datePickerCell.datePicker date]];
        self.delegate = nil;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)cancelEdit:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)changeDateInLabel:(id)sender{
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	df.dateStyle = NSDateFormatterMediumStyle;
    UIDatePicker *datePicker = (UIDatePicker *) sender;
    UITableViewCell *labelCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	labelCell.textLabel.text = [df stringFromDate:datePicker.date];
	[df release];
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
