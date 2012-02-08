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
//  TableViewHeaderView.m
//

#import "TableViewHeaderView.h"

@implementation TableViewHeaderView
@synthesize textLabel;

static CGFloat const kLabelFontSize = 20.0f;
static CGFloat const kSectionHeaderHeightPadding = 6.0;

- (void)dealloc {
    [textLabel release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame label:(NSString *)label {
    self = [super initWithFrame:frame];
    if(self) {
        CGSize sectionTitleSize = [label sizeWithFont:[UIFont boldSystemFontOfSize:kLabelFontSize]];
        CGFloat headerHeight = sectionTitleSize.height + kSectionHeaderHeightPadding;
        
        if(headerHeight > frame.size.height) {
            frame.size.height = headerHeight;
            [self setFrame:frame];
        }
        
        textLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 0.0, frame.size.width, headerHeight)];
        [textLabel setFont:[UIFont boldSystemFontOfSize:kLabelFontSize]];
        [textLabel setText:label];
        
        
        [textLabel setBackgroundColor:[UIColor clearColor]]; // FIXME: Not optimal!!!
        [self addSubview:textLabel];
    }
    
    return self;
}
@end
