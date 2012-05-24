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
//  FailedUploadDetailViewController.m
//

#import <QuartzCore/QuartzCore.h>
#import "FailedUploadDetailViewController.h"
#import "UploadInfo.h"
#import "UIColor+Theme.h"
#import "UIImageUtils.h"
#import "UploadsManager.h"

const CGFloat kFailedUploadDetailPadding = 10.0f;

@interface FailedUploadDetailViewController ()

@end

@implementation FailedUploadDetailViewController
@synthesize uploadInfo = _uploadInfo;
@synthesize closeAction = _closeAction;
@synthesize closeTarget = _closeTarget;

- (void)dealloc
{
    [_uploadInfo release];
    [super dealloc];
}

- (id)initWithUploadInfo:(UploadInfo *)uploadInfo
{
    self = [super init];
    if(self)
    {
        [self setUploadInfo:uploadInfo];
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 250, 400)];
    //[containerView setAlpha:0.5f];
    [containerView setBackgroundColor:[UIColor clearColor]];
    
    CGFloat subViewWidth = 250 - (kFailedUploadDetailPadding * 2);
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(kFailedUploadDetailPadding, kFailedUploadDetailPadding, subViewWidth, 0)];
    [titleLabel setFont:[UIFont boldSystemFontOfSize:20.0f]];
    [titleLabel setText:NSLocalizedString(@"Upload Failed", @"")];
    [titleLabel setTextAlignment:UITextAlignmentCenter];
    [titleLabel setTextColor:[UIColor whiteColor]];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    CGRect titleFrame = titleLabel.frame;
    titleFrame.size.height = [titleLabel sizeThatFits:CGSizeMake(subViewWidth, 400)].height;
    [titleLabel setFrame:titleFrame];
    [containerView addSubview:titleLabel];
    
    
    UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(kFailedUploadDetailPadding, titleFrame.size.height + (kFailedUploadDetailPadding * 2), subViewWidth, 0)];
    [descriptionLabel setFont:[UIFont systemFontOfSize:17.0f]];
    [descriptionLabel setNumberOfLines:0];
    [descriptionLabel setText:[self.uploadInfo.error localizedDescription]];
    [descriptionLabel setTextAlignment:UITextAlignmentCenter];
    [descriptionLabel setTextColor:[UIColor whiteColor]];
    [descriptionLabel setBackgroundColor:[UIColor clearColor]];
    CGRect descriptionFrame = descriptionLabel.frame;
    descriptionFrame.size.height = [descriptionLabel sizeThatFits:CGSizeMake(subViewWidth, 400)].height;
    [descriptionLabel setFrame:descriptionFrame];
    [containerView addSubview:descriptionLabel];
    
    UIButton *retryButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [retryButton.titleLabel setFont:[UIFont boldSystemFontOfSize:17]];
    [retryButton setTitle:NSLocalizedString(@"Retry", @"Retry") forState:UIControlStateNormal];
    [retryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    UIColor *firstColor = [UIColor colorWIthHexRed:92 green:97 blue:116 alphaTransparency:1.0f];
    UIColor *secondColor = [UIColor colorWIthHexRed:3 green:13 blue:38 alphaTransparency:1.0f];
    [retryButton setBackgroundImage:[UIImage imageWithFirstColor:firstColor andSecondColor:secondColor] forState:UIControlStateNormal];
    CGRect retryButtonFrame = CGRectMake(kFailedUploadDetailPadding, titleFrame.size.height + descriptionFrame.size.height + (kFailedUploadDetailPadding * 3), subViewWidth, 40);
    [retryButton setFrame:retryButtonFrame];
    
    CALayer *layer = [retryButton layer];
    [layer setMasksToBounds:YES];
    [layer setCornerRadius:6.0f];
    [layer setBorderColor:[[UIColor colorWIthHexRed:39 green:46 blue:63 alphaTransparency:1.0f] CGColor]];
    [layer setBorderWidth:2.0f];
    
    [retryButton addTarget:self action:@selector(retryButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [containerView addSubview:retryButton];
    
    CGRect containerFrame = containerView.frame;
    containerFrame.size.height = titleLabel.frame.size.height + descriptionLabel.frame.size.height + retryButton.frame.size.height + (kFailedUploadDetailPadding * 4); 
    [containerView setFrame:containerFrame];
    [self setView:containerView];
    
    [titleLabel release];
    [descriptionLabel release];
    [containerView release];
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
    return YES;
}

#pragma mark - Close button action
- (void)retryButtonAction:(id)sender
{
    [[UploadsManager sharedManager] retryUpload:self.uploadInfo.uuid];
    if(self.closeTarget && [self.closeTarget respondsToSelector:self.closeAction])
    {
        [self.closeTarget performSelector:self.closeAction withObject:self];
    }
}

@end
