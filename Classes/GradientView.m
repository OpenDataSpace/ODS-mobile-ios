//
//  GradientView.m
//  FreshDocs
//
//  Created by Gi Hyun Lee on 10/23/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
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
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		[self setBorderWidth:0.0f];
		[[self layer] setMasksToBounds:YES];
	}
	return self;
}

- (void)defaultInit
{
	
}
		 
#pragma mark Drawing Methods

- (void)drawRect:(CGRect)rect
{
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
