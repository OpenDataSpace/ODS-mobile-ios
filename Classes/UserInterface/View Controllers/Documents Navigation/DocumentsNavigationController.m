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
//  DocumentsNavigationController.m
//

#import "DocumentsNavigationController.h"
#import "ProgressPanelView.h"
#import "UploadsManager.h"
#import "FileUtils.h"

CGFloat const kProgressPanelHeight = 55.0f;

@interface DocumentsNavigationController ()
@property (nonatomic, retain) ProgressPanelView *progressPanel;
- (void)positionProgressPanel;
- (void)showProgressPanel;
@end

@implementation DocumentsNavigationController
@synthesize progressPanel = _progressPanel;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadQueueChanged:) name:kNotificationUploadQueueChanged object:nil];
        
        CGRect navFrame = self.view.frame;
        //We position the view y outside the navigationView height
        ProgressPanelView *progressPanel = [[ProgressPanelView alloc] initWithFrame:CGRectMake(0, navFrame.size.height, navFrame.size.width, kProgressPanelHeight)];
        [progressPanel setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin];
        [progressPanel sizeToFit];
        [progressPanel.closeButton addTarget:self action:@selector(cancelUploadsAction:) forControlEvents:UIControlEventTouchUpInside];
        [self setProgressPanel:progressPanel];
        [self setDelegate:self];
        
        [progressPanel release];
        [self.view addSubview:self.progressPanel];
        _isProgressPanelHidden = YES;
    }
    return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    //[self.progressPanel setHidden:YES];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self resizeView:[[self.viewControllers lastObject] view]];
    //[self.progressPanel setHidden:NO];
    //[self positionProgressPanel];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)positionProgressPanel
{
    CGRect navFrame = self.view.frame;
    
    if(_isProgressPanelHidden)
    {
        [self.progressPanel setFrame:CGRectMake(0, navFrame.size.height, navFrame.size.width, kProgressPanelHeight)]; //We position the view after the end of the frame
    }
    else 
    {
        [self.progressPanel setFrame:CGRectMake(0, navFrame.size.height-kProgressPanelHeight, navFrame.size.width, kProgressPanelHeight)]; //We position the view at the right y
    }
}

- (void)showProgressPanel
{
    if(_isProgressPanelHidden)
    {
        _isProgressPanelHidden = NO;        
        [UIView beginAnimations:@"animateTableView" context:nil];
        [UIView setAnimationDuration:0.5];
        [self positionProgressPanel];
        [UIView commitAnimations];
        
        [self resizeView:[[self.viewControllers lastObject] view]];
        _GTMDevLog(@"viewWillAppear: Tableview frame %@", NSStringFromCGRect(self.view.frame));
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
    CGFloat statusBarHeight = [self statusBarFrameViewRect:self.view].size.height;
    CGFloat maxContentHeight = navFrame.size.height - self.navigationBar.frame.size.height - statusBarHeight;
    CGFloat viewHeight = view.frame.size.height;
    CGFloat deltaHeight = 0;
    
    //IF we are showing th progressPanel we need to reduce the height of the view
    if(!_isProgressPanelHidden && viewHeight >= maxContentHeight)
    {
        deltaHeight = -self.progressPanel.frame.size.height;
    }
    // If we are not we need to add the same height
    else if(_isProgressPanelHidden && viewHeight < maxContentHeight) 
    {
        deltaHeight = self.progressPanel.frame.size.height;
    }
   
    if(deltaHeight != 0)
    {
        CGRect containedFrame = view.frame;
        containedFrame.size.height += deltaHeight;
        
        [view setAutoresizesSubviews:YES];
        [view setFrame:containedFrame];
        [view setBounds:containedFrame];
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
     NSInteger operationCount = [[[UploadsManager sharedManager] uploadsQueue] operationCount];
    [self.progressPanel.progressBar setProgress:newProgress];
    float progressLeft = 1 - newProgress;
    float bytesLeft = (progressLeft * manager.uploadsQueue.totalBytesToUpload);
    bytesLeft = MAX(0, bytesLeft);
    
    NSString *leftToUpload = [FileUtils stringForLongFileSize:bytesLeft];
    [self.progressPanel.progressLabel setText:[NSString stringWithFormat:@"Uploading %d Items, %@ left", operationCount, leftToUpload]];
}

#pragma mark - Cancel button actions
- (void)cancelUploadsAction:(id)sender
{
    UIAlertView *confirmAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"uploads.cancelAll.title", @"Uploads") message:NSLocalizedString(@"uploads.cancelAll.body", @"Would you like to...") delegate:self cancelButtonTitle:NSLocalizedString(@"No", @"No") otherButtonTitles:(@"Yes", @"Yes"), nil] autorelease];
    
    [confirmAlert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex != alertView.cancelButtonIndex)
    {
        _GTMDevLog(@"Cancelling all active uploads!");
        [[UploadsManager sharedManager] cancelActiveUploads];
    }
}

#pragma mark - Notification handlers
- (void)uploadQueueChanged:(NSNotification *)notification
{
    NSArray *activeUploads = [[UploadsManager sharedManager] activeUploads];
    NSInteger operationCount = [[[UploadsManager sharedManager] uploadsQueue] operationCount];
    NSLog(@"Operation count %d", operationCount);
    
    if(operationCount > 0 && _isProgressPanelHidden)
    {
        [self.progressPanel.progressLabel setText:[NSString stringWithFormat:@"Uploading %d Items", [activeUploads count]]];
        [[UploadsManager sharedManager] setQueueProgressDelegate:self];
        [self showProgressPanel];
    }
    else if(operationCount == 0 && !_isProgressPanelHidden)
    {
        [self hideProgressPanel];
        [[UploadsManager sharedManager] setQueueProgressDelegate:nil];
    }
}

@end
