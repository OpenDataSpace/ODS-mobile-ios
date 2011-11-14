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
//  MetaDataDatePicker.m
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
