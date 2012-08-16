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
 *
 * ***** END LICENSE BLOCK ***** */
//
//  LicencesViewController.m
//

#import "LicencesViewController.h"

@implementation LicencesViewController

@synthesize package = _package;
@synthesize details = _details;

- (void)dealloc
{
    [_package release];
    [_details release];
    
    [super dealloc];
}

- (id)init
{
    self = [super initWithNibName:@"LicencesViewController" bundle:nil];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor colorWithRed:222/255.0 green:225/255.0 blue:230/255.0 alpha:1.0]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)showLicenceFor:(NSString *)pack
{
    [self.package setText:pack];
    
    NSString* path = [[NSBundle mainBundle] pathForResource:pack ofType:@"txt"];
    [self.details setText:[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil]];
}

@end
