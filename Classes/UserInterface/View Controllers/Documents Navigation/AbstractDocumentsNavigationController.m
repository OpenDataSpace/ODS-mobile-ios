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
//  AbstractDocumentsNavigationController.m
//

#import "AbstractDocumentsNavigationController.h"


CGFloat const kProgressPanelHeight = 55.0f;
CGFloat const kWhitePadding = 0.0f;

@interface AbstractDocumentsNavigationController ()
@end

@interface AbstractDocumentsNavigationController ()

@end

@implementation AbstractDocumentsNavigationController
@synthesize progressPanel = _progressPanel;
@synthesize failurePanel = _failurePanel;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_progressPanel release];
    [_failurePanel release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadQueueChanged:) name:kNotificationUploadQueueChanged object:nil];
        
        //Previously the code in viewDidLoad was here but that caused a 20px white space at the top of the navigation controller view
        _isProgressPanelHidden = YES;
        _isFailurePanelHidden = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    CGRect navFrame = self.view.bounds;
    //We position the view y outside the navigationView height
    ProgressPanelView *progressPanel = [[ProgressPanelView alloc] initWithFrame:CGRectMake(0, navFrame.size.height, navFrame.size.width, kProgressPanelHeight)];
    [progressPanel setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin];
    [progressPanel sizeToFit];
    [progressPanel.closeButton addTarget:self action:@selector(cancelUploadsAction:) forControlEvents:UIControlEventTouchUpInside];
    [self setProgressPanel:progressPanel];
    [self setDelegate:self];
    [progressPanel release];
    
    FailurePanelView *failurePanel = [[FailurePanelView alloc] initWithFrame:CGRectMake(0, navFrame.size.height, navFrame.size.width, 0)]; //Height will be generated
    [failurePanel setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin];
    [failurePanel addTarget:self action:@selector(failedUploadsAction:) forControlEvents:UIControlEventTouchUpInside];
    [self setFailurePanel:failurePanel];
    [failurePanel release];
    
    [self.view addSubview:self.progressPanel];
    [self.view addSubview:self.failurePanel];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self resizeView:[[self.viewControllers lastObject] view]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateFailedUploads];
    [self updateTabItemBadge];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self resizeView:[[self.viewControllers lastObject] view]];
}

#pragma mark - Progress panel
- (void)positionProgressPanel
{
    CGRect navFrame = self.view.frame;
    CGFloat posY = navFrame.size.height; // Hidden position is at the end of the navFrame y position
    if(!_isProgressPanelHidden)
    {
        if(!_isFailurePanelHidden)
        {
            // If the failure panel is not hidden we need to move this panel to the top of the failure panel
            posY -= self.failurePanel.frame.size.height + kWhitePadding;
            
        }
        // Showing position is at the bottom of the navFrame
        posY -= kProgressPanelHeight + kWhitePadding; 
    }
    
    //This method can be called to reposition the progress panel, so we have to check if it's currently in the right Y postion
    if(self.progressPanel.frame.origin.y != posY)
    {
        [self.progressPanel setFrame:CGRectMake(0, posY, navFrame.size.width, kProgressPanelHeight)]; //We position the view after the end of the frame
    }
}

- (void)showProgressPanel
{
    if(_isProgressPanelHidden && !_externalHidden)
    {
        _isProgressPanelHidden = NO;        
        [UIView beginAnimations:@"animateProgressPanelShow" context:nil];
        [UIView setAnimationDuration:0.5];
        [self positionProgressPanel];
        [UIView commitAnimations];
        
        [self resizeView:[[self.viewControllers lastObject] view]];
        alfrescoLog(AlfrescoLogLevelTrace, @"viewWillAppear: Tableview frame %@", NSStringFromCGRect(self.view.frame));
    }
}

- (void)hideProgressPanel
{
    if(!_isProgressPanelHidden)
    {
        _isProgressPanelHidden = YES;        
        //Animate resize
        [UIView beginAnimations:@"animateProgressPanelHide" context:nil];
        [UIView setAnimationDuration:0.5];
        [self positionProgressPanel];
        [UIView commitAnimations];
        
        [self resizeView:[[self.viewControllers lastObject] view]];
    }
}

#pragma mark - Failure panel
- (void)positionFailurePanel
{
    CGRect navFrame = self.view.frame;
    
    if(_isFailurePanelHidden)
    {
        [self.failurePanel setFrame:CGRectMake(0, navFrame.size.height, navFrame.size.width, self.failurePanel.frame.size.height)]; //We position the view after the end of the frame
    }
    else 
    {
        [self.failurePanel setFrame:CGRectMake(0, navFrame.size.height-self.failurePanel.frame.size.height-kWhitePadding, navFrame.size.width, self.failurePanel.frame.size.height)]; //We position the view at the right y minus a white padding
    }
    //We need to reposition the progress panel in case the failure eithers
    [self positionProgressPanel];
}

- (void)showFailurePanel
{
    if(_isFailurePanelHidden && !_externalHidden)
    {
        _isFailurePanelHidden = NO;        
        [UIView beginAnimations:@"animateFailurePanelShow" context:nil];
        [UIView setAnimationDuration:0.5];
        [self positionFailurePanel];
        [UIView commitAnimations];
        
        [self resizeView:[[self.viewControllers lastObject] view]];
    }
}

- (void)hideFailurePanel
{
    if(!_isFailurePanelHidden)
    {
        _isFailurePanelHidden = YES;        
        //Animate resize
        [UIView beginAnimations:@"animateFailurePanelHide" context:nil];
        [UIView setAnimationDuration:0.5];
        [self positionFailurePanel];
        [UIView commitAnimations];
        
        [self resizeView:[[self.viewControllers lastObject] view]];
    }
}

#pragma mark - Resizing the current view
//http://stackoverflow.com/questions/3888517/get-iphone-status-bar-height
- (CGRect)statusBarFrameViewRect:(UIView*)view 
{
    CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
    CGRect statusBarWindowRect = [view.window convertRect:statusBarFrame fromWindow: nil];
    CGRect statusBarViewRect = [view convertRect:statusBarWindowRect fromView: nil];
    
    return statusBarViewRect;
}

- (void)resizeView:(UIView *)view
{
    CGRect navFrame = self.view.frame;
    CGFloat maxContentHeight = navFrame.size.height;
    maxContentHeight -= [self isNavigationBarHidden] ? 0 : self.navigationBar.frame.size.height;
    if(!IS_IPAD)
    {
        // For some reason only in iphone, the 20px space of the status bar is included in the height of the
        // navigation view
        // TODO: check why this is happening? maybe is not the status bar the extra 20px?
        CGFloat statusBarHeight = [self statusBarFrameViewRect:self.view].size.height;
        maxContentHeight -= statusBarHeight;
    }
    CGFloat deltaHeight = 0;
    
    //IF we are showing th progressPanel we need to reduce the height of the view
    if(!_isProgressPanelHidden)
    {
        deltaHeight -= self.progressPanel.frame.size.height + kWhitePadding;
    }
    
    if(!_isFailurePanelHidden)
    {
        deltaHeight -= self.failurePanel.frame.size.height + kWhitePadding;
    }
    
    CGRect containedFrame = view.frame;
    
    
    if(containedFrame.size.height != maxContentHeight + deltaHeight)
    {
        containedFrame.size.height = maxContentHeight + deltaHeight;
        [view setAutoresizesSubviews:YES];
        [view setFrame:containedFrame];
    }
    
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self resizeView:viewController.view];
}

#pragma mark - ASIProgressDelegate
- (void)setProgress:(float)newProgress
{
    UploadsManager *manager = [UploadsManager sharedManager];
    NSInteger operationCount = [[[UploadsManager sharedManager] activeUploads] count];
    [self.progressPanel.progressBar setProgress:newProgress];
    float progressLeft = 1 - newProgress;
    float bytesLeft = (progressLeft * manager.uploadsQueue.totalBytesToUpload);
    bytesLeft = MAX(0, bytesLeft);
    
    NSString *leftToUpload = [FileUtils stringForLongFileSize:bytesLeft];
    NSString *itemText = [self itemText:operationCount];
    [self.progressPanel.progressLabel setText:[NSString stringWithFormat:NSLocalizedString(@"uploads.progress.label", @"Uploading %d %@, %@ left"), operationCount, itemText, leftToUpload]];
}

#pragma mark - Button actions
- (void)cancelUploadsAction:(id)sender
{
    [[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"uploads.cancelAll.title", @"Uploads")
                                 message:NSLocalizedString(@"uploads.cancelAll.body", @"Would you like to...")
                                delegate:self
                       cancelButtonTitle:NSLocalizedString(@"No", @"No")
                       otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil] autorelease] show];
}

- (void)failedUploadsAction:(id)sender
{
    AlfrescoAppDelegate *appDelegate = (AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    FailedUploadsViewController *failedUploads = [[FailedUploadsViewController alloc] initWithFailedUploads:[[UploadsManager sharedManager] failedUploads]];
    failedUploads.viewType = FailedUploadsViewTypeUploads;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:failedUploads];
    [navController setModalPresentationStyle:UIModalPresentationFormSheet];
    [navController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    //Have to use the app delegate since it seems to be a bug when presenting from a popover
    //and no black overlay was added behind the presented view controller
    [appDelegate presentModalViewController:navController animated:YES];
    [failedUploads release];
    [navController release];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 0 && buttonIndex != alertView.cancelButtonIndex)
    {
        alfrescoLog(AlfrescoLogLevelTrace, @"Cancelling all active uploads!");
        [[UploadsManager sharedManager] cancelActiveUploads];
    }
    
    if(alertView.tag == 1 && buttonIndex != alertView.cancelButtonIndex)
    {
        NSArray *failedUploads = [[UploadsManager sharedManager] failedUploads];
        NSMutableArray *failedUUIDs = [NSMutableArray arrayWithCapacity:[failedUploads count]];
        for(UploadInfo *uploadInfo in failedUploads)
        {
            [failedUUIDs addObject:uploadInfo.uuid];
        }
        
        alfrescoLog(AlfrescoLogLevelTrace, @"Clearing all failed uploads!");
        [[UploadsManager sharedManager] clearUploads:failedUUIDs];
    }
}

#pragma mark - Util methods
- (NSString *)itemText:(NSInteger)itemsCount
{
    return itemsCount == 1 ? NSLocalizedString(@"uploads.items.singular", @"item") : NSLocalizedString(@"uploads.items.plural", @"items");
}

- (void)updateTabItemBadge
{
    NSArray *failedUploads = [[UploadsManager sharedManager] failedUploads];
    NSInteger activeCount = [[[UploadsManager sharedManager] activeUploads] count];
    if([failedUploads count] > 0)
    {
        [self.tabBarItem setBadgeValue:@"!"];
    }
    else if (activeCount > 0)
    {
        [self.tabBarItem setBadgeValue:[NSString stringWithFormat:@"%d", activeCount]];
    }
    else 
    {
        [self.tabBarItem setBadgeValue:nil];
    }
    
    
}

#pragma mark - Public methods
- (void)showPanels
{
    // We don't always want to show the panels in this stage
    // a simulated state change is triggered for both progress and failed
    // uploads
    _externalHidden = NO;
    [self updateFailedUploads];
    [self uploadQueueChanged:nil];
}

- (void)hidePanels
{
    _externalHidden = YES;
    [self hideFailurePanel];
    [self hideProgressPanel];
}

#pragma mark - Notification handlers
- (void)updateFailedUploads
{
    NSArray *failedUploads = [[UploadsManager sharedManager] failedUploads];
    if([failedUploads count] > 0)
    {
        NSString *itemText = [self itemText:[failedUploads count]];
        [self.failurePanel.badge autoBadgeSizeWithString:@"!"];
        [self.failurePanel.badge setNeedsDisplay];
        [self.failurePanel.failureLabel setText:[NSString stringWithFormat:NSLocalizedString(@"uploads.failed.label", @"%d %@ failed to upload"), [failedUploads count], itemText]];
        [self showFailurePanel];
    }
    else 
    {
        [self hideFailurePanel];
    }
}

- (void)uploadQueueChanged:(NSNotification *)notification
{
    NSArray *activeUploads = [[UploadsManager sharedManager] activeUploads];
    NSInteger operationCount = [activeUploads count];
    NSLog(@"Operation count %d", operationCount);
    
    //This may be called from a background thread
    //making sure the UI updates are performed in the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        if(operationCount > 0 && _isProgressPanelHidden)
        {
            NSString *itemText = [self itemText:[activeUploads count]];
            [self.progressPanel.progressLabel setText:[NSString stringWithFormat:NSLocalizedString(@"uploads.progress.label", @"Uploading %d %@, %@ left"), [activeUploads count], itemText, @"0"]];
            [[UploadsManager sharedManager] setQueueProgressDelegate:self];
            [self showProgressPanel];
        }
        else if(operationCount == 0 && !_isProgressPanelHidden)
        {
            [self hideProgressPanel];
            [[UploadsManager sharedManager] setQueueProgressDelegate:nil];
        }
        
        [self updateFailedUploads];
        [self updateTabItemBadge];
    });
}
@end
