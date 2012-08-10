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
#import "LicencesViewController.h"

@implementation AboutViewController
@synthesize buildTimeLabel = _buildTimeLabel;
@synthesize gradientView = _gradientView;
@synthesize aboutBorderedInfoView = _aboutBorderedInfoView;
@synthesize aboutClientBorderedInfoView = _aboutClientBorderedInfoView;
@synthesize scrollView = _scrollView;
@synthesize aboutText = _aboutText;
@synthesize librariesLabel = _librariesLabel;

- (void)dealloc
{
	[_buildTimeLabel release];
	[_gradientView release];
	[_aboutBorderedInfoView release];
    [_aboutClientBorderedInfoView release];
    [_scrollView release];
    [_aboutText release];
    [_librariesLabel release];
	
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
    
    [self.scrollView setContentSize:CGSizeMake(self.aboutBorderedInfoView.frame.size.width, self.gradientView.frame.size.height)];

	[Theme setThemeForUINavigationBar:[[self navigationController] navigationBar]];
    BOOL useGradient = [[AppProperties propertyForKey:kAUseGradient] boolValue];
    
    self.aboutText.text = NSLocalizedString(@"about.body", @"About Body");
    self.librariesLabel.text = NSLocalizedString(@"about.libraries", @"About Libraries");
    
    if(useGradient) {
#if defined (TARGET_ALFRESCO)
        //    [self.buildTimeLabel setText:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
        
        [[self aboutClientBorderedInfoView] setStartColor:[UIColor colorWithHexRed:38.0f green:38.0f blue:38.0f alphaTransparency:1.0f] 
                                               startPoint:CGPointMake(0.5f, 0.0f) 
                                                 endColor:[UIColor colorWithHexRed:16.0f green:16.0f blue:16.0f alphaTransparency:1.0f] 
                                                 endPoint:CGPointMake(0.5f, 0.8f)];
        [[self aboutClientBorderedInfoView] setBorderColor:[UIColor colorWithHexRed:61.0f green:61.0f blue:61.0f alphaTransparency:1.0f]];
        [[self aboutClientBorderedInfoView] setBorderWidth:2.5f];
        
        
        [[self aboutBorderedInfoView] setStartColor:[UIColor colorWithHexRed:38.0f green:38.0f blue:38.0f alphaTransparency:1.0f]
                                         startPoint:CGPointMake(0.5f, 0.0f) 
                                           endColor:[UIColor colorWithHexRed:16.0f green:16.0f blue:16.0f alphaTransparency:1.0f]
                                           endPoint:CGPointMake(0.5f, 0.8f)];
        [[self aboutBorderedInfoView] setBorderColor:[UIColor colorWithHexRed:61.0f green:61.0f blue:61.0f alphaTransparency:1.0f]];
        [[self aboutBorderedInfoView] setBorderWidth:2.5f];
        
        [[self gradientView] setStartColor:[UIColor colorWithHexRed:13.0f green:13.0f blue:13.0f alphaTransparency:1.0f] 
                                startPoint:CGPointMake(0.5f, 1.0f/3.0f) 
                                  endColor:[UIColor colorWithHexRed:13.0f green:13.0f blue:13.0f alphaTransparency:1.0f] 
                                  endPoint:CGPointMake(0.5f, 1.0f)];	
#else

        UIColor *startColor = [UIColor colorWithHexRed:130.0f green:135.0f blue:141.0f alphaTransparency:1.0f];
        UIColor *endColor = [UIColor colorWithHexRed:130.0f green:156.0f blue:163.0f alphaTransparency:1.0f];
        
        [[self aboutClientBorderedInfoView] setStartColor:[UIColor whiteColor] startPoint:CGPointMake(0.5f, 0.0f) 
                                                 endColor:[UIColor whiteColor] endPoint:CGPointMake(0.5f, 0.8f)];
        [[self aboutClientBorderedInfoView] setBorderColor:[UIColor blackColor]];
        [[self aboutClientBorderedInfoView] setBorderWidth:2.5f];
        
        
        [[self aboutBorderedInfoView] setStartColor:startColor startPoint:CGPointMake(0.5f, 0.0f) 
                                           endColor:endColor endPoint:CGPointMake(0.5f, 0.8f)];
        [[self aboutBorderedInfoView] setBorderColor:[UIColor redColor]];
        [[self aboutBorderedInfoView] setBorderWidth:2.5f];
        [[self aboutBorderedInfoView] setBorderWidth:2.5f];
        [[self gradientView] setStartColor:[UIColor colorWithHexRed:200.0f green:208.0f blue:217.0f alphaTransparency:1.0f] startPoint:CGPointMake(0.5f, 1.0f/3.0f) 
                                  endColor:[UIColor colorWithHexRed:250.0f green:250.0f blue:250.0f alphaTransparency:1.0f] endPoint:CGPointMake(0.5f, 1.0f)];
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

    [self.gradientView setNeedsDisplay];
    [self.aboutBorderedInfoView setNeedsDisplay];
    [self.aboutClientBorderedInfoView setNeedsDisplay];
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

- (IBAction)showLicence:(id)sender
{
    LicencesViewController *licence = [[LicencesViewController alloc] init];
    [self.navigationController pushViewController:licence animated:YES];
    [licence showLicenceFor:[[(UIButton*) sender titleLabel] text]];
    [licence release];
}

@end
