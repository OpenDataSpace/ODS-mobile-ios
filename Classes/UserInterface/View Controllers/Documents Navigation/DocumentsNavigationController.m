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

@interface DocumentsNavigationController ()
@property (nonatomic, retain) ProgressPanelView *progressPanel;

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
        ProgressPanelView *progressPanel = [[ProgressPanelView alloc] initWithFrame:CGRectMake(0, navFrame.size.height, navFrame.size.width, 55)];
        [progressPanel sizeToFit];
        [self setProgressPanel:progressPanel];
        [self setDelegate:self];
        
        [progressPanel release];
    }
    return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)showProgressPanel
{
    if(!self.progressPanel.superview)
    {
        [self.view addSubview:self.progressPanel];
        CGRect navFrame = self.view.frame;
        
        [UIView beginAnimations:@"animateTableView" context:nil];
        [UIView setAnimationDuration:0.5];
        [self.progressPanel setFrame:CGRectMake(0, navFrame.size.height-55, navFrame.size.width, 55)]; //We position the view at the right y
        [UIView commitAnimations];
        
        [self resizeView:[[self.viewControllers lastObject] view]];
        NSLog(@"viewWillAppear: Tableview frame %@", NSStringFromCGRect(self.view.frame));
    }
}

- (void)hideProgressPanel
{
    if(self.progressPanel.superview)
    {
        [UIView beginAnimations:@"animateTableView" context:nil];
        [UIView setAnimationDuration:0.5];
        [self.progressPanel removeFromSuperview];
        [self resizeView:[[self.viewControllers lastObject] view]];
        [UIView commitAnimations];
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
    if(self.progressPanel.superview && viewHeight >= maxContentHeight)
    {
        deltaHeight = -self.progressPanel.frame.size.height;
    }
    // If we are not we need to add the same height
    else if(!self.progressPanel.superview && viewHeight < maxContentHeight) 
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
    NSArray *activeUploads = [manager activeUploads];
    [self.progressPanel.progressBar setProgress:newProgress];
    float progressLeft = 1 - newProgress;
    NSString *leftToUpload = [FileUtils stringForLongFileSize:(progressLeft * manager.uploadsQueue.totalBytesToUpload)];
    [self.progressPanel.progressLabel setText:[NSString stringWithFormat:@"Uploading %d Items, %@ left", [activeUploads count], leftToUpload]];
}

#pragma mark - Notification handlers
- (void)uploadQueueChanged:(NSNotification *)notification
{
    NSArray *activeUploads = [[UploadsManager sharedManager] activeUploads];
    NSInteger operationCount = [[[UploadsManager sharedManager] uploadsQueue] operationCount];
    NSLog(@"Operation count %d", operationCount);
    
    if([activeUploads count] > 0 && !self.progressPanel.superview)
    {
        [self.progressPanel.progressLabel setText:[NSString stringWithFormat:@"Uploading %d Items", [activeUploads count]]];
        [[UploadsManager sharedManager] setQueueProgressDelegate:self];
        [self showProgressPanel];
    }
    else if([activeUploads count] == 0 && self.progressPanel.superview)
    {
        [self hideProgressPanel];
        [[UploadsManager sharedManager] setQueueProgressDelegate:nil];
    }
}

@end
