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
//  ProgressPanelView.m
//

#import "ProgressPanelView.h"
#import "UIColor+Theme.h"
#import "UIImageUtils.h"

const CGFloat kProgressPanelPadding = 8.0f;

@implementation ProgressPanelView
@synthesize progressLabel = _progressLabel;
@synthesize progressBar = _progressBar;
@synthesize closeButton = _closeButton;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [self setBackgroundColor:[UIColor panelBackgroundColor]];
        
        UILabel *progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(kProgressPanelPadding, kProgressPanelPadding, 0, 0)];
        [progressLabel setText:@"Title"];
        [progressLabel setTextColor:[UIColor whiteColor]];
        [progressLabel setBackgroundColor:[UIColor clearColor]];
        [progressLabel setFont:[UIFont systemFontOfSize:15]];
        [progressLabel sizeToFit];
        CGRect labelRect = progressLabel.frame;
        labelRect.size.width = frame.size.width - (kProgressPanelPadding * 4);
        [progressLabel setFrame:labelRect];
        [progressLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [self setProgressLabel:progressLabel];
            
        UIProgressView *progressBar = [[UIProgressView alloc] initWithFrame:CGRectMake(kProgressPanelPadding, progressLabel.frame.size.height + (kProgressPanelPadding *2), frame.size.width - (kProgressPanelPadding * 3) - 25, 25)];
        [progressBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [self setProgressBar:progressBar];
        
        UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [closeButton setBackgroundColor:[UIColor panelBackgroundColor]];
        UIImage *backgroundImage = [UIImage imageWithColor:[UIColor panelBackgroundColor]];
        [closeButton setBackgroundImage:backgroundImage forState:UIControlStateNormal];
        [closeButton setBackgroundImage:[UIImage imageWithColor:[UIColor selectedPanelBackgroundColor]] forState:UIControlStateHighlighted];
        
        [closeButton setTitle:@"x" forState:UIControlStateNormal];
        [closeButton setFrame:CGRectMake((kProgressPanelPadding * 2) + progressBar.frame.size.width, progressLabel.frame.size.height, 25, 25)];
        [closeButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
        [self setCloseButton:closeButton];
         
        [progressLabel release];
        [progressBar release];
        
        [self addSubview:progressLabel];
        [self addSubview:progressBar];
        [self addSubview:closeButton];
    }
    return self;
}

@end
