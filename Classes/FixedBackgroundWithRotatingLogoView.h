//
//  FixedBackgroundWithRotatingLogoView.h
//  FreshDocs
//
//  Created by Gi Hyun Lee on 10/20/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FixedBackgroundWithRotatingLogoView : UIView {
@private
	UIImage *rotatingLogoImage;
	UIImageView *rotatingLogoView;
	UIDeviceOrientation previousOrientation;
}

@property (nonatomic, retain) UIImage *rotatingLogoImage;
@property (nonatomic, retain) UIImageView *rotatingLogoView;
@property (nonatomic) UIDeviceOrientation previousOrientation;

- (id)initWithBackgroundColor:(UIColor *)color rotatingLogoImage:(UIImage *)rotatingImage;
- (id)initWithBackgroundImage:(UIImage *)image rotatingLogoImage:(UIImage *)rotatingImage;
- (void)setDefaultProperties;
- (void)rotateAndTranslateLogo;
@end
