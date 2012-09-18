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
//  SystemNoticeGradientView.m
//

#import <QuartzCore/QuartzCore.h>
#import "SystemNoticeGradientView.h"

@interface SystemNoticeGradientView ()
@property (nonatomic, retain) UIColor *gradientTop;
@property (nonatomic, retain) UIColor *gradientBottom;
@property (nonatomic, retain) UIColor *firstTopLine;
@property (nonatomic, retain) UIColor *secondTopLine;
@property (nonatomic, retain) UIColor *firstBottomLine;
@property (nonatomic, retain) UIColor *secondBottomLine;
@end

@implementation SystemNoticeGradientView

@synthesize gradientTop = _gradientTop;
@synthesize gradientBottom = _gradientBottom;
@synthesize firstTopLine = _firstTopLine;
@synthesize secondTopLine = _secondTopLine;
@synthesize firstBottomLine = _firstBottomLine;
@synthesize secondBottomLine = _secondBottomLine;

- (void)dealloc
{
    [_gradientTop release];
    [_gradientBottom release];
    [_firstTopLine release];
    [_secondTopLine release];
    [_firstBottomLine release];
    [_secondBottomLine release];
    
    [super dealloc];
}

- (id)initBlueGradientWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.gradientTop = [UIColor colorWithRed:37/255.0f green:122/255.0f blue:185/255.0f alpha:1.0];
        self.gradientBottom = [UIColor colorWithRed:18/255.0f green:96/255.0f blue:154/255.0f alpha:1.0];
        self.firstTopLine = [UIColor colorWithRed:105/255.0f green:163/255.0f blue:208/255.0f alpha:1.0];
        self.secondTopLine = [UIColor colorWithRed:46/255.0f green:126/255.0f blue:188/255.0f alpha:1.0];
        self.firstBottomLine = [UIColor colorWithRed:18/255.0f green:92/255.0f blue:149/255.0f alpha:1.0];
        self.secondBottomLine = [UIColor colorWithRed:4/255.0f green:45/255.0f blue:75/255.0f alpha:1.0];
    }
    return self;
}

- (id)initRedGradientWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.gradientTop = [UIColor colorWithRed:167/255.0f green:26/255.0f blue:20/255.0f alpha:1.0];
        self.gradientBottom = [UIColor colorWithRed:134/255.0f green:9/255.0f blue:7/255.0f alpha:1.0];
        self.firstTopLine = [UIColor colorWithRed:211/255.0f green:82/255.0f blue:80/255.0f alpha:1.0];
        self.secondTopLine = [UIColor colorWithRed:193/255.0f green:30/255.0f blue:23/255.0f alpha:1.0];
        self.firstBottomLine = [UIColor colorWithRed:134/255.0f green:9/255.0f blue:7/255.0f alpha:1.0];
        self.secondBottomLine = [UIColor colorWithRed:52/255.0f green:4/255.0f blue:3/255.0f alpha:1.0];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.bounds;
    gradient.colors = [NSArray arrayWithObjects:
                       (id)self.gradientTop.CGColor,
                       (id)self.gradientBottom.CGColor,
                       nil];
    gradient.locations = [NSArray arrayWithObjects:
                          [NSNumber numberWithFloat:0.0f],
                          [NSNumber numberWithFloat:0.7],
                          nil];
    
    [self.layer insertSublayer:gradient atIndex:0];
    
    UIView *firstTopLine = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.bounds.size.width, 1.0)] autorelease];
    firstTopLine.backgroundColor = self.firstTopLine;
    [self addSubview:firstTopLine];
    
    UIView *secondTopLine = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 1.0, self.bounds.size.width, 1.0)] autorelease];
    secondTopLine.backgroundColor = self.secondTopLine;
    [self addSubview:secondTopLine];
    
    UIView *firstBottomLine = [[[UIView alloc] initWithFrame:CGRectMake(0.0, self.bounds.size.height - 1, self.frame.size.width, 1.0)] autorelease];
    firstBottomLine.backgroundColor = self.firstBottomLine;
    [self addSubview:firstBottomLine];
    
    UIView *secondBottomLine = [[[UIView alloc] initWithFrame:CGRectMake(0.0, self.bounds.size.height, self.frame.size.width, 1.0)] autorelease];
    secondBottomLine.backgroundColor = self.secondBottomLine;
    [self addSubview:secondBottomLine];
}

@end

