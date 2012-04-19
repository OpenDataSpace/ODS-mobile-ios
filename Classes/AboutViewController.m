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
//  AboutViewController.m
//

#define IS_IPAD ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

#import "AboutViewController.h"
#import "Theme.h"
#import "ThemeProperties.h"
#import "AppProperties.h"
#import "UIColor+Theme.h"

@implementation AboutViewController
@synthesize buildTimeLabel;
@synthesize gradientView;
@synthesize aboutBorderedInfoView;
@synthesize aboutClientBorderedInfoView;
@synthesize scrollView;

- (void)dealloc {
	[buildTimeLabel release];
	[gradientView release];
	[aboutBorderedInfoView release];
    [aboutClientBorderedInfoView release];
    [scrollView release];
	
    [super dealloc];
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) { }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) { }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.buildTimeLabel = nil;
    self.gradientView = nil;
    self.aboutBorderedInfoView = nil;
    self.aboutClientBorderedInfoView = nil;
    self.scrollView = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [scrollView setContentSize:CGSizeMake(gradientView.frame.size.width, gradientView.frame.size.height)];

	[Theme setThemeForUINavigationBar:[[self navigationController] navigationBar]];
    BOOL useGradient = [[AppProperties propertyForKey:kAUseGradient] boolValue];
    
    if(useGradient) {
#if defined (TARGET_ALFRESCO)
        //    [self.buildTimeLabel setText:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
        
        [[self aboutClientBorderedInfoView] setStartColor:[UIColor colorWIthHexRed:38.0f green:38.0f blue:38.0f alphaTransparency:1.0f] 
                                               startPoint:CGPointMake(0.5f, 0.0f) 
                                                 endColor:[UIColor colorWIthHexRed:16.0f green:16.0f blue:16.0f alphaTransparency:1.0f] 
                                                 endPoint:CGPointMake(0.5f, 0.8f)];
        [[self aboutClientBorderedInfoView] setBorderColor:[UIColor colorWIthHexRed:61.0f green:61.0f blue:61.0f alphaTransparency:1.0f]];
        [[self aboutClientBorderedInfoView] setBorderWidth:2.5f];
        
        
        [[self aboutBorderedInfoView] setStartColor:[UIColor colorWIthHexRed:51.0f green:51.0f blue:51.0f alphaTransparency:1.0f] 
                                         startPoint:CGPointMake(0.5f, 0.0f) 
                                           endColor:[UIColor colorWIthHexRed:26.0f green:26.0f blue:26.0f alphaTransparency:1.0f] 
                                           endPoint:CGPointMake(0.5f, 0.8f)];
        [[self aboutBorderedInfoView] setBorderColor:[UIColor colorWIthHexRed:61.0f green:61.0f blue:61.0f alphaTransparency:1.0f]];
        [[self aboutBorderedInfoView] setBorderWidth:2.5f];
        
        [[self gradientView] setStartColor:[UIColor colorWIthHexRed:13.0f green:13.0f blue:13.0f alphaTransparency:1.0f] 
                                startPoint:CGPointMake(0.5f, 1.0f/3.0f) 
                                  endColor:[UIColor colorWIthHexRed:13.0f green:13.0f blue:13.0f alphaTransparency:1.0f] 
                                  endPoint:CGPointMake(0.5f, 1.0f)];	
#else

        UIColor *startColor;
        UIColor *endColor;
        
        if(IS_IPAD) {
            startColor = [UIColor ziaThemeSandColor];
            endColor = [UIColor blackColor];
        } else {
            startColor = [UIColor ziaThemeSandColor];
            endColor = [UIColor ziaThemeSandColor];
        }
        
        
        [[self aboutClientBorderedInfoView] setStartColor:[UIColor whiteColor] startPoint:CGPointMake(0.5f, 0.0f) 
                                                 endColor:[UIColor whiteColor] endPoint:CGPointMake(0.5f, 0.8f)];
        [[self aboutClientBorderedInfoView] setBorderColor:[UIColor blackColor]];
        [[self aboutClientBorderedInfoView] setBorderWidth:2.5f];
        
        
        [[self aboutBorderedInfoView] setStartColor:startColor startPoint:CGPointMake(0.5f, 0.0f) 
                                           endColor:endColor endPoint:CGPointMake(0.5f, 0.8f)];
        [[self aboutBorderedInfoView] setBorderColor:[UIColor blackColor]];
        [[self aboutBorderedInfoView] setBorderWidth:2.5f];
        [[self gradientView] setStartColor:[UIColor blackColor] startPoint:CGPointMake(0.5f, 1.0f/3.0f) 
                                  endColor:[ThemeProperties toolbarColor] endPoint:CGPointMake(0.5f, 1.0f)];
#endif
    }
    
#if defined (TARGET_ALFRESCO)
    NSString *buildTime = [[NSString alloc] initWithFormat:NSLocalizedString(@"about.build.date.time", @"Build: %s %s (%@.%@)"), __DATE__, __TIME__, 
                           [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                           [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
    [self.buildTimeLabel setText:buildTime];
    [buildTime release];

    // Build version check & watermark rendering
    [self renderWatermarkByMatchingBundleVersion:[AppProperties propertyForKey:@"watermarks"]];
#else
    [self.buildTimeLabel setText:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
#endif
}

- (void)renderWatermarkByMatchingBundleVersion:(NSArray *)watermarks
{
    NSString *bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    for (NSString *key in watermarks)
    {
        NSRange range = [bundleVersion rangeOfString:key];
        if (range.location != NSNotFound)
        {
            UILabel *qaLabel = [[UILabel alloc] initWithFrame:[self.view bounds]];
            [qaLabel setBackgroundColor:[UIColor clearColor]];
            [qaLabel setFont:[UIFont fontWithName:@"MarkerFelt-Thin" size:60.0]];
            [qaLabel setNumberOfLines:0];
            [qaLabel setShadowColor:[UIColor whiteColor]];
            [qaLabel setText:[NSString stringWithFormat:@"INTERNAL %@ BUILD", key]];
            [qaLabel setTextAlignment:UITextAlignmentCenter];
            [qaLabel setTextColor:[UIColor colorWithRed:1.0 green:0 blue:0 alpha:0.8]];
            [qaLabel setTransform:CGAffineTransformConcat(CGAffineTransformMakeRotation(M_PI_4), CGAffineTransformMakeTranslation(0.0, -60.0))];
            [qaLabel sizeToFit];
            [self.view addSubview:qaLabel];
            [qaLabel release];
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

    [gradientView setNeedsDisplay];
    [aboutBorderedInfoView setNeedsDisplay];
    [aboutClientBorderedInfoView setNeedsDisplay];
    return YES;
}

-(IBAction)buttonPressed:(id)sender {
	NSURL *url = [[NSURL alloc] initWithString: @"http://www.ziaconsulting.com"];
	[[UIApplication sharedApplication] openURL:url];
	[url release];
}

- (IBAction)clientButtonPressed:(id)sender {
    NSString *clientUrlStr = [AppProperties propertyForKey:kAClientUrl];
    
    if (clientUrlStr != nil) {
        NSURL *url = [[NSURL alloc] initWithString:clientUrlStr];
        [[UIApplication sharedApplication] openURL:url];
        [url release];
    }
}

@end
