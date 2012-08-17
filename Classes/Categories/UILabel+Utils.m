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
// UILabel(Utils) 
//

#import "UILabel+Utils.h"

@implementation UILabel (Utils)

// Inspired by http://stackoverflow.com/questions/2844397/how-to-adjust-font-size-of-label-to-fit-the-rectangle
- (void) fitTextToLabelUsingFont:(NSString *)fontName defaultFontSize:(NSInteger)defaultFontSize minFontSize:(NSInteger)minFontSize
{
    NSInteger fontSize = defaultFontSize;
    CGSize constraintSize = CGSizeMake(self.frame.size.width, MAXFLOAT);

    while (fontSize > minFontSize)
    {
        self.font = [UIFont fontWithName:fontName size:fontSize];
        CGSize sizeWithFont = [self.text sizeWithFont:self.font constrainedToSize:constraintSize];

        if (sizeWithFont.height <= self.frame.size.height)
        {
            break;
        }
        fontSize--;
    }
}

@end
