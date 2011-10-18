//
//  FixedBackgroundWithRotatingLogoView.m
//  FreshDocs
//
//  Created by Gi Hyun Lee on 10/20/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

#import "FixedBackgroundWithRotatingLogoView.h"
#import "AlfrescoAppDelegate.h"

// TODO: Move these into a constants file
static CGFloat bufferPadding = 20.0;
static CGFloat bottomPadding = 49.0;


@implementation FixedBackgroundWithRotatingLogoView
@synthesize rotatingLogoImage;
@synthesize rotatingLogoView;
@synthesize previousOrientation;

#pragma mark Memory Management Methods

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[rotatingLogoImage release];
	[rotatingLogoView release];
	
	[super dealloc];
}

#pragma mark Initialization Methods

- (id)initWithBackgroundColor:(UIColor *)color rotatingLogoImage:(UIImage *)rotatingImage
{
	if ((self = [super initWithFrame:[[UIScreen mainScreen] bounds]])) {
		[self setDefaultProperties];
		[self setBackgroundColor:color];
		
		[self setRotatingLogoImage:rotatingImage];
		[self setRotatingLogoView:[[[UIImageView alloc] initWithImage:rotatingImage] autorelease]];
		[self addSubview:rotatingLogoView];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rotateAndTranslateLogo) 
													 name:UIDeviceOrientationDidChangeNotification object:nil];
	}
	return self;
}

- (id)initWithBackgroundImage:(UIImage *)image rotatingLogoImage:(UIImage *)rotatingImage
{
	if ((self = [super initWithFrame:[[UIScreen mainScreen] bounds]])) {
		[self setDefaultProperties];
		
		UIImageView *bgView = [[UIImageView alloc] initWithImage:image];
		[bgView setOpaque:YES];
		[self addSubview:bgView];
		[bgView release];
		
		
		[self setRotatingLogoImage:rotatingImage];
		[self setRotatingLogoView:[[[UIImageView alloc] initWithImage:rotatingImage] autorelease]];
		[self addSubview:rotatingLogoView];
		
		CGSize logoSize = [[self rotatingLogoImage] size];
		CGSize viewFrameSize = self.frame.size;
		CGPoint movePoint = CGPointMake((viewFrameSize.width - logoSize.width - bufferPadding),
										(viewFrameSize.height - logoSize.height - bottomPadding - bufferPadding));
		[[self rotatingLogoView] setFrame:CGRectMake(movePoint.x, movePoint.y, 
													 [self rotatingLogoView].frame.size.width, 
													 [self rotatingLogoView].frame.size.height)];
	}
	return self;
}

- (void)setDefaultProperties
{
	[self setPreviousOrientation:UIDeviceOrientationUnknown];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rotateAndTranslateLogo) 
												 name:UIDeviceOrientationDidChangeNotification object:nil];

	[self setAutoresizesSubviews:YES];
	[self setOpaque:YES];	
}

#pragma mark Rotatation and Translation

- (void)rotateAndTranslateLogo
{
	if ([NSThread isMainThread] == NO) {
		[self performSelectorOnMainThread:@selector(rotateAndTranslateLogo) withObject:nil waitUntilDone:NO];
		return;
	}
	
	UIDeviceOrientation currentOrientation = [[UIDevice currentDevice] orientation];
	if (previousOrientation == currentOrientation) {
		return;
	}
	
	CGSize logoSize = [[self rotatingLogoImage] size];
	CGSize viewFrameSize = self.frame.size;
	
	CGPoint movePoint;
	CGFloat rotationAngleRadians; // counterclockwise rotation
	switch (currentOrientation) {
		case UIDeviceOrientationLandscapeLeft:
			// HOME BUTTON ON RIGHT
			rotationAngleRadians = 3 * M_PI / 2;
			movePoint = CGPointMake((bottomPadding + bufferPadding), 
									(viewFrameSize.height - logoSize.width - bufferPadding));
			break;
		case UIDeviceOrientationLandscapeRight:
			// HOME BUTTON ON LEFT
			rotationAngleRadians = M_PI / 2;
			movePoint = CGPointMake((viewFrameSize.width - logoSize.height - bottomPadding - bufferPadding), 
									(bufferPadding));
			break;
		case UIDeviceOrientationPortraitUpsideDown:
			rotationAngleRadians = M_PI;
			movePoint = CGPointMake((bufferPadding), 
									(bufferPadding + bottomPadding));
			break;
		case UIDeviceOrientationFaceUp:
		case UIDeviceOrientationFaceDown:
			if (previousOrientation != UIDeviceOrientationUnknown) {
				return;
			}
			currentOrientation = UIDeviceOrientationPortrait;
		case UIDeviceOrientationPortrait:
			rotationAngleRadians = 0;
			movePoint = CGPointMake((viewFrameSize.width - logoSize.width - bufferPadding),
									(viewFrameSize.height - logoSize.height - bottomPadding - bufferPadding));
			break;
		default:
			// we're handling an orientation that tells us nothing, do nothing
			return;
	}
	
	[self setPreviousOrientation:currentOrientation];
	
	// transform back to identity to make rotation calculation easier
	[rotatingLogoView setTransform:CGAffineTransformIdentity]; 
	
	// don't worry about the translation, we manually set the t_x & t_y by setting the point for the frame
	CGAffineTransform rotate = CGAffineTransformMake(cos(rotationAngleRadians), -sin(rotationAngleRadians),
													 sin(rotationAngleRadians), cos(rotationAngleRadians), 
													 0, 0); 
	[rotatingLogoView setTransform:rotate];
	
	// GHL: manually setting the point because I didn't want to solve the math to find the translation values for the transform matrix
	[[self rotatingLogoView] setFrame:CGRectMake(movePoint.x, movePoint.y, 
												 [self rotatingLogoView].frame.size.width, 
												 [self rotatingLogoView].frame.size.height)];
}

@end
