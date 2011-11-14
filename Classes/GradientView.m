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
//  GradientView.m
//

#import <QuartzCore/QuartzCore.h>
#import "GradientView.h"
#import "UIColor+Theme.h"


@implementation GradientView
@synthesize startPoint;
@synthesize endPoint;
@synthesize startColor;
@synthesize endColor;
@synthesize borderColor;
@synthesize borderWidth;
@synthesize gradientLayer;

- (void)dealloc
{
	[startColor release];
	[endColor release];
	[borderColor release];
	[gradientLayer release];
	[super dealloc];
}

- (id)initWithStartColor:(UIColor *)sColor endColor:(UIColor *)eColor
{
	if ((self = [super init])) {
		[self setOpaque:YES];
		[self setBackgroundColor:[UIColor whiteColor]];
		
		[self setStartColor:sColor];
		[self setEndColor:eColor];
		[self setBorderWidth:0.0f];
		[[self layer] setMasksToBounds:YES];
        self.contentMode = UIViewContentModeRedraw;
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		[self setOpaque:YES];
		[self setBackgroundColor:[UIColor whiteColor]];
		[self setBorderWidth:0.0f];
		[[self layer] setMasksToBounds:YES];
        self.contentMode = UIViewContentModeRedraw;
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		[self setBorderWidth:0.0f];
		[[self layer] setMasksToBounds:YES];
        self.contentMode = UIViewContentModeRedraw;
	}
	return self;
}

- (void)defaultInit
{
	
}
		 
#pragma mark Drawing Methods

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    [super drawLayer:layer inContext:ctx];
}

- (void)drawRect:(CGRect)rect
{
/*
	BOOL borderWillBeDrawn = (nil != [self borderColor]);

	int numberOfColors = 2;
	const CGFloat * startColorComponents = CGColorGetComponents([startColor CGColor]);
	const CGFloat * endColorComponents = CGColorGetComponents([endColor CGColor]);
	
	CGFloat colorComponents[] = 
	{
		endColorComponents[0]/255.0, endColorComponents[1]/255.0, endColorComponents[2]/255.0, endColorComponents[3],
		startColorComponents[0]/255.0, startColorComponents[1]/255.0, startColorComponents[2]/255.0, startColorComponents[3]
	};

	CGContextRef context = UIGraphicsGetCurrentContext();
	CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
	CGGradientRef gradient = CGGradientCreateWithColorComponents(rgbColorSpace, colorComponents, NULL, numberOfColors);
	
	CGRect currentBounds = [self bounds];
    CGPoint startPoint = ((borderWillBeDrawn) 
						  ? CGPointMake(0.0, [self borderWidth])
						  : CGPointMake(0.0, (2 * CGRectGetMidX(currentBounds)/3.0f)));
    CGPoint endPoint = ((borderWillBeDrawn) 
						? CGPointMake(0.0, (CGRectGetMaxY(currentBounds) - [self borderWidth]))
						: CGPointMake(0.0f, CGRectGetMaxY(currentBounds)));
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, kCGGradientDrawsBeforeStartLocation);
//								((borderWillBeDrawn) ? 0 : kCGGradientDrawsBeforeStartLocation));
	
    CGGradientRelease(gradient);
    CGColorSpaceRelease(rgbColorSpace);
*/
	CGRect currentBounds = [self bounds];
	if (![self gradientLayer]) {
		[self setGradientLayer:[CAGradientLayer layer]];
		[[self layer] insertSublayer:[self gradientLayer] atIndex:0];
	}

	[[self gradientLayer] setFrame:currentBounds];
	[[self gradientLayer] setStartPoint:startPoint];
	[[self gradientLayer] setEndPoint:endPoint];
	[[self gradientLayer] setColors:[NSArray arrayWithObjects:(id)[startColor CGColor], (id)[endColor CGColor], nil]];
	[[self gradientLayer] removeAllAnimations];
	


	if ([self borderColor])
	{	
		[[self layer] setMasksToBounds:YES];
		[[self layer] setBorderColor:[[self borderColor] CGColor]];
		[[self layer] setBorderWidth:[self borderWidth]];
		[[self layer] setCornerRadius:10.0f];
		
	}
    
}

- (void)setStartColor:(UIColor *)sColor startPoint:(CGPoint)sPoint endColor:(UIColor *)eColor endPoint:(CGPoint)ePoint
{
	[self setStartColor:sColor];
	[self setStartPoint:sPoint];
	[self setEndColor:eColor];
	[self setEndPoint:ePoint];
	[self setNeedsDisplay];
}

@end
