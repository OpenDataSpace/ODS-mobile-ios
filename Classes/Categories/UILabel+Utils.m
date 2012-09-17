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

#define THREE_DOTS @"..."

#import "UILabel+Utils.h"

@implementation UILabel (Utils)

// Inspired by http://stackoverflow.com/questions/2844397/how-to-adjust-font-size-of-label-to-fit-the-rectangle
- (void)fitTextToLabelUsingFont:(NSString *)fontName defaultFontSize:(NSInteger)defaultFontSize minFontSize:(NSInteger)minFontSize
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

- (BOOL)appendDotsIfTextDoesNotFit
{
    BOOL isTextShortened = NO;

    if (self.numberOfLines == 1)
    {
        CGFloat textWidth = [self.text sizeWithFont:self.font].width;
        if (textWidth > self.frame.size.width)
        {
            CGFloat dotsWidth = [THREE_DOTS sizeWithFont:self.font].width;

            // Remove characters from text until the text with the three dots fits the width
            while ([self.text sizeWithFont:self.font].width + dotsWidth > self.frame.size.width)
            {
                self.text = [self.text substringToIndex:self.text.length - 2];
            }

            self.text = [NSString stringWithFormat:@"%@%@", self.text, THREE_DOTS];
            isTextShortened = YES;
        }
    }
    else // Multi line case
    {
        CGFloat textHeight = [self.text sizeWithFont:self.font constrainedToSize:CGSizeMake(self.frame.size.width, MAXFLOAT) lineBreakMode:self.lineBreakMode].height;
        if (textHeight > self.frame.size.height)
        {
            while (textHeight > self.frame.size.height)
            {
                self.text = [self.text substringToIndex:self.text.length - 2];
                textHeight = [[NSString stringWithFormat:@"%@%@", self.text, THREE_DOTS] sizeWithFont:self.font
                     constrainedToSize:CGSizeMake(self.frame.size.width, MAXFLOAT) lineBreakMode:self.lineBreakMode].height;
            }

            self.text = [NSString stringWithFormat:@"%@%@", self.text, THREE_DOTS];
            isTextShortened = YES;
        }
    }

    return isTextShortened;
}

// Supports SystemNotice message label
- (NSArray *)arrayWithLinesOfText
{
    NSMutableArray *lines = [NSMutableArray arrayWithCapacity:10];
    NSCharacterSet *wordSeparators = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *currentLine = self.text;
    NSUInteger textLength = [self.text length];
    
    NSRange rCurrentLine = NSMakeRange(0, textLength);
    NSRange rWhitespace = NSMakeRange(0, 0);
    NSRange rRemainingText = NSMakeRange(0, textLength);
    BOOL done = NO;
    
    while (NO == done)
    {
        // determine the next whitespace word separator position
        rWhitespace.location = rWhitespace.location + rWhitespace.length;
        rWhitespace.length = textLength - rWhitespace.location;
        rWhitespace = [self.text rangeOfCharacterFromSet:wordSeparators options:NSCaseInsensitiveSearch range:rWhitespace];
        
        if (NSNotFound == rWhitespace.location)
        {
            rWhitespace.location = textLength;
            done = YES;
        }
        
        NSRange rTest = NSMakeRange(rRemainingText.location, rWhitespace.location - rRemainingText.location);
        NSString *textTest = [self.text substringWithRange:rTest];
        CGSize sizeTest = [textTest sizeWithFont:self.font forWidth:1024.0 lineBreakMode:UILineBreakModeWordWrap];
        
        if (sizeTest.width > self.bounds.size.width)
        {
            [lines addObject:[currentLine stringByTrimmingCharactersInSet:wordSeparators]];
            rRemainingText.location = rCurrentLine.location + rCurrentLine.length;
            rRemainingText.length = textLength-rRemainingText.location;
            continue;
        }
        
        rCurrentLine = rTest;
        currentLine = textTest;
    }
    
    [lines addObject:[currentLine stringByTrimmingCharactersInSet:wordSeparators]];
    
    return lines;
    
}

@end
