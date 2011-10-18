//
//  GradientView.h
//  FreshDocs
//
//  Created by Gi Hyun Lee on 10/23/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface GradientView : UIView {
	CGPoint startPoint;
	CGPoint	endPoint;
	UIColor *startColor;
	UIColor *endColor;
	UIColor *borderColor;
	CGFloat borderWidth;
	CAGradientLayer *gradientLayer;
}

@property (nonatomic) CGPoint startPoint;
@property (nonatomic) CGPoint endPoint;
@property (nonatomic, retain) UIColor *startColor;
@property (nonatomic, retain) UIColor *endColor;
@property (nonatomic, retain) UIColor *borderColor;
@property (nonatomic) CGFloat borderWidth;
@property (nonatomic, retain) CAGradientLayer *gradientLayer;

- (void)setStartColor:(UIColor *)sColor startPoint:(CGPoint)sPoint endColor:(UIColor *)eColor endPoint:(CGPoint)ePoint;

@end
