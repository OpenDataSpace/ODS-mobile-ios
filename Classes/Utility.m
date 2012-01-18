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
//  Utility.m
//  Alfresco
//

#include <sys/xattr.h>

#import "Utility.h"
#import "ISO8601DateFormatter.h"
#import "NSString+Utils.h"
#import "RepositoryServices.h"
#import "AppProperties.h"

static NSDictionary *iconMappings;
static NSDictionary *mimeMappings;

UIImage* imageForFilename(NSString* filename) 
{
    NSString *fileExtension = [filename pathExtension];
    if (fileExtension && ([fileExtension length] > 0))
    {
        NSString *potentialImageName = [fileExtension stringByAppendingPathExtension:@"png"];
        //        NSLog(@"Attempting to locate document icon %@", potentialImageName);
        
        UIImage *potentialImage = [UIImage imageNamed:potentialImageName];
        if (nil != potentialImage) 
        {
            //            NSLog(@"Document Icon %@ found", potentialImageName);
            return potentialImage;
        }
    }
    
    //    NSLog(@"Document Icon default mapping will be used for document %@", filename);
	NSString *imageName = nil;
    if(!iconMappings) {
        NSString *mappingsPath = [[NSBundle mainBundle] pathForResource:@"IconMappings" ofType:@"plist"];
        iconMappings = [[NSDictionary alloc] initWithContentsOfFile:mappingsPath];
    }
	NSUInteger location = [filename rangeOfString:@"." options: NSBackwardsSearch].location;
	if (location != NSNotFound) {
		NSString *ext = [[filename substringFromIndex:location] lowercaseString];
		if ([iconMappings objectForKey:ext]) {
			imageName = [iconMappings objectForKey:ext];
		}
	}
    
    if (imageName == nil || [imageName length] == 0) {
        imageName = @"generic.png";
    }

	return [UIImage imageNamed:imageName];
}

NSString* mimeTypeForFilename(NSString* filename) 
{
    return mimeTypeForFilenameWithDefault(filename, @"text/plain");
}

NSString* mimeTypeForFilenameWithDefault(NSString* filename, NSString *defaultMimeType)
{
    NSString *fileExtension = [filename pathExtension];
    fileExtension = [fileExtension lowercaseString];
    NSString *mimeType = defaultMimeType;
    
    if(!mimeMappings) {
        NSString *mimeMappingsPath = [[NSBundle mainBundle] pathForResource:@"MimeMappings" ofType:@"plist"];
        mimeMappings = [[NSDictionary alloc] initWithContentsOfFile:mimeMappingsPath];
    }
    
    if (fileExtension && ([fileExtension length] > 0) && [mimeMappings
                                                          objectForKey:fileExtension])
    {
        mimeType = [mimeMappings objectForKey:fileExtension];
    } 
    
    return mimeType;
}

BOOL isVideoExtension(NSString *extension) {
    static NSArray *videoExtensions = nil;
    extension = [extension lowercaseString];
    
    if(!videoExtensions) {
        videoExtensions = [[NSArray arrayWithObjects:@"mov", @"mp4", @"mpv", @"3gp", @"m4v",
                        nil] retain];
    }
    
    return [videoExtensions containsObject:extension];
}

BOOL isMimeTypeVideo(NSString *mimeType)
{
    return [[mimeType lowercaseString] hasPrefix:@"video/"];
}

NSString* createStringByEscapingAmpersandsInsideTagsOfString(NSString *input, NSString *startTag, NSString *endTag) {
	
	NSMutableString *escapedString = [[NSMutableString alloc] initWithString:@""];
	
	NSArray *pieces = [input componentsSeparatedByString:startTag];
	
	if ([pieces count] > 0) {
		[escapedString appendString:[pieces objectAtIndex:0]];
		
		for (int i = 1; i < [pieces count]; i++) {
			
			NSString *piece = [pieces objectAtIndex:i];
			NSRange r = [piece rangeOfString:endTag];
			
			NSString *firstHalf = [piece substringToIndex:r.location];
			NSString *secondHalf = [piece substringFromIndex:r.location];
			NSString *encodedFirstHalf = [firstHalf stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"]; 
			
			[escapedString appendString:startTag];
			[escapedString appendString:encodedFirstHalf];
			[escapedString appendString:secondHalf];
		}
	}
	
	return escapedString;
}

static int spinnerCount = 0;

void startSpinner() {
	if (spinnerCount <= 0) {
		spinnerCount = 0;
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	}
	spinnerCount++;
}

void stopSpinner() 
{
	spinnerCount--;
	if (spinnerCount <= 0) {
		spinnerCount = 0;
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	}
}

BOOL userPrefShowHiddenFiles() {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"showHidden"];
}

BOOL userPrefShowCompanyHome() {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"showCompanyHome"];	
}

NSString* userPrefProtocol() {
	return [[NSUserDefaults standardUserDefaults] objectForKey:@"protocol"];
}

BOOL userPrefFullTextSearch() {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"fullTextSearch"];
}

BOOL userPrefValidateSSLCertificate() {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"validateSSLCertificate"];
}

NSDate* dateFromIso(NSString *isoDate) {
	ISO8601DateFormatter *isoFormatter = [[ISO8601DateFormatter alloc] init];	
    NSDate *formattedDate = [isoFormatter dateFromString:isoDate];
    [isoFormatter release];
	return formattedDate;
}

NSString* formatDateTime(NSString *isoDate) {
	if (nil == isoDate) {
		return [NSString string];
	}
	
	NSDate *date = dateFromIso(isoDate);
	return formatDateTimeFromDate(date);
}

NSString* formatDateTimeFromDate(NSDate *dateObj) {
	if (nil == dateObj) {
		return [NSString string];
	}
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	
    [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	NSString *humanReadableDate = [dateFormatter stringFromDate:dateObj];
	
	[dateFormatter release];
	return humanReadableDate;
}

// Is "useRelativeDate" Setting aware
NSString* changeStringDateToFormat(NSString *stringDate, NSString *currentFormat, NSString *destinationFormat) {
	if (nil == stringDate) {
		return [NSString string];
	}
	
    NSDateFormatter *currentFormatter = [[NSDateFormatter alloc] init];
    BOOL useRelativeDate = [[NSUserDefaults standardUserDefaults] boolForKey:@"useRelativeDate"];
    [currentFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [currentFormatter setDateFormat:currentFormat];
    NSDate *date = [currentFormatter dateFromString:stringDate];
    NSString *formattedDate;
    
    if(useRelativeDate) {
        formattedDate = relativeDateFromDate(date);
    } else {
        NSDateFormatter *destinationFormatter = [[NSDateFormatter alloc] init];
        [destinationFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
        [destinationFormatter setDateFormat:destinationFormat];
        formattedDate = [destinationFormatter stringFromDate:date];
        
        [destinationFormatter release];
    }
    
    [currentFormatter release];
	return formattedDate;
}

NSString* relativeDate(NSString *isoDate) {
    if (nil == isoDate) {
		return [NSString string];
	}
	NSDate *convertedDate = dateFromIso(isoDate);

    return relativeDateFromDate(convertedDate);
}

NSString* relativeDateFromDate(NSDate *objDate) {
    if (nil == objDate) {
		return [NSString string];
	}
    
    NSDate *todayDate = [NSDate date];
    double ti = [objDate timeIntervalSinceDate:todayDate];
    ti = ti * -1;
    
    //FIXME: Solve Plural/nonplural for other localizations
    
    if(ti < 1) {
        return NSLocalizedString(@"relative.date.just-now", @"just now");
    } else      if (ti < 60) {
        return NSLocalizedString(@"relative.date.less-than-a-minute-ago", @"less than a minute ago");
    } else if (ti < 3600) {
        int diff = round(ti / 60);
        NSString *plural = diff > 1? @"s": @"";
        return [NSString stringWithFormat:NSLocalizedString(@"relative.date.minutes-ago", @"%d minute%@ ago"), diff, plural];
    } else if (ti < 86400) {
        int diff = round(ti / 60 / 60);
        NSString *plural = diff > 1? @"s": @"";
        return[NSString stringWithFormat:NSLocalizedString(@"relative.date.hours-ago", @"%d hour%@ ago"), diff, plural];
    } else {
        int diff = round(ti / 60 / 60 / 24);
        NSString *plural = diff > 1? @"s": @"";
        return[NSString stringWithFormat:NSLocalizedString(@"relative.date.days-ago", @"%d day%@ ago"), diff, plural];
    }  
}

// Is "useRelativeDate" Setting aware
NSString* formatDocumentDate(NSString *isoDate) {
    BOOL useRelativeDate = [[NSUserDefaults standardUserDefaults] boolForKey:@"useRelativeDate"];
    
    if(useRelativeDate) {
        return relativeDate(isoDate);
    } else {
        return formatDateTime(isoDate);
    }
}

// Is "useRelativeDate" Setting aware
NSString* formatDocumentDateFromDate(NSDate *dateObj) {
    BOOL useRelativeDate = [[NSUserDefaults standardUserDefaults] boolForKey:@"useRelativeDate"];
    
    if(useRelativeDate) {
        return relativeDateFromDate(dateObj);
    } else {
        return formatDateTimeFromDate(dateObj);
    }
}

NSString* replaceStringWithNamedParameters(NSString *stringTemplate, NSDictionary *namedParameters) {
    NSString *key = nil;
    
    for(key in namedParameters) {
        NSString *parameter = [NSString stringWithFormat:@"{%@}", key];
        stringTemplate = [stringTemplate stringByReplacingOccurrencesOfString:parameter withString:[namedParameters objectForKey:key]];
    }
    
    return stringTemplate;
}

BOOL stringToBoolWithNumericDefault(NSString *string, NSNumber* defaultValue)
{
    if ([defaultValue isEqualToNumber:[NSNumber numberWithInt:0]]) {
        return stringToBoolWithDefault(string, NO);
    } else {
        return stringToBoolWithDefault(string, YES);
    }
}

BOOL stringToBoolWithDefault(NSString *string, BOOL defaultValue)
{
    BOOL retv = defaultValue;
    if (nil == string) return retv;
    NSString *comp = [[string lowercaseString] trimWhiteSpace];
    if (NO == defaultValue) {
        if ([comp isEqualToString:@"yes"]) retv = YES;
        if ([comp isEqualToString:@"true"]) retv = YES;
        if ([comp isEqualToString:@"1"]) retv = YES;
    } else {
        if ([comp isEqualToString:@"no"]) retv = NO;
        if ([comp isEqualToString:@"false"]) retv = NO;
        if ([comp isEqualToString:@"0"]) retv = NO;
    }
    return retv;
}

NSString *defaultString(NSString *string, NSString *defaultValue)
{
    if (nil != string && [string length] > 0) return string;
    return defaultValue;
}

BOOL addSkipBackupAttributeToItemAtURL(NSURL *URL)
{
    const char* filePath = [[URL path] fileSystemRepresentation];
    const char* attrName = "com.apple.MobileBackup";
    u_int8_t attrValue = 1;
    
    int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
    return result == 0;
}

BOOL getBackupAttributeFromItemAtURL(NSURL *URL)
{
    const char* filePath = [[URL path] fileSystemRepresentation];
    const char* attrName = "com.apple.MobileBackup";
    u_int8_t attrValue = 0;
    
    getxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
    return (attrValue > 0);
}

void showOfflineModeAlert(NSString *url)
{
    NSString *failureMessage = [NSString stringWithFormat:NSLocalizedString(@"serviceDocumentRequestFailureMessage", @"Failed to connect to the repository"),
                                url];
    
    UIAlertView *sdFailureAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"serviceDocumentRequestFailureTitle", @"Error")
                                                              message:failureMessage
                                                             delegate:nil 
                                                    cancelButtonTitle:NSLocalizedString(@"Continue", nil)
                                                    otherButtonTitles:nil] autorelease];
    [sdFailureAlert show];

}

void styleButtonAsDefaultAction(UIBarButtonItem *button)
{
    UIColor *actionColor = [UIColor colorWithHue:0.61 saturation:0.44 brightness:0.9 alpha:0];
    if ([button respondsToSelector:@selector(setTintColor:)])
    {
        [button setTintColor:actionColor];
    }
}
