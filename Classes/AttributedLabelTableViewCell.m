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
//  AttributedLabelTableViewCell.m
//

#import <QuartzCore/QuartzCore.h>
#import "AttributedLabelTableViewCell.h"
#import "TTTAttributedLabel.h"

static CGFloat const kTextFontSize = 17;

@implementation AttributedLabelTableViewCell
@synthesize attributedLabel = _attributedLabel;

- (void)dealloc
{
    [_attributedLabel release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil; 
    }
    
    self.layer.shouldRasterize = YES;
    self.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    
    self.attributedLabel = [[[TTTAttributedLabel alloc] initWithFrame:CGRectZero] autorelease];
    self.attributedLabel.font = [UIFont systemFontOfSize:kTextFontSize];
    self.attributedLabel.lineBreakMode = UILineBreakModeWordWrap;
    self.attributedLabel.numberOfLines = 0;
    self.attributedLabel.linkAttributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCTUnderlineStyleAttributeName];
    
    self.attributedLabel.highlightedTextColor = [UIColor whiteColor];
    self.attributedLabel.shadowColor = [UIColor colorWithWhite:0.87 alpha:1.0];
    self.attributedLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
    self.attributedLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
    self.attributedLabel.textAlignment = UITextAlignmentCenter;
    
    [self.contentView addSubview:self.attributedLabel];
    
    return self;
}

#pragma mark - UIView

- (void)layoutSubviews {
    [super layoutSubviews];
    self.textLabel.hidden = YES;
    self.detailTextLabel.hidden = YES;
    
    CGRect labelFrame = self.contentView.bounds;
    labelFrame.size.width -= 20;
    labelFrame.size.height -= 20;
    labelFrame.origin.x +=10;
    labelFrame.origin.y +=10;
    self.attributedLabel.frame = labelFrame;
}

@end
