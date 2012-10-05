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
// Using parts of code from Matt Thompson
// Copyright (C) 2011-2012 Mattt Thompson (http://mattt.me)
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
// ActivityTableViewCell.m

#import <QuartzCore/QuartzCore.h>
#import "ActivityTableViewCell.h"
#import "TTTAttributedLabel.h"
#import "Activity.h"

static CGFloat const kSummaryTextFontSize = 17;

static NSRegularExpression *__nameRegularExpression;
static inline NSRegularExpression * NameRegularExpression()
{
    if (!__nameRegularExpression)
    {
        __nameRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"^\\w+" options:NSRegularExpressionCaseInsensitive error:nil];
    }
    
    return __nameRegularExpression;
}

static NSRegularExpression *__parenthesisRegularExpression;
static inline NSRegularExpression * ParenthesisRegularExpression()
{
    if (!__parenthesisRegularExpression)
    {
        __parenthesisRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"\\([^\\(\\)]+\\)" options:NSRegularExpressionCaseInsensitive error:nil];
    }
    
    return __parenthesisRegularExpression;
}

@implementation ActivityTableViewCell

@synthesize activity = _activity;
@synthesize summaryLabel = _summaryLabel;

- (void)dealloc
{
    [_summaryLabel release];
    [_activity release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.summaryLabel = [[[TTTAttributedLabel alloc] initWithFrame:CGRectZero] autorelease];
        self.summaryLabel.font = [UIFont systemFontOfSize:kSummaryTextFontSize];
        self.summaryLabel.lineBreakMode = UILineBreakModeWordWrap;
        self.summaryLabel.numberOfLines = 0;
        
        [self.contentView addSubview:self.summaryLabel];
    }
        
    return self;
}

- (void)setActivity:(Activity *)activity
{
    [_activity autorelease];
    _activity = [activity retain];
    
    [self.summaryLabel setText:[activity activityText] afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
        mutableAttributedString = [self.activity boldReplacements:[self.activity replacements] inString:mutableAttributedString];
        return mutableAttributedString;
    }];
}

#pragma mark - UIView

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.textLabel.hidden = YES;
        
    self.summaryLabel.frame = self.textLabel.frame;
}

@end
