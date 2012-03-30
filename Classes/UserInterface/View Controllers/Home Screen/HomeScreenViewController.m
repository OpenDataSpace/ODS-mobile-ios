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
#import "NewCloudAccountViewController.h"
#import "AlfrescoAppDelegate.h"
#import "NSNotificationCenter+CustomNotification.h"

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
@synthesize scrollView = _scrollView;

- (void)dealloc
{
    [_cloudSignupButton release];
    [_addAccountButton release];
    [_tryAlfrescoButton release];
    [_scrollView release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if(self.scrollView)
    {
        [self.scrollView setContentSize:CGSizeMake(320, 600)];
    }
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
    NewCloudAccountViewController *viewController = [NewCloudAccountViewController genericTableViewWithPlistPath:plistPath andTableViewStyle:UITableViewStyleGrouped];
    [viewController setDelegate:self];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [navController setModalPresentationStyle:UIModalPresentationFormSheet];
    [navController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    [self presentModalViewController:navController animated:YES];
    [navController release];
}

- (IBAction)addAccountButtonAction:(id)sender
{
    [self highlightButton:sender];
    AccountTypeViewController *newAccountController = [[AccountTypeViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [newAccountController setDelegate:self];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:newAccountController];
    
    [navController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    [navController setModalPresentationStyle:UIModalPresentationFormSheet];
    [self presentModalViewController:navController animated:YES];
    
    [navController release];
    [newAccountController release];
}

- (IBAction)tryAlfrescoButtonAction:(id)sender
{
    [self highlightButton:sender];
    NSLog(@"Try Alfresco button pressed");
    // We will dismiss the current modal view controller at this point the current modal is "self"
    [self dismissModalViewControllerAnimated:YES];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"ShowHomescreen"];
}

#pragma mark - AccountViewControllerDelegate methods
- (void)accountControllerDidCancel:(AccountViewController *)accountViewController
{
    // We will dismiss the current modal view controller, at this point is the Alfresco signup/Add account view Controllers
    [self dismissModalViewControllerAnimated:YES];
}

- (void)accountControllerDidFinishSaving:(AccountViewController *)accountViewController
{
    //TODO: Go to the account details
    AlfrescoAppDelegate *appDelegate = (AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate dismissHomeScreenController];
    [[NSNotificationCenter defaultCenter] postLastAccountDetailsNotification:nil];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"ShowHomescreen"];
}

@end
