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
// DateIconView 
//
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import "DateIconView.h"


@implementation DateIconView

@synthesize date = _date;


- (void)dealloc
{
    [_date release];
    [super dealloc];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    // Rounded and border
    self.layer.cornerRadius = 10;
    self.layer.masksToBounds = YES;
    self.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.layer.borderWidth = 1.0;

    CAGradientLayer *bgGradient = [CAGradientLayer layer];
    bgGradient.frame = self.bounds;
    bgGradient.colors = [NSArray arrayWithObjects:(id) [UIColor colorWithRed:0.97 green:0.96 blue:0.93 alpha:0.47].CGColor,
                                                (id) [UIColor colorWithRed:0.97 green:0.96 blue:0.93 alpha:0.25].CGColor, nil];
    [self.layer insertSublayer:bgGradient atIndex:0];

    // Header with month
    CGRect headerFrame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height / 3);
    UIView *headerView = [[UIView alloc] initWithFrame:headerFrame];
    [self addSubview:headerView];

    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = headerView.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[UIColor colorWithRed:0.69 green:0.169 blue:0.173 alpha:0.8].CGColor,
                    (id)[UIColor colorWithRed:0.69 green:0.169 blue:0.173 alpha:0.5].CGColor, nil];
    [headerView.layer insertSublayer:gradient atIndex:0];
    [headerView release];

    CGFloat margin = 2;
    CGRect monthLabelFrame = CGRectMake(headerFrame.origin.x + margin,
            headerFrame.origin.y + margin,
            headerFrame.size.width - 2*margin,
            headerFrame.size.height - 2*margin);

    UILabel *monthLabel = [[UILabel alloc] initWithFrame:monthLabelFrame];
    monthLabel.textColor = [UIColor whiteColor];
    monthLabel.backgroundColor = [UIColor clearColor];
    monthLabel.textAlignment = UITextAlignmentCenter;
    monthLabel.adjustsFontSizeToFitWidth = YES;
    [self addSubview:monthLabel];
    [monthLabel release];

    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setDateFormat:@"MMM"];
    monthLabel.text = [[dateFormatter stringFromDate:self.date] uppercaseString];
    [self fitTextToLabel:monthLabel];

    // Day view
    UILabel *dayLabel = [[UILabel alloc] initWithFrame:CGRectMake(headerFrame.origin.x,
        headerFrame.origin.y + headerFrame.size.height,
        self.frame.size.width,
        self.frame.size.height - headerFrame.size.height - 2 * margin)];
    dayLabel.backgroundColor = [UIColor clearColor];

    [dateFormatter setDateFormat:@"d"];
    dayLabel.text = [dateFormatter stringFromDate:self.date];
    [self fitTextToLabel:dayLabel];
    dayLabel.textAlignment = UITextAlignmentCenter;
    [self addSubview:dayLabel];
    [dayLabel release];
}

#pragma mark Helper methods

// Inspired by http://stackoverflow.com/questions/2844397/how-to-adjust-font-size-of-label-to-fit-the-rectangle
- (void) fitTextToLabel:(UILabel *)label{

    int fontSize = 100;
    int minFontSize = 10;

    // Fit label width wize
    CGSize constraintSize = CGSizeMake(label.frame.size.width, MAXFLOAT);

    while (fontSize > minFontSize)
    {
        label.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:fontSize];
        CGSize sizeWithFont = [label.text sizeWithFont:label.font constrainedToSize:constraintSize];

        if (sizeWithFont.height <= label.frame.size.height)
        {
            break;
        }
        fontSize -= 2;
    }
}

@end
