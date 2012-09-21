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
//  DetailsPlaceholderViewController.m
//

#import "DetailNavigationController.h"
#import "Theme.h"
#import "ThemeProperties.h"
#import "PlaceholderViewController.h"
#import "IpadSupport.h"

@interface DetailNavigationController ()
@property (nonatomic, retain, readwrite) UIViewController *detailViewController;
@property (nonatomic, retain) UIViewController *fullScreenModalController;
- (void)configureView;
@end

@implementation DetailNavigationController

@synthesize detailViewController = _detailViewController;
@synthesize fullScreenModalController = _fullScreenModalController;
@synthesize popoverButtonTitle = _popoverButtonTitle;
@synthesize masterPopoverBarButton = _masterPopoverBarButton;
@synthesize masterPopoverController = _masterPopoverController;
@synthesize expandButton = _expandButton;
@synthesize closeButton = _closeButton;
@synthesize splitViewController = _splitViewController;

static BOOL isExpanded = NO;
static CGFloat masterViewControllerWidth = 320.0;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_detailViewController release];
    [_fullScreenModalController release];
    [_popoverButtonTitle release];
    [_masterPopoverBarButton release];
    [_masterPopoverController release];
    [_expandButton release];
    [_closeButton release];
    [_splitViewController release];
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.title = NSLocalizedString(@"Detail", @"Detail");

        self.expandButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"expand"]
                                                              style:UIBarButtonItemStylePlain
                                                             target:self action:@selector(performAction:)] autorelease];

        self.closeButton = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"Close")
                                                              style:UIBarButtonItemStylePlain
                                                             target:self action:@selector(performCloseAction:)] autorelease];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBrowseDocuments:) name:kBrowseDocumentsNotification object:nil];
    }
    return self;
}

- (id)initWithRootViewController:(UIViewController *)rootViewController
{
    self.detailViewController = rootViewController;
    return [super initWithRootViewController:rootViewController];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configureView];
}

#pragma mark - Managing the detail item

- (void)resetViewControllerStackWithNewTopViewController:(UIViewController *)newTopViewController dismissPopover:(BOOL)dismissPopover
{
    if (self.detailViewController != newTopViewController) 
    {
        [self setViewControllers:nil animated:NO];
        [self setDetailViewController:newTopViewController];
        
        // Update the view.
        [self configureView];
    }
    
    if (dismissPopover)
    {
        [self dismissPopover];
    }
}

- (void)addViewControllerToStack:(UIViewController *)newTopViewController
{
    [self setViewControllers:nil animated:NO];
    [self setFullScreenModalController:newTopViewController];
    
    [self configureView];
    
    [self dismissPopover];
}

- (void)dismissPopover
{
    if (self.masterPopoverController && self.masterPopoverController.popoverVisible)
    {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
}

- (void)configureView
{
    // Update the user interface for the detail item.
    if (self.detailViewController)
    {
        NSLog(@"Detail View Controller title: %@", self.detailViewController.title);
        
        if (self.fullScreenModalController)
        {
            [self setViewControllers:[NSArray arrayWithObjects:self.detailViewController, self.fullScreenModalController, nil]];
        }
        else 
        {
            [self setViewControllers:[NSArray arrayWithObject:self.detailViewController]];
        }
 
        if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
        {
            [self.detailViewController.navigationItem setLeftBarButtonItem:self.expandButton animated:NO];
        }
        else
        {
            [self.detailViewController.navigationItem setLeftBarButtonItem:self.masterPopoverBarButton animated:NO];
        }
    }
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"popover.button.title", @"Alfresco");
    UIViewController *current = [self.viewControllers objectAtIndex:0];
    [current.navigationItem setLeftBarButtonItem:barButtonItem animated:NO];

    self.masterPopoverBarButton = barButtonItem;
    self.masterPopoverController = popoverController;
    self.splitViewController = splitController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    [self.expandButton setImage:[UIImage imageNamed:@"expand"]];

    UIViewController *current = [self.viewControllers objectAtIndex:0];
    [current.navigationItem setLeftBarButtonItem:self.expandButton animated:NO];

    self.masterPopoverController = nil;
    isExpanded = NO;
}

- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation
{
    return (UIInterfaceOrientationIsPortrait(orientation) || hideMasterAlways);
}

- (void)performAction:(id)sender
{
    [self expandDetailView:!isExpanded animated:YES];
}

- (void)expandDetailView:(BOOL)expanded animated:(BOOL)animated
{
    if (expanded == isExpanded || UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
    {
        return;
    }
    
    UIViewController *masterViewController = [self.splitViewController.viewControllers objectAtIndex:0];
    UIViewController *detailViewController = [self.splitViewController.viewControllers objectAtIndex:1];
    
    CGRect splitFrame = self.splitViewController.view.frame;
    CGRect masterFrame = masterViewController.view.frame;
    CGRect detailFrame = detailViewController.view.frame;
    
    CGFloat delta = isExpanded ? -masterViewControllerWidth : masterViewControllerWidth;
    
    if (self.interfaceOrientation == UIDeviceOrientationLandscapeLeft)
    {
        splitFrame.origin.y -= delta;
    }
    splitFrame.size.height += delta;
    masterFrame.origin.x -= delta;
    detailFrame.size.width += delta;
    
    if (animated)
    {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.3f];
    }
    self.splitViewController.view.frame = splitFrame;
    masterViewController.view.frame = masterFrame;
    detailViewController.view.frame = detailFrame;
    
    if (animated)
    {
        [UIView commitAnimations];
    }
    
    isExpanded = !isExpanded;

    UIViewController *current = [self.viewControllers objectAtIndex:0];
    [current.navigationItem.leftBarButtonItem setImage:[UIImage imageNamed:(isExpanded ? @"collapse" : @"expand")]];
}

- (void)showFullScreen
{
    [self expandDetailView:YES animated:NO];
}

// Shows the view controller on top of an existing view controller
- (void)showFullScreenOnTopWithCloseButtonTitle:(NSString *)closeButtonTitle
{
    self.closeButton.title = closeButtonTitle;

    UIViewController *current = [self.viewControllers objectAtIndex:1];
    [current.navigationItem setLeftBarButtonItem:self.closeButton];
    
    previousExpandedState = isExpanded;
    [self expandDetailView:YES animated:NO];
    hideMasterAlways = YES;
}

- (void)performCloseAction:(id)sender
{
    [self setViewControllers:[NSArray arrayWithObject:self.detailViewController] animated:NO];
    self.fullScreenModalController = nil;
    [self configureView];

    // restore defaults
    [self expandDetailView:previousExpandedState animated:NO];
    hideMasterAlways = NO;
}

- (void)showMasterPopoverController
{
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) && self.masterPopoverController && self.masterPopoverBarButton)
    {
        [self.masterPopoverBarButton.target performSelector:self.masterPopoverBarButton.action];
    }
}

#pragma mark - NotificationCenter methods

- (void)handleBrowseDocuments:(NSNotification *)notification
{
    [IpadSupport clearDetailController];
    [self showMasterPopoverController];
}

@end
