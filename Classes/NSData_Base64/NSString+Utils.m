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
//  NSString+Utils.m
//

#import "NSString+Utils.h"

@implementation NSString (Utils)

/**
 * Returns YES if aString is equivalent to the receiver (if they have the same id or if they are NSOrderedSame in a literal comparison with option NSCaseInsensitiveSearch), otherwise NO.
 */
- (BOOL)isEqualToCaseInsensitiveString:(NSString *)aString
{
    return ( (self == aString) || (NSOrderedSame == [self caseInsensitiveCompare:aString]) );
}

/**
 * From: http://stackoverflow.com/questions/800123/best-practices-for-validating-email-address-in-objective-c-on-ios-2-0
 *
**/
- (BOOL)isValidEmail
{
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"; 
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex]; 
    
    return [emailTest evaluateWithObject:self];
}

- (BOOL)isNotEmpty
{
    return ![[self trimWhiteSpace] isEqualToString:[NSString string]];
}

/**
 * From: http://stackoverflow.com/questions/277055/remove-html-tags-from-an-nsstring-on-the-iphone
 *
 **/
- (NSString *)stringByRemovingHTMLTags
{
    NSRange r;
    NSString *s = [[self copy] autorelease];
    
    while ((r = [s rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        s = [s stringByReplacingCharactersInRange:r withString:@""];
    
    // also replace &nbsp; with " "
    s = [s stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
    
    return s;
}

#pragma - Trimming utils
- (NSString *)stringWithTrailingSlashRemoved
{
	if ([self hasSuffix:@"/"]) {
		return [self substringToIndex:([self length]-1)];
	}
	else {
		return self;
	}
}

- (NSString *)trimWhiteSpace
{
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

#pragma - Concatenate utils
+ (NSString *)stringByAppendingString:(NSString *)string toString:(NSString *)otherString 
{
	if (!string) {
		return otherString;
	}
	else if (!otherString) {
		return string;
	}
	else {
		return [otherString stringByAppendingString:string];
	}
}

@end
