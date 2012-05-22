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
 * Portions created by the Initial Developer are Copyright (C) 2011-2012
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  UIImageUtils.h
//
// Some code from: http://stackoverflow.com/questions/603907/uiimage-resize-then-crop
//

#import <Foundation/Foundation.h>

@interface UIImage (UIImageUtils)

- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize;
- (UIImage*)imageByScalingToWidth:(CGFloat)targetWidth;

/*
 Creates a 1x1 image the pixel is filled with the supplied color
 */
+ (UIImage *)imageWithColor:(UIColor *)color;
/*
 Creates a 1x2 image the top pixel filled with the first color and the bottom pixel filled with the second color
 */
+ (UIImage *)imageWithFirstColor:(UIColor *)color andSecondColor:(UIColor *)secondColor;
@end
