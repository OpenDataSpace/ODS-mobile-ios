//
//  UIColor+Theme.m
//  FreshDocs
//
//  Created by Gi Hyun Lee on 10/1/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

#import "UIColor+Theme.h"


@implementation UIColor (Theme)

+ (UIColor *)colorWIthHexRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alphaTransparency:(CGFloat)alpha
{
	return [UIColor colorWithRed:(red/255.0) green:(green/255.0) blue:(blue/255.0) alpha:alpha];
}

+ (UIColor *)ziaThemeYellowColor
{
	return [UIColor colorWIthHexRed:255.0f green:209.0f blue:1.0f alphaTransparency:1.0f];
}

+ (UIColor *)ziaThemeRedColor
{
#if defined (TARGET_ALFRESCO)
    return [UIColor colorWIthHexRed:0.0f green:0.0f blue:0.0f alphaTransparency:1.0f];
#else
	return [UIColor colorWIthHexRed:119.0f green:33.0f blue:34.0f alphaTransparency:1.0f];
#endif
}

+ (UIColor *)ziaThemeOliveGreenColor
{
	return [UIColor colorWIthHexRed:103.0f green:101.0f blue:26.0f alphaTransparency:1.0f];	
}

+ (UIColor *)ziaThemeLightOliveGreenColor
{
	return [UIColor colorWIthHexRed:166.0f green:159.0f blue:78.0f alphaTransparency:1.0f];
}

+ (UIColor *)ziaThemeSandColor
{
	return [UIColor colorWIthHexRed:204.0f green:192.0f blue:144.0f alphaTransparency:1.0f];
}

@end
