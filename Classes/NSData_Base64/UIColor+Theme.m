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
//  UIColor+Theme.m
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
	
// FIXME: Temporary resolution to how to them the application
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
