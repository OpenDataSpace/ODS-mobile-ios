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
//  HomeScreenViewController.m
//

#import <QuartzCore/QuartzCore.h>
#import "HomeScreenViewController.h"
#import "ImageTextButton.h"
#import "FDGenericTableViewController.h"

static inline UIColor * kHighlightColor() {
    return [UIColor grayColor];
}

static inline UIColor * kBackgroundColor() {
    return [UIColor blackColor];
}

@interface HomeScreenViewController ()

@end

@implementation HomeScreenViewController
@synthesize cloudSignupButton = _cloudSignupButton;
@synthesize addAccountButton = _addAccountButton;
@synthesize tryAlfrescoButton = _tryAlfrescoButton;

- (void)dealloc
{
    [_cloudSignupButton release];
    [_addAccountButton release];
    [_tryAlfrescoButton release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.cloudSignupButton.buttonLabel setText:@"Sign up for Alfresco Cloud"];
    [_addAccountButton.buttonLabel setText:@"I already have an account"];
    [_tryAlfrescoButton.buttonLabel setText:@"Try Alfresco..."];
}

- (void)highlightButton:(UIButton *)button
{
    button.layer.backgroundColor = [kHighlightColor() CGColor];
    [self performSelector:@selector(resetHighlight:) withObject:button afterDelay:0.2];
}

- (void)resetHighlight:(UIButton *)button
{
    button.layer.backgroundColor = [kBackgroundColor() CGColor];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (IBAction)cloudSignupButtonAction:(id)sender
{
    [self highlightButton:sender];
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"NewCloudAccountConfiguration" ofType:@"plist"];
    FDGenericTableViewController *viewController = [FDGenericTableViewController genericTableViewWithPlistPath:plistPath andTableViewStyle:UITableViewStyleGrouped];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [navController setModalPresentationStyle:UIModalPresentationFormSheet];
    [navController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    [self presentModalViewController:navController animated:YES];
    [navController release];
}

- (IBAction)addAccountButtonAction:(id)sender
{
    [self highlightButton:sender];
    NSLog(@"Add account button pressed");
}

- (IBAction)tryAlfrescoButtonAction:(id)sender
{
    [self highlightButton:sender];
    NSLog(@"Try Alfresco button pressed");
}

@end
