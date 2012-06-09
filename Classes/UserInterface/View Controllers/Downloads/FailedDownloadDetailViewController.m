//
//  FailedDownloadDetailViewController.m
//  FreshDocs
//
//  Created by Mike Hatfield on 07/06/2012.
//  Copyright (c) 2012 . All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "FailedDownloadDetailViewController.h"
#import "DownloadInfo.h"
#import "DownloadManager.h"
#import "UIColor+Theme.h"
#import "UIImageUtils.h"

const CGFloat kFailedDownloadDetailPadding = 10.0f;

@interface FailedDownloadDetailViewController ()

@end

@implementation FailedDownloadDetailViewController

@synthesize downloadInfo = _downloadInfo;
@synthesize closeAction = _closeAction;
@synthesize closeTarget = _closeTarget;

- (void)dealloc
{
    [_downloadInfo release];
    
    [super dealloc];
}

- (id)initWithDownloadInfo:(DownloadInfo *)downloadInfo
{
    self = [super init];
    if (self)
    {
        [self setDownloadInfo:downloadInfo];
    }
    return self;
}

- (void)loadView
{
    [super loadView];

    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 250, 400)];
    [containerView setBackgroundColor:[UIColor clearColor]];
    
    CGFloat subViewWidth = 250 - (kFailedDownloadDetailPadding * 2);
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(kFailedDownloadDetailPadding, kFailedDownloadDetailPadding, subViewWidth, 0)];
    [titleLabel setFont:[UIFont boldSystemFontOfSize:20.0f]];
    [titleLabel setText:NSLocalizedString(@"download.failureDetail.title", @"Download Failed")];
    [titleLabel setTextAlignment:UITextAlignmentCenter];
    [titleLabel setTextColor:[UIColor whiteColor]];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    CGRect titleFrame = titleLabel.frame;
    titleFrame.size.height = [titleLabel sizeThatFits:CGSizeMake(subViewWidth, 400)].height;
    [titleLabel setFrame:titleFrame];
    [containerView addSubview:titleLabel];
    
    
    UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(kFailedDownloadDetailPadding, titleFrame.size.height + (kFailedDownloadDetailPadding * 2), subViewWidth, 0)];
    [descriptionLabel setFont:[UIFont systemFontOfSize:17.0f]];
    [descriptionLabel setNumberOfLines:0];
    [descriptionLabel setText:[self.downloadInfo.error localizedDescription]];
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
    UIColor *firstColor = [UIColor colorWithHexRed:92 green:97 blue:116 alphaTransparency:1.0f];
    UIColor *secondColor = [UIColor colorWithHexRed:3 green:13 blue:38 alphaTransparency:1.0f];
    [retryButton setBackgroundImage:[UIImage imageWithFirstColor:firstColor andSecondColor:secondColor] forState:UIControlStateNormal];
    CGRect retryButtonFrame = CGRectMake(kFailedDownloadDetailPadding, titleFrame.size.height + descriptionFrame.size.height + (kFailedDownloadDetailPadding * 3), subViewWidth, 40);
    [retryButton setFrame:retryButtonFrame];
    
    CALayer *layer = [retryButton layer];
    [layer setMasksToBounds:YES];
    [layer setCornerRadius:6.0f];
    [layer setBorderColor:[[UIColor colorWithHexRed:39 green:46 blue:63 alphaTransparency:1.0f] CGColor]];
    [layer setBorderWidth:2.0f];
    
    [retryButton addTarget:self action:@selector(retryButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [containerView addSubview:retryButton];
    
    CGRect containerFrame = containerView.frame;
    containerFrame.size.height = titleLabel.frame.size.height + descriptionLabel.frame.size.height + retryButton.frame.size.height + (kFailedDownloadDetailPadding * 4); 
    [containerView setFrame:containerFrame];
    [self setView:containerView];
    
    [titleLabel release];
    [descriptionLabel release];
    [containerView release];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

#pragma mark - Button Action

- (void)retryButtonAction:(id)sender
{
    [[DownloadManager sharedManager] retryDownload:self.downloadInfo.cmisObjectId];
    
    [self dismissModalViewControllerAnimated:YES];
}

@end
