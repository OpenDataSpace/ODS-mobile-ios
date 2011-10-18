//
//  UIImageUtils.h
//  XpenserUtility
//
//  Created by Bindu Wavell on 1/6/10.
//  Copyright 2010 Zia Consulting, Inc.. All rights reserved.
//
// Some code from: http://stackoverflow.com/questions/603907/uiimage-resize-then-crop
//

#import <Foundation/Foundation.h>

@interface UIImage (UIImageUtils)

- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize;
- (UIImage*)imageByScalingToWidth:(CGFloat)targetWidth;

@end
