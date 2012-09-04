//
//  TaskAssigneesViewController.m
//  FreshDocs
//
//  Created by Tijs Rademakers on 04/09/2012.
//  Copyright (c) 2012 U001b. All rights reserved.
//

#import "TaskAssigneesViewController.h"

@interface TaskAssigneesViewController ()

@end

@implementation TaskAssigneesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
