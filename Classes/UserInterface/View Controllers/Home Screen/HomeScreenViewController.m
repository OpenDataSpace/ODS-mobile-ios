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
#import "UIColor+Theme.h"
#import "GradientView.h"
#import "MoreViewController.h"

static inline UIColor * kHighlightColor() {
    return [UIColor grayColor];
}

static inline UIColor * kBackgroundColor() {
    return [UIColor clearColor];
}

@interface HomeScreenViewController ()

@end

@implementation HomeScreenViewController
@synthesize headerLabel = _headerLabel;
@synthesize cloudSignupButton = _cloudSignupButton;
@synthesize cloudSignupDescription = _cloudSignupDescription;
@synthesize addAccountButton = _addAccountButton;
@synthesize addAccountDescription = _addAccountDescription;
@synthesize scrollView = _scrollView;
@synthesize attributedFooterLabel = _attributedFooterLabel;
@synthesize backgroundGradientView = _backgroundGradientView;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [_cloudSignupButton release];
    [_addAccountButton release];
    [_scrollView release];
    [_attributedFooterLabel release];
    [_backgroundGradientView release];
    [_headerLabel release];
    [_cloudSignupDescription release];
    [_addAccountDescription release];
    [super dealloc];
}

- (void)viewDidUnload
{
    [self setHeaderLabel:nil];
    [self setCloudSignupDescription:nil];
    [self setAddAccountDescription:nil];
    [super viewDidUnload];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (self.scrollView)
    {
        [self.scrollView setContentSize:self.backgroundGradientView.frame.size];
    }
    
    [self.headerLabel setText:NSLocalizedString(@"homescreen.header", @"Let's get you started...")];
    [self.cloudSignupButton.buttonLabel setText:NSLocalizedString(@"homescreen.button.signup", @"Sign up for Alfresco Cloud")];
    [self.cloudSignupDescription setText:NSLocalizedString(@"homescreen.description.signup", @"New to Alfresco? ...")];
    [self.addAccountButton.buttonLabel setText:NSLocalizedString(@"homescreen.button.account", @"I already have an account")];
    [self.addAccountDescription setText:NSLocalizedString(@"homescreen.description.account", @"Choose this option...")];
    
    NSString *footerText = NSLocalizedString(@"homescreen.footer", @"If you want to...");
    NSString *footerTextRangeToLink = NSLocalizedString(@"homescreen.footer.textRangeToLink", @"Guides");
    [self.attributedFooterLabel setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin];
    [self.attributedFooterLabel setFont:[UIFont systemFontOfSize:(IS_IPAD ? 17.0f : 15.0f)]];
    [self.attributedFooterLabel setBackgroundColor:[UIColor clearColor]];
    UIColor *textColor = [UIColor colorWIthHexRed:201 green:204 blue:204 alphaTransparency:1];
    [self.attributedFooterLabel setTextColor:textColor];
    [self.attributedFooterLabel setDelegate:self];
    [self.attributedFooterLabel setTextAlignment:UITextAlignmentCenter];
    [self.attributedFooterLabel setVerticalAlignment:TTTAttributedLabelVerticalAlignmentTop];
    [self.attributedFooterLabel setLineBreakMode:UILineBreakModeWordWrap];
    [self.attributedFooterLabel setUserInteractionEnabled:YES];
    [self.attributedFooterLabel setNumberOfLines:0];
    [self.attributedFooterLabel setText:footerText];
    
    NSRange guideRange = [footerText rangeOfString:footerTextRangeToLink];
    if (guideRange.length > 0 && guideRange.location != NSNotFound)
    {
        UIColor *linkColor = [UIColor colorWIthHexRed:0 green:153 blue:255 alphaTransparency:1];
        NSMutableDictionary *mutableLinkAttributes = [NSMutableDictionary dictionary];
        [mutableLinkAttributes setValue:(id)[linkColor CGColor] forKey:(NSString*)kCTForegroundColorAttributeName];
        [self.attributedFooterLabel addLinkWithTextCheckingResult:[NSTextCheckingResult linkCheckingResultWithRange:guideRange URL:[NSURL URLWithString:nil]] attributes:mutableLinkAttributes];
    }
    
    [[self backgroundGradientView] setStartColor:[UIColor colorWIthHexRed:51.0f green:51.0f blue:51.0f alphaTransparency:1.0f]
                                           startPoint:CGPointMake(0.5f, 0.0f) 
                                             endColor:[UIColor colorWIthHexRed:13.0f green:13.0f blue:13.0f alphaTransparency:1.0f]
                                             endPoint:CGPointMake(0.5f, 0.8f)];
    
    [self.cloudSignupButton setBackgroundColor:[UIColor clearColor]];
    [self.addAccountButton setBackgroundColor:[UIColor clearColor]];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAppEntersBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

#pragma mark - Instance Methods

- (void)dismiss
{
    AlfrescoAppDelegate *appDelegate = (AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate dismissModalViewController];
}

#pragma mark - Highlighting the custom Button
- (void)highlightButton:(UIButton *)button
{
    button.layer.backgroundColor = [kHighlightColor() CGColor];
    [self performSelector:@selector(resetHighlight:) withObject:button afterDelay:0.2];
}

- (void)resetHighlight:(UIButton *)button
{
    button.layer.backgroundColor = [kBackgroundColor() CGColor];
}

#pragma mark - UIButton actions
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

- (IBAction)closeButtonAction:(id)sender
{
    [self dismiss];
    [[FDKeychainUserDefaults standardUserDefaults] setBool:NO forKey:@"ShowHomescreen"];
    [[FDKeychainUserDefaults standardUserDefaults] synchronize];
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
    [self dismiss];
    [[FDKeychainUserDefaults standardUserDefaults] setBool:NO forKey:@"ShowHomescreen"];
    [[FDKeychainUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postLastAccountDetailsNotification:nil];
}

#pragma mark - TTTAttributedLabelDelegate methods
- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    [self dismiss];

    AlfrescoAppDelegate *appDelegate = (AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate];
    UINavigationController *moreNavController = appDelegate.moreNavController;
    [moreNavController popToRootViewControllerAnimated:NO];

    MoreViewController *moreViewController = (MoreViewController *)moreNavController.topViewController;
    [moreViewController view]; // Ensure the controller's view is loaded
    [moreViewController showHelpView];
    [appDelegate.tabBarController setSelectedViewController:moreNavController];
    
    if (IS_IPAD)
    {
        // When in portrait orientation, show the master view controller to guide the user
        if (self.interfaceOrientation == UIInterfaceOrientationPortrait || self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
        {
            [appDelegate.splitViewController showMasterPopover:nil];
        }
    }

    [[FDKeychainUserDefaults standardUserDefaults] setBool:NO forKey:@"ShowHomescreen"];
    [[FDKeychainUserDefaults standardUserDefaults] synchronize];
}

// We need to dismiss the homescreen if we enter the background to avoid a weird bug
// were the more tab is blank after dismissing the homescreen
- (void)handleAppEntersBackground:(NSNotification *)notification
{
    [self dismiss];
}

@end
