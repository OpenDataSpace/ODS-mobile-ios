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
    self.layer.borderColor = [[UIColor blackColor] colorWithAlphaComponent:0.7].CGColor;
    self.layer.borderWidth = 1.0;
    self.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.15];

    // Header with month
    CGRect headerFrame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height / 3);
    UIView *headerView = [[UIView alloc] initWithFrame:headerFrame];
    headerView.backgroundColor = [UIColor colorWithRed:0.60 green:0 blue:0.054 alpha:1.0];
    [self addSubview:headerView];
    [headerView release];

    CGFloat margin = 2;
    CGRect monthLabelFrame = CGRectMake(headerFrame.origin.x + margin,
            headerFrame.origin.y + margin,
            headerFrame.size.width - 2*margin,
            headerFrame.size.height - 2*margin);

    UILabel *monthLabel = [[UILabel alloc] initWithFrame:monthLabelFrame];
    monthLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:14];
    monthLabel.textColor = [UIColor whiteColor];
    monthLabel.backgroundColor = [UIColor clearColor];
    monthLabel.textAlignment = UITextAlignmentCenter;
    monthLabel.adjustsFontSizeToFitWidth = YES;
    [self addSubview:monthLabel];
    [monthLabel release];

    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setDateFormat:@"MMMM"];
    monthLabel.text = [dateFormatter stringFromDate:self.date];

    // Day view
    UILabel *dayLabel = [[UILabel alloc] initWithFrame:CGRectMake(headerFrame.origin.x + margin,
            headerFrame.origin.y + headerFrame.size.height + margin,
            headerFrame.size.width - 2 * margin,
            self.frame.size.height - headerFrame.size.height - 2 * margin)];
    [dateFormatter setDateFormat:@"dd"];
    dayLabel.text = [dateFormatter stringFromDate:self.date];
    [self addSubview:dayLabel];
    [dayLabel release];
}

@end
