//
//  AboutViewController.m
//  Alfresco
//
//  Created by Michael Muller on 10/2/09.
//  Copyright 2009 Zia Consulting. All rights reserved.
//

#define IS_IPAD ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

#import "AboutViewController.h"
#import "Theme.h"
#import "UIColor+Theme.h"

@implementation AboutViewController
@synthesize buildTimeLabel;
@synthesize gradientView;
@synthesize aboutBorderedInfoView;
@synthesize aboutClientBorderedInfoView;

- (void)dealloc {
	[buildTimeLabel release];
	[gradientView release];
	[aboutBorderedInfoView release];
    [aboutClientBorderedInfoView release];
	
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
}

- (void)viewDidLoad {
	[super viewDidLoad];

	[Theme setThemeForUINavigationBar:[[self navigationController] navigationBar]];
    
    NSString *buildTime;
    buildTime = [[NSString alloc] initWithFormat:@"Build Date: %s %s", __DATE__, __TIME__];
    
    [self.buildTimeLabel setText:buildTime];
	[buildTime release];
    
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
									   endColor:[UIColor ziaThemeRedColor] endPoint:CGPointMake(0.5f, 1.0f)];	
#endif
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

// TODO: EXTERNALIZE!!!
- (IBAction)clientButtonPressed:(id)sender {
    NSString *clientUrlStr = clientUrlStr = @"http://www.alfresco.com";

    if (clientUrlStr != nil) {
        NSURL *url = [[NSURL alloc] initWithString:clientUrlStr];
        [[UIApplication sharedApplication] openURL:url];
        [url release];
    }
}

@end
