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

#define HEADER_HEIGHT 20.0

#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import "DateIconView.h"
#import "UILabel+Utils.h"

@interface DateIconView ()

@property (nonatomic, retain) UILabel *monthLabel;
@property (nonatomic, retain) UILabel *dayLabel;

@end

@implementation DateIconView

@synthesize date = _date;
@synthesize monthLabel = _monthLabel;
@synthesize dayLabel = _dayLabel;


- (void)dealloc
{
    [_date release];
    [_monthLabel release];
    [_dayLabel release];
    [super dealloc];
}

- (void)setDate:(NSDate *)date
{
    [_date autorelease];
    _date = [date retain];

    // When the date is changed, update the layout again
    [self layoutSubviews];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    // Background image
    UIImage *background = [UIImage imageNamed:@"calendar.png"];
    if (!self.image)
    {
        self.image = background;
    }

    // Month
    if (!self.monthLabel)
    {
        self.monthLabel = [[[UILabel alloc] init] autorelease];
        [self addSubview:self.monthLabel];
    }

    CGFloat monthLabelMargin = 8;
    CGRect monthLabelFrame = CGRectMake(monthLabelMargin, 5,
            background.size.width - 2* monthLabelMargin, HEADER_HEIGHT);
    self.monthLabel.frame = monthLabelFrame;
    self.monthLabel.textColor = [UIColor whiteColor];
    self.monthLabel.backgroundColor = [UIColor clearColor];
    self.monthLabel.textAlignment = UITextAlignmentCenter;
    self.monthLabel.adjustsFontSizeToFitWidth = YES;

    // Day label
    if (!self.dayLabel)
    {
        self.dayLabel = [[[UILabel alloc] init] autorelease];
        [self addSubview:self.dayLabel];
    }
    CGFloat dayMargin = 4.0;
    self.dayLabel.frame = CGRectMake(0, dayMargin + monthLabelFrame.size.height, self.frame.size.width,
        self.frame.size.height - monthLabelFrame.size.height - 2 * dayMargin);
    self.dayLabel.backgroundColor = [UIColor clearColor];
    self.dayLabel.textAlignment = UITextAlignmentCenter;

    // Text
    if (self.date)
    {
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormatter setDateFormat:@"MMM"];
        self.monthLabel.text = [[dateFormatter stringFromDate:self.date] uppercaseString];

        [dateFormatter setDateFormat:@"d"];
        self.dayLabel.text = [dateFormatter stringFromDate:self.date];
    }
    else
    {
        self.monthLabel.text = NSLocalizedString(@"date.icon.view.no.date.header", nil);
        self.dayLabel.text = NSLocalizedString(@"date.icon.view.no.date.day", nil);
        self.dayLabel.textColor = [UIColor lightGrayColor];
    }

    [self.monthLabel fitTextToLabelUsingFont:@"HelveticaNeue-Medium" defaultFontSize:50 minFontSize:6];
    [self.dayLabel fitTextToLabelUsingFont:@"HelveticaNeue-Medium" defaultFontSize:50 minFontSize:6];
}

@end
