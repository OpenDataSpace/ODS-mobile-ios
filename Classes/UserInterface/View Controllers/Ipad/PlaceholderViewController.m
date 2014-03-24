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
//  PlaceholderViewController.m
//
#import "UIImageView+WebCache.h"
#import "PlaceholderViewController.h"
#import "Theme.h"
#import "GradientView.h"
#import "ThemeProperties.h"
#import "AlfrescoAppDelegate.h"
#import "LogoManager.h"

static BOOL launchViewPresented = NO;

@interface PlaceholderViewController() {
    UIImageView     *noDocImgView_;
}
@end

@implementation PlaceholderViewController

#pragma View Lifecycle
- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[Theme setThemeForUIViewController:self]; 
    
    if (IS_IPAD && !launchViewPresented)
    {
        // We have to call the helper method from here because this is the point where we want to present the controller.
        // Trying to present before this point the initial orientation of the screen will be always portrait
        AlfrescoAppDelegate *appDelegate = (AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate];
        if (YES == [appDelegate shouldPresentSplashScreen])
        {
            [appDelegate presentSplashScreenController];
        }
        else
        {
            [appDelegate presentHomeScreenController];
        }
    }
    
    // We set the static variable to YES since this method can be trigger while using the app
    // we only want to show the launch views the first time we enter this method
    launchViewPresented = YES;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

    GradientView *gradientView = [[GradientView alloc] initWithFrame:self.view.frame];
    UIColor *startColor = [ThemeProperties ipadDetailGradientStartColor];
    UIColor *endColor = [ThemeProperties ipadDetailGradientEndColor];
    
    [gradientView setStartColor:startColor
                                           startPoint:CGPointMake(0.5f, 0.0f) 
                                             endColor:endColor 
                                             endPoint:CGPointMake(0.5f,1.0f)];
    
    self.view = gradientView;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    UIView *noDocView = [[UIView alloc] init];
    noDocImgView_ = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"no-document-selected.png"]];
    
    NSInteger gradientWidth = gradientView.frame.size.width;
    NSInteger gradientHeight = gradientView.frame.size.height;
    NSInteger imageWidth = self.view.frame.size.width - 40;
    NSInteger imageHeight = noDocImgView_.frame.size.height + 40;
    CGRect noDocViewFrame = CGRectMake(0, 0, imageWidth, imageHeight);
    
    //image is centered in the x axis
    noDocViewFrame.origin.x = (int) ((gradientWidth / 2) - (imageWidth / 2));
    //image top is at one third the view height
    noDocViewFrame.origin.y = (int) (gradientHeight / 3);
    noDocView.frame = noDocViewFrame;
    
    // Aligning imageview to center of noDocView
    CGRect imageViewFrame = noDocImgView_.frame;
    imageViewFrame.origin.x = (noDocView.frame.size.width - noDocImgView_.frame.size.width) / 2;
    noDocImgView_.frame = imageViewFrame;
    
    //loading no doc image from server
    [noDocImgView_ setImageWithURL:[[LogoManager shareManager] getLogoURLByName:kLogoNoDocumentSelected] placeholderImage:[UIImage imageNamed:kLogoNoDocumentSelected]];
    
    UILabel *noDocText = [[UILabel alloc] initWithFrame:CGRectMake(0, noDocImgView_.frame.size.height, noDocView.frame.size.width, 40)];
    noDocText.backgroundColor = [UIColor clearColor];
    noDocText.textAlignment = UITextAlignmentCenter;
    noDocText.textColor = [UIColor colorWithRed:152/255.0 green:152/255.0 blue:152/255.0 alpha:1.0];
    noDocText.font = [UIFont boldSystemFontOfSize:18];
    noDocText.text = NSLocalizedString(@"no.document.selected.text", @"NO Document Selected");
    
    noDocImgView_.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin);
    
    noDocView.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin);
    
    [noDocView addSubview:noDocImgView_];
    [noDocView addSubview:noDocText];
    
    [self.view addSubview:noDocView];
    
    [gradientView release];
    [noDocView release];
    [noDocText release];
    
    //set notification for update logo
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:kNotificationUpdateLogos object:nil];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [noDocImgView_ release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark Handle Notification

- (void) handleNotification:(NSNotification*) noti {
    if ([noti.name isEqualToString:kNotificationUpdateLogos]) {
        [noDocImgView_ setImageWithURL:[[LogoManager shareManager] getLogoURLByName:kLogoNoDocumentSelected] placeholderImage:[UIImage imageNamed:kLogoNoDocumentSelected]];
    }
}
@end
