//
//  LicencesViewController.m
//  FreshDocs
//
//  Created by Mohamad Saeedi on 27/07/2012.
//  Copyright (c) 2012 . All rights reserved.
//

#import "LicencesViewController.h"

@interface LicencesViewController ()

@end

@implementation LicencesViewController

@synthesize package = _package;
@synthesize details = _details;


- (id)init
{
    if (IS_IPAD) {
        
        self = [super initWithNibName:@"LicencesViewController-iPad" bundle:nil];
    }
    else {
        
        self = [super initWithNibName:@"LicencesViewController" bundle:nil];
    }
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self.view setBackgroundColor:[UIColor colorWithRed:222/255.0 green:225/255.0 blue:230/255.0 alpha:1.0]];
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

-(void) showLicenceFor:(NSString*)pack
{
    self.package.text = pack;
    
    NSString* path = [[NSBundle mainBundle] pathForResource:pack ofType:@"txt"];
    
    self.details.text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
}

@end
