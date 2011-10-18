//
//	WhiteGlossGradientView.m
//	FreshDocs
//
//	Created by Gi Hyun Lee on 10/1/10
//  Copyright 2010 Zia Consulting. All rights reserved.
//
//	http://stackoverflow.com/questions/422066/gradients-on-uiview-and-uilabels-on-iphone/422208#422208
//

#import "WhiteGlossGradientView.h"
#import "UIColor+Theme.h"

@implementation WhiteGlossGradientView

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		[self setOpaque:NO];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self) {
		[self setOpaque:NO];
	}
	return self;
}

- (void)drawRect:(CGRect)dirtyRect
{
	CGContextRef currentContext = UIGraphicsGetCurrentContext();
	
    CGGradientRef glossGradient;
    CGColorSpaceRef rgbColorspace;
    size_t num_locations = 2;
    CGFloat locations[2] = { 0.0f, 1.0f };
    CGFloat components[8] = { 1.0, 1.0, 1.0, 0.35,  // Start color
							1.0, 1.0, 1.0, 0.06 }; // End color
	
    rgbColorspace = CGColorSpaceCreateDeviceRGB();
    glossGradient = CGGradientCreateWithColorComponents(rgbColorspace, components, locations, num_locations);
	
    CGRect currentBounds = self.bounds;
    CGPoint topCenter = CGPointMake(CGRectGetMidX(currentBounds), 0.0f);
    CGPoint midCenter = CGPointMake(CGRectGetMidX(currentBounds), CGRectGetMidY(currentBounds));
    CGContextDrawLinearGradient(currentContext, glossGradient, topCenter, midCenter, 0);
	
    CGGradientRelease(glossGradient);
    CGColorSpaceRelease(rgbColorspace);
}

@end
