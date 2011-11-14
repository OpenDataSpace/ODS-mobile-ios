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
 * Portions created by the Initial Developer are Copyright (C) 2011
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
/*ISO8601DateFormatter.h
 *
 *Created by Peter Hosey on 2009-04-11.
 *Copyright 2009 Peter Hosey. All rights reserved.
 */

#import <Foundation/Foundation.h>

/*This class converts dates to and from ISO 8601 strings. A good introduction to ISO 8601: <http://www.cl.cam.ac.uk/~mgk25/iso-time.html>
 *
 *Parsing can be done strictly, or not. When you parse loosely, leading whitespace is ignored, as is anything after the date.
 *The loose parser will return an NSDate for this string: @" \t\r\n\f\t  2006-03-02!!!"
 *Leading non-whitespace will not be ignored; the string will be rejected, and nil returned. See the README that came with this addition.
 *
 *The strict parser will only accept a string if the date is the entire string. The above string would be rejected immediately, solely on these grounds.
 *Also, the loose parser provides some extensions that the strict parser doesn't.
 *For example, the standard says for "-DDD" (an ordinal date in the implied year) that the logical representation (meaning, hierarchically) would be "--DDD", but because that extra hyphen is "superfluous", it was omitted.
 *The loose parser will accept the extra hyphen; the strict parser will not.
 *A full list of these extensions is in the README file.
 */

/*The format to either expect or produce.
 *Calendar format is YYYY-MM-DD.
 *Ordinal format is YYYY-DDD, where DDD ranges from 1 to 366; for example, 2009-32 is 2009-02-01.
 *Week format is YYYY-Www-D, where ww ranges from 1 to 53 (the 'W' is literal) and D ranges from 1 to 7; for example, 2009-W05-07.
 */
enum {
	ISO8601DateFormatCalendar,
	ISO8601DateFormatOrdinal,
	ISO8601DateFormatWeek,
};
typedef NSUInteger ISO8601DateFormat;

//The default separator for time values. Currently, this is ':'.
extern unichar ISO8601DefaultTimeSeparatorCharacter;

@interface ISO8601DateFormatter: NSFormatter
{
	NSTimeZone *defaultTimeZone;
	ISO8601DateFormat format;
	unichar timeSeparator;
	BOOL includeTime;
	BOOL parsesStrictly;
}

@property(retain) NSTimeZone *defaultTimeZone;

#pragma mark Parsing

//As a formatter, this object converts strings to dates.

@property BOOL parsesStrictly;

- (NSDateComponents *) dateComponentsFromString:(NSString *)string;
- (NSDateComponents *) dateComponentsFromString:(NSString *)string timeZone:(out NSTimeZone **)outTimeZone;
- (NSDateComponents *) dateComponentsFromString:(NSString *)string timeZone:(out NSTimeZone **)outTimeZone range:(out NSRange *)outRange;

- (NSDate *) dateFromString:(NSString *)string;
- (NSDate *) dateFromString:(NSString *)string timeZone:(out NSTimeZone **)outTimeZone;
- (NSDate *) dateFromString:(NSString *)string timeZone:(out NSTimeZone **)outTimeZone range:(out NSRange *)outRange;

#pragma mark Unparsing

@property ISO8601DateFormat format;
@property BOOL includeTime;
@property unichar timeSeparator;

- (NSString *) stringFromDate:(NSDate *)date;
- (NSString *) stringFromDate:(NSDate *)date timeZone:(NSTimeZone *)timeZone;

@end
