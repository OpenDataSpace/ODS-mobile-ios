    //
//  MetaDataDatePicker.m
//  FreshDocs
//
//  Created by Michael Muller on 5/15/10.
//  Copyright 2010 Michael J Muller. All rights reserved.
//

#define HEIGHT 216

#import "MetaDataDatePicker.h"

@implementation MetaDataDatePicker

@synthesize datePicker;
@synthesize timePicker;

- (void)dealloc {
	[datePicker release];
	[timePicker release];
    [super dealloc];
}


 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		UIDatePicker *dp = [[UIDatePicker alloc] init];
        self.datePicker = dp;
		self.datePicker.datePickerMode = UIDatePickerModeDate;
		[self.view addSubview:self.datePicker];
		[dp release];
		
		UIDatePicker *tp = [[UIDatePicker alloc] init];
        self.datePicker = tp;
		self.datePicker.datePickerMode = UIDatePickerModeDate;
		[self.view addSubview:self.timePicker];
		[tp release];
		
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
	[self layout];
}

- (void)layout {
	int windowHeight = self.view.window.bounds.size.height; 
	int windowWidth = self.view.window.bounds.size.width; 
	int pickerWidth = windowWidth / 2;
	
	self.view.frame = CGRectMake(0, windowHeight - HEIGHT, windowWidth, HEIGHT);
	self.datePicker.frame = CGRectMake(0, 0, pickerWidth, HEIGHT);
	self.timePicker.frame = CGRectMake(pickerWidth+1, 0, pickerWidth, HEIGHT);
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

@end
