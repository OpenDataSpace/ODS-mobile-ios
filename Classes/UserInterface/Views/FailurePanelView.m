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
//  FailurePanelView.m
//

#import "FailurePanelView.h"
#import "UIColor+Theme.h"
#import "CustomBadge.h"
#import "UIImageUtils.h"

CGFloat kFailurePanelPadding = 8.0f;

@implementation FailurePanelView
@synthesize failureLabel = _failureLabel;
@synthesize badge = _badge;

- (void)dealloc
{
    [_failureLabel release];
    [_badge release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        //[self setBackgroundColor:[UIColor panelBackgroundColor]];
        UIImage *backgroundImage = [UIImage imageWithColor:[UIColor panelBackgroundColor]];
        [self setBackgroundImage:backgroundImage forState:UIControlStateNormal];
        [self setBackgroundImage:[UIImage imageWithColor:[UIColor selectedPanelBackgroundColor]] forState:UIControlStateHighlighted];
        
        CustomBadge *badge = [CustomBadge customBadgeWithString:@"!"];
        [badge setFrame:CGRectMake(kFailurePanelPadding, kFailurePanelPadding/2, badge.frame.size.width, badge.frame.size.height)];
        [badge setAutoresizingMask:UIViewAutoresizingNone];
        [self setBadge:badge];
        [self addSubview:self.badge];
        
        UILabel *failureLabel = [[UILabel alloc] initWithFrame:CGRectMake(kFailurePanelPadding * 2 + self.badge.frame.size.width, 0, 0, 0)];
        [failureLabel setText:@"Title"];
        [failureLabel setTextColor:[UIColor whiteColor]];
        [failureLabel setBackgroundColor:[UIColor clearColor]];
        [failureLabel setFont:[UIFont systemFontOfSize:15]];
        [failureLabel sizeToFit];
        CGRect labelRect = failureLabel.frame;
        labelRect.size.width = frame.size.width - self.badge.frame.size.width - (kFailurePanelPadding * 3);
        labelRect.origin.y = self.badge.center.y - (labelRect.size.height / 2);
        [failureLabel setFrame:labelRect];
        [failureLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [self setFailureLabel:failureLabel];
        [failureLabel release];
        
        //We generate this view's height
        [self setFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width,  kFailurePanelPadding + self.badge.frame.size.height)];
        [self addSubview:self.failureLabel];
        [self addSubview:self.badge];
    }
    return self;
}


@end
