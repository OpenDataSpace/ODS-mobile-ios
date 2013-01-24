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

#import "AboutViewController.h"
#import "Theme.h"
#import "AppProperties.h"
#import "LicencesViewController.h"

@implementation AboutViewController
@synthesize buildTimeLabel = _buildTimeLabel;
@synthesize gradientView = _gradientView;
@synthesize aboutBorderedInfoView = _aboutBorderedInfoView;
@synthesize aboutClientBorderedInfoView = _aboutClientBorderedInfoView;
@synthesize scrollView = _scrollView;
@synthesize aboutText = _aboutText;
@synthesize librariesLabel = _librariesLabel;
@synthesize additionalLogoButton = _additionalLogoButton;

- (void)dealloc
{
	[_buildTimeLabel release];
	[_gradientView release];
	[_aboutBorderedInfoView release];
    [_aboutClientBorderedInfoView release];
    [_scrollView release];
    [_aboutText release];
    [_librariesLabel release];
    [_additionalLogoButton release];
	
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.scrollView setContentSize:CGSizeMake(self.aboutBorderedInfoView.frame.size.width, self.gradientView.frame.size.height)];

	[Theme setThemeForUINavigationBar:[[self navigationController] navigationBar]];
    BOOL useGradient = [[AppProperties propertyForKey:kAUseGradient] boolValue];
    
    self.aboutText.text = NSLocalizedString(@"about.body", @"About Body");
    self.librariesLabel.text = NSLocalizedString(@"about.libraries", @"About Libraries");
    
    if (useGradient)
    {
#if defined (TARGET_ALFRESCO)
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
        
        [self listExternalLibraries:[AppProperties propertyForKey:kALicenses]];
    }
    
#if defined (TARGET_ALFRESCO)
    NSString *buildTime = [NSString stringWithFormat:NSLocalizedString(@"about.build.date.time", @"Build: %s %s (%@.%@)"), __DATE__, __TIME__,
                           [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                           [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
    [self.buildTimeLabel setText:buildTime];

    // Additional Logo image - set here to ensure it's localized
    [self.additionalLogoButton.imageView setImage:[UIImage imageNamed:@"zia-partner-logo.png"]];
#else
    [self.buildTimeLabel setText:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
#endif
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    [self.gradientView setNeedsDisplay];
    [self.aboutBorderedInfoView setNeedsDisplay];
    [self.aboutClientBorderedInfoView setNeedsDisplay];
    return YES;
}

- (IBAction)buttonPressed:(id)sender
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://www.ziaconsulting.com"]];
}

- (IBAction)clientButtonPressed:(id)sender
{
    NSString *clientUrlStr = [AppProperties propertyForKey:kAClientUrl];
    if (clientUrlStr != nil)
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:clientUrlStr]];
    }
}

- (void)showLicence:(id)sender
{
    LicencesViewController *licencesViewController = [[LicencesViewController alloc] init];
    [self.navigationController pushViewController:licencesViewController animated:YES];
    [licencesViewController showLicenceForComponent:[[(UIButton *)sender titleLabel] text]];
    [licencesViewController release];
}
- (void)listExternalLibraries:(NSArray *)libraries
{
    // Variable declarations use iPad defaults
    int columnCount = 3;
    
    CGFloat height = 22.0, width = 192.0;
    CGFloat leftMargin = 28.0, topMargin = 48.0;
    CGFloat horizontalSpace = 20.0, verticalSpace = 8.0;
    CGFloat fontSize = 15.0;
    
    if (!IS_IPAD)
    {
        // Override defaults for non-iPad platforms
        columnCount = 2;
        
        height = 18.0;
        width = 147.0;
        
        leftMargin = 12.0;
        topMargin = 62.0;
        horizontalSpace = 2.0;
        verticalSpace = 5.0;
        fontSize = 11.0;
    }

    CGFloat x = leftMargin, y = topMargin;
    long index = 0;
    
    for (NSString *library in libraries)
    {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(x, y, width, height)];
        [button setTitle:[libraries objectAtIndex:index] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont boldSystemFontOfSize:fontSize];
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [button addTarget:self action:@selector(showLicence:) forControlEvents:UIControlEventTouchUpInside];
        [self.aboutBorderedInfoView addSubview:button];
        [button release];

        if ((++index % columnCount) == 0)
        {
            x = leftMargin;
            y += height + verticalSpace;
        }
        else
        {
            x += width + horizontalSpace;
        }
    }
}

@end
