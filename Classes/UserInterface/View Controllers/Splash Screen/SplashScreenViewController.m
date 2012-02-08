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

#define IS_IPAD ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

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

    self.timer = [NSTimer scheduledTimerWithTimeInterval:kSplashScreenDisplayTime
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
    [self dismissModalViewControllerAnimated:YES];
}

@end
