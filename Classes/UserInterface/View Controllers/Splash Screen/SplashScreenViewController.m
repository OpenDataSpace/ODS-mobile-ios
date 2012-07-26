
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

@interface SplashScreenViewController ()
@property (retain) NSTimer *timer;

- (void)handleTap:(UIGestureRecognizer *)sender;
- (void)handleSplashScreenTimer;
@end

@implementation SplashScreenViewController
@synthesize splashImage = _splashImage;
@synthesize disclaimerTitleLabel = _dislaimerTitleLabel;
@synthesize disclaimerBodyLabel = _disclaimerBodyLabel;
@synthesize contentView = _contentView;

@synthesize timer = _timer;

#pragma mark - View lifecycle

- (void)dealloc
{
    AlfrescoAppDelegate *appDelegate = (AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate performSelectorOnMainThread:@selector(presentHomeScreenController) withObject:nil waitUntilDone:NO];

    [_timer release];
    [_splashImage release];
    [_dislaimerTitleLabel release];
    [_disclaimerBodyLabel release];
    [super dealloc];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    CGRect rect = CGRectMake(0, 0, 1024, 1024);
    gradient.frame = rect;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:56/255.0f green:56/255.0f blue:56/255.0f alpha:1.0]CGColor], (id)[[UIColor colorWithRed:0/255.0f green:0/255.0f blue:0/255.0f alpha:1.0]CGColor], nil];
    [self.view .layer addSublayer:gradient];
    
    [self.view addSubview:self.contentView];

    [self.disclaimerTitleLabel setText:NSLocalizedString(@"splashscreen.disclaimer.title", @"Disclaimer Title")];
    [self.disclaimerBodyLabel setText:NSLocalizedString(@"splashscreen.disclaimer.body", @"Disclaimer Body") ];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.view addGestureRecognizer:tap];
    [tap release];

    NSTimeInterval displayTime = [[AppProperties propertyForKey:kSplashscreenDisplayTimeKey] floatValue];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:displayTime
                                                  target:self
                                                selector:@selector(handleSplashScreenTimer)
                                                userInfo:nil
                                                 repeats:NO];    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return IS_IPAD;
}

#pragma mark -
#pragma mark Instance Methods

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

    AlfrescoAppDelegate *appDelegate = (AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate performSelectorOnMainThread:@selector(dismissModalViewController) withObject:nil waitUntilDone:NO];
}

- (void)viewDidUnload
{
    [self setSplashImage:nil];
    [self setDisclaimerTitleLabel:nil];
    [self setDisclaimerBodyLabel:nil];
    [super viewDidUnload];
}
@end
