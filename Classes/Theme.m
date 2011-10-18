//
//  Theme.m
//  FreshDocs
//
//  Created by Gi Hyun Lee on 10/1/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

#import "Theme.h"
#import "AlfrescoAppDelegate.h"
#import "FixedBackgroundWithRotatingLogoView.h"


@implementation Theme

+ (void)setThemeForUINavigationBar:(UINavigationBar *)navBar
{
	[navBar setTintColor:[UIColor ziaThemeRedColor]];
}

+ (void)setThemeForUIViewController:(UIViewController *)viewController
{
	[Theme setThemeForUINavigationBar:[[viewController navigationController] navigationBar]];
	[[viewController view] setBackgroundColor:[UIColor clearColor]];
}

+ (void)setThemeForUITableViewController:(UITableViewController *)tableViewController
{
	[Theme setThemeForUINavigationBar:[[tableViewController navigationController] navigationBar]];
	[[tableViewController view] setBackgroundColor:[UIColor clearColor]];
}

@end
