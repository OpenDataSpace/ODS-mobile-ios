//
//  UIColor+Theme.h
//  FreshDocs
//
//  Created by Gi Hyun Lee on 10/1/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UIColor (Theme)

+ (UIColor *)colorWIthHexRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alphaTransparency:(CGFloat)alpha;
+ (UIColor *)ziaThemeYellowColor;
+ (UIColor *)ziaThemeRedColor;
+ (UIColor *)ziaThemeOliveGreenColor;
+ (UIColor *)ziaThemeLightOliveGreenColor;
+ (UIColor *)ziaThemeSandColor;

@end
