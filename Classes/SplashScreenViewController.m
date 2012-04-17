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
 *
 * ***** END LICENSE BLOCK ***** */
//
//  SplashScreenViewController.m
//

#import "SplashScreenViewController.h"
#import "Constants.h"
#import "AlfrescoAppDelegate.h"
#import "AppProperties.h"

#define IS_IPAD ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
CGFloat const kDisclaimerTitleTop = 10;
CGFloat const kDisclaimerTitleFontSize = 16;
CGFloat const kDisclaimerBodyFontSize = 14;
CGFloat const kDisclaimerPadding = 5;

@interface SplashScreenViewController ()
- (void)handleTap:(UIGestureRecognizer *)sender;
- (void)handleSplashScreenTimer;
@end

@implementation SplashScreenViewController

@synthesize splashImage = _splashImage;
@synthesize timer = _timer;

#pragma mark - View lifecycle

- (void) dealloc
{
    [splashImage release];
    [timer release];

    [super dealloc];
}

- (void)loadView
{
    UIImageView *imageView = [[UIImageView alloc] initWithImage:self.splashImage];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    imageView.contentMode = UIViewContentModeCenter;
    
    CGSize disclaimerSize;
    if(IS_IPAD)
    {
        disclaimerSize = CGSizeMake(500, MAXFLOAT);
    }
    else 
    {
        disclaimerSize = CGSizeMake(250, MAXFLOAT);
    }
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [titleLabel setText:NSLocalizedString(@"splashscreen.disclaimer.title", @"Disclaimer Title")];
    [titleLabel setFont:[UIFont boldSystemFontOfSize:kDisclaimerTitleFontSize]];
    [titleLabel setTextColor:[UIColor whiteColor]];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    [titleLabel sizeToFit];
    [titleLabel setCenter:imageView.center];
    CGRect titleFrame = titleLabel.frame;
    titleFrame.origin.y = kDisclaimerTitleTop;
    [titleLabel setFrame:titleFrame];
    [titleLabel setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
    [imageView addSubview:titleLabel];
    [titleLabel release];
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    UILabel *bodyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [bodyLabel setText:NSLocalizedString(@"splashscreen.disclaimer.body", @"Disclaimer Body") ];
    [bodyLabel setFont:[UIFont systemFontOfSize:kDisclaimerBodyFontSize]];
    [bodyLabel setTextColor:[UIColor whiteColor]];
    [bodyLabel setBackgroundColor:[UIColor clearColor]];
    [bodyLabel setNumberOfLines:0];
    [bodyLabel setTextAlignment:UITextAlignmentCenter];
    CGSize bodySize = [bodyLabel sizeThatFits:disclaimerSize];
    // We need to center the body label in the x axis an position it after the title label in the y axis
    CGRect bodyFrame = bodyLabel.frame;
    bodyFrame.size.height = bodySize.height;
    bodyFrame.size.width = disclaimerSize.width - (kDisclaimerPadding * 2);
    bodyFrame.origin.y = kDisclaimerTitleTop + titleFrame.size.height + kDisclaimerPadding;
    bodyFrame.origin.x = (screenSize.width / 2) - (bodyFrame.size.width / 2);
    [bodyLabel setFrame:bodyFrame];
    [imageView addSubview:bodyLabel];
    [bodyLabel release];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    imageView.userInteractionEnabled = YES;
    [imageView addGestureRecognizer:tap];
    [tap release];
    
    self.view = imageView;
    [imageView release];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];

    NSTimeInterval displayTime = [[AppProperties propertyForKey:kSplashscreenDisplayTimeKey] floatValue];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:displayTime
                                                  target:self
                                                selector:@selector(handleSplashScreenTimer)
                                                userInfo:nil
                                                 repeats:NO];    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark -
#pragma mark Splash screen handling

- (UIImage *)splashImage
{
    if (splashImage == nil)
    {
        if (IS_IPAD)
        {
            splashImage = [UIImage imageNamed:@"SplashScreen~ipad.png"];
        }
        else
        {
            splashImage = [UIImage imageNamed:@"SplashScreen.png"];
        }
    }
    return splashImage;
}

- (void)handleTap:(UIGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        [self.timer fire];
    }
}

- (void)handleSplashScreenTimer
{
    [self.timer invalidate];
    [self dismissModalViewControllerAnimated:NO];
    
    AlfrescoAppDelegate *appDelegate = (AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate performSelectorOnMainThread:@selector(presentHomeScreenController) withObject:nil waitUntilDone:NO];
}

@end
