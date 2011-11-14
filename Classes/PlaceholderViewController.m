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
 * Portions created by the Initial Developer are Copyright (C) 2011
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  PlaceholderViewController.m
//

#import "PlaceholderViewController.h"
#import "Theme.h"
#import "Utility.h"
#import "GradientView.h"
#import "UIColor+Theme.h"
#import "ThemeProperties.h"

@implementation PlaceholderViewController

#pragma View Lifecycle
- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[Theme setThemeForUIViewController:self]; 
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
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"no-document-selected.png"]];
    
    NSInteger gradientWidth = gradientView.frame.size.width;
    NSInteger gradientHeight = gradientView.frame.size.height;
    NSInteger imageWidth = imageView.frame.size.width;
    NSInteger imageHeight = imageView.frame.size.height;
    CGRect imageFrame = CGRectMake(0, 0, imageWidth, imageHeight);
    
    //image is centered in the x axis
    imageFrame.origin.x = (int) ((gradientWidth / 2) - (imageWidth / 2));
    //image top is at one third the view height
    imageFrame.origin.y = (int) (gradientHeight / 3);
    imageView.frame = imageFrame;
    
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin);
    
    [self.view addSubview:imageView];
    [gradientView release];
    [imageView release];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

@end
