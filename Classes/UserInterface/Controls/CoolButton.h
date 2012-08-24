/*
 * Author: Jess Martin
 *
 * Copyright (c) 2011 Jess Martin.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

/*
 * Adapated by Joram Barrez (ie made non-ARC).
 * Also remove white drop shadow
 */

#import <Foundation/Foundation.h>

@class CALayer;
@class CAGradientLayer;

// CoolButtons is a subclass of UIButton that draws glassy iOS style buttons, all using CoreGraphics and no images
// The button looks exactly like the default 'done' button, which is hard to create using a regular UIButton
@interface CoolButton : UIButton {
    CAGradientLayer *_gradientLayer;
    CAGradientLayer *_innerGlowLayer;
}

@property (nonatomic, retain) UIColor *buttonColor;
@property (nonatomic, retain) UIView *innerView;
@property (nonatomic, retain) CALayer *highlightLayer;

@end
