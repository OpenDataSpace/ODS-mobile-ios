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

#import "FailedUploadDetailViewController.h"
#import "UploadInfo.h"

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
    [containerView setBackgroundColor:[UIColor whiteColor]];
    
    CGFloat subViewWidth = 250 - (kFailedUploadDetailPadding * 2);
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(kFailedUploadDetailPadding, kFailedUploadDetailPadding, subViewWidth, 0)];
    [titleLabel setFont:[UIFont boldSystemFontOfSize:20.0f]];
    [titleLabel setText:NSLocalizedString(@"Upload Failed", @"")];
    [titleLabel setTextAlignment:UITextAlignmentCenter];
    CGRect titleFrame = titleLabel.frame;
    titleFrame.size.height = [titleLabel sizeThatFits:CGSizeMake(subViewWidth, 400)].height;
    [titleLabel setFrame:titleFrame];
    [containerView addSubview:titleLabel];
    
    
    UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(kFailedUploadDetailPadding, titleFrame.size.height + (kFailedUploadDetailPadding * 2), subViewWidth, 0)];
    [descriptionLabel setFont:[UIFont systemFontOfSize:17.0f]];
    [descriptionLabel setNumberOfLines:0];
    [descriptionLabel setText:[self.uploadInfo.error localizedDescription]];
    [descriptionLabel setTextAlignment:UITextAlignmentCenter];
    CGRect descriptionFrame = descriptionLabel.frame;
    descriptionFrame.size.height = [descriptionLabel sizeThatFits:CGSizeMake(subViewWidth, 400)].height;
    [descriptionLabel setFrame:descriptionFrame];
    [containerView addSubview:descriptionLabel];
    
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [closeButton setTitle:NSLocalizedString(@"Close", @"Close") forState:UIControlStateNormal];
    [closeButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    CGRect closeButtonFrame = CGRectMake(kFailedUploadDetailPadding, titleFrame.size.height + descriptionFrame.size.height + (kFailedUploadDetailPadding * 3), subViewWidth, 30);
    [closeButton setFrame:closeButtonFrame];
    [closeButton addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [containerView addSubview:closeButton];
    
    CGRect containerFrame = containerView.frame;
    containerFrame.size.height = titleLabel.frame.size.height + descriptionLabel.frame.size.height + closeButton.frame.size.height + (kFailedUploadDetailPadding * 4); 
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
- (void)closeButtonAction:(id)sender
{
    if(self.closeTarget && [self.closeTarget respondsToSelector:self.closeAction])
    {
        [self.closeTarget performSelector:self.closeAction withObject:self];
    }
}

@end
