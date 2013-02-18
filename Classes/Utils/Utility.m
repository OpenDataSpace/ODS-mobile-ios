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
#import "AlfrescoAppDelegate.h"
#import "DetailNavigationController.h"
#import "AppProperties.h"
#import <Security/SecureTransport.h>

static NSDictionary *iconMappings;
static NSDictionary *mimeMappings;
static NSDictionary *apiKeys;


UIImage *imageForFilename(NSString *filename)
{
    NSString *fileExtension = filename.pathExtension;
    if (fileExtension && (fileExtension.length > 0))
    {
        NSString *potentialImageName = [fileExtension stringByAppendingPathExtension:@"png"];
        UIImage *potentialImage = [UIImage imageNamed:potentialImageName];
        if (nil != potentialImage) 
        {
            return potentialImage;
        }
    }
    
	NSString *imageName = nil;
    if (!iconMappings)
    {
        NSString *mappingsPath = [[NSBundle mainBundle] pathForResource:@"IconMappings" ofType:@"plist"];
        iconMappings = [[NSDictionary alloc] initWithContentsOfFile:mappingsPath];
    }
	NSUInteger location = [filename rangeOfString:@"." options:NSBackwardsSearch].location;
	if (location != NSNotFound)
    {
		NSString *ext = [[filename substringFromIndex:location] lowercaseString];
		if ([iconMappings objectForKey:ext])
        {
			imageName = [iconMappings objectForKey:ext];
		}
	}
    
    if (imageName == nil || imageName.length == 0)
    {
        imageName = @"generic.png";
    }

	return [UIImage imageNamed:imageName];
}

NSString *mimeTypeForFilename(NSString *filename)
{
    return mimeTypeForFilenameWithDefault(filename, @"text/plain");
}

NSString *mimeTypeForFilenameWithDefault(NSString *filename, NSString *defaultMimeType)
{
    NSString *fileExtension = filename.pathExtension.lowercaseString;
    NSString *mimeType = defaultMimeType;
    
    if (!mimeMappings)
    {
        NSString *mimeMappingsPath = [[NSBundle mainBundle] pathForResource:@"MimeMappings" ofType:@"plist"];
        mimeMappings = [[NSDictionary alloc] initWithContentsOfFile:mimeMappingsPath];
    }
    
    if (fileExtension && (fileExtension.length > 0) && [mimeMappings objectForKey:fileExtension])
    {
        mimeType = [mimeMappings objectForKey:fileExtension];
    } 
    
    return mimeType;
}

BOOL isVideoExtension(NSString *extension)
{
    static NSArray *videoExtensions = nil;
    extension = [extension lowercaseString];
    
    if (!videoExtensions)
    {
        videoExtensions = [[NSArray arrayWithObjects:@"mov", @"mp4", @"mpv", @"3gp", @"m4v", nil] retain];
    }
    
    return [videoExtensions containsObject:extension];
}

BOOL isAudioExtension(NSString *extension)
{
    static NSArray *audioExtensions;
    extension = [extension lowercaseString];
    
    if (!audioExtensions)
    {
        //From http://stackoverflow.com/questions/4461898/getting-file-type-audio-or-video-in-ios
        audioExtensions = [[NSArray arrayWithObjects:@"mp3", @"m4p", @"m4a", @"aac", @"wav", @"caf", nil] retain];
    }
    
    return [audioExtensions containsObject:extension];
}

BOOL isPhotoExtension(NSString *extension)
{
    static NSArray *photoExtensions = nil;
    extension = [extension lowercaseString];
    
    if (!photoExtensions)
    {
        photoExtensions = [[NSArray arrayWithObjects:@"jpg", @"jpeg", @"png", @"bmp", @"tiff", @"tif", @"gif", nil] retain];
    }
    
    return [photoExtensions containsObject:extension];
}

BOOL isMimeTypeVideo(NSString *mimeType)
{
    return [[mimeType lowercaseString] hasPrefix:@"video/"];
}

NSString *createStringByEscapingAmpersandsInsideTagsOfString(NSString *input, NSString *startTag, NSString *endTag)
{
	NSMutableString *escapedString = [NSMutableString stringWithString:@""];
    NSArray *pieces = [input componentsSeparatedByString:startTag];
	
	if (pieces.count > 0)
    {
		[escapedString appendString:[pieces objectAtIndex:0]];
		
		for (int i = 1; i < pieces.count; i++)
        {
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

void startSpinner()
{
	if (spinnerCount <= 0)
    {
		spinnerCount = 0;
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	}
	spinnerCount++;
}

void stopSpinner() 
{
	spinnerCount--;
	if (spinnerCount <= 0)
    {
		spinnerCount = 0;
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	}
}

BOOL userPrefShowHiddenFiles()
{
	return [[FDKeychainUserDefaults standardUserDefaults] boolForKey:@"showHidden"];
}

BOOL userPrefShowCompanyHome()
{
    return [[FDKeychainUserDefaults standardUserDefaults] boolForKey:@"showCompanyHome"];	
}

BOOL userPrefFullTextSearch()
{
	return [[FDKeychainUserDefaults standardUserDefaults] boolForKey:@"fullTextSearch"];
}

BOOL userPrefValidateSSLCertificate()
{
	return [[FDKeychainUserDefaults standardUserDefaults] boolForKey:@"validateSSLCertificate"];
}

NSDate*dateFromIso(NSString *isoDate)
{
	ISO8601DateFormatter *isoFormatter = [[[ISO8601DateFormatter alloc] init] autorelease];
    NSDate *formattedDate = [isoFormatter dateFromString:isoDate];
	return formattedDate;
}

NSString *formatDateTime(NSString *isoDate)
{
	if (nil == isoDate)
    {
		return @"";
	}
	
	NSDate *date = dateFromIso(isoDate);
	return formatDateTimeFromDate(date);
}

NSString *formatDateTimeFromDate(NSDate *dateObj)
{
	if (nil == dateObj)
    {
		return @"";
	}

	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];

	NSString *humanReadableDate = [dateFormatter stringFromDate:dateObj];
	return humanReadableDate;
}

// Is "useRelativeDate" Setting aware
NSString *changeStringDateToFormat(NSString *stringDate, NSString *currentFormat, NSString *destinationFormat)
{
	if (nil == stringDate)
    {
		return @"";
	}
	
    NSDateFormatter *currentFormatter = [[[NSDateFormatter alloc] init] autorelease];
    BOOL useRelativeDate = [[FDKeychainUserDefaults standardUserDefaults] boolForKey:@"useRelativeDate"];
    [currentFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [currentFormatter setDateFormat:currentFormat];
    NSDate *date = [currentFormatter dateFromString:stringDate];
    NSString *formattedDate;
    
    if (useRelativeDate)
    {
        formattedDate = relativeDateFromDate(date);
    }
    else
    {
        NSDateFormatter *destinationFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [destinationFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
        [destinationFormatter setDateFormat:destinationFormat];
        formattedDate = [destinationFormatter stringFromDate:date];
    }
    
	return formattedDate;
}

NSString *relativeDate(NSString *isoDate)
{
    if (nil == isoDate)
    {
		return @"";
	}

	NSDate *convertedDate = dateFromIso(isoDate);
    return relativeDateFromDate(convertedDate);
}

NSString *relativeDateFromDate(NSDate *objDate)
{
    if (nil == objDate)
    {
		return @"";
	}
    
    NSDate *todayDate = [NSDate date];
    double ti = [objDate timeIntervalSinceDate:todayDate];
    ti = ti * -1;
    
    NSString *key = nil;
    int diff = 0;
    
    if (ti < 1)
    {
        key = @"relative.date.just-now";
    }
    else if (ti < 60)
    {
        key = @"relative.date.less-than-a-minute-ago";
    }
    else if (ti < 3600)
    {
        diff = round(ti / 60);
        key = (diff > 1) ? @"relative.date.n-minutes-ago" : @"relative.date.one-minute-ago";
    }
    else if (ti < 86400)
    {
        diff = round(ti / 60 / 60);
        key = (diff > 1) ? @"relative.date.n-hours-ago" : @"relative.date.one-hour-ago";
    }
    else
    {
        diff = round(ti / 60 / 60 / 24);
        key = (diff > 1) ? @"relative.date.n-days-ago" : @"relative.date.one-day-ago";
    }
    
    return [NSString stringWithFormat:NSLocalizedString(key, @"Localized relative date string"), diff];
}

NSString *relativeIntervalFromSeconds(NSTimeInterval seconds)
{
    NSString *timeFormat = nil;
    int diff = 0;
    
    if (seconds > (60 * 60 * 24))
    {
        diff = seconds / 60 / 60 / 24;
        timeFormat = (diff > 1) ? @"relative.interval.n-days" : @"relative.interval.one-day";
    }
    else if (seconds > (60 * 60))
    {
        diff = seconds / 60 / 60;
        timeFormat = (diff > 1) ? @"relative.interval.n-hours" : @"relative.interval.one-hour";
    }
    else if (seconds > 60)
    {
        diff = seconds / 60;
        timeFormat = (diff > 1) ? @"relative.interval.n-minutes" : @"relative.interval.one-minute";
    }
    else
    {
        diff = seconds;
        timeFormat = (diff > 1) ? @"relative.interval.n-seconds" : @"relative.interval.one-second";
    }
    
    return [NSString stringWithFormat:NSLocalizedString(timeFormat, @"Localized relative date string"), diff];
}

// Is "useRelativeDate" Setting aware
NSString *formatDocumentDate(NSString *isoDate)
{
    BOOL useRelativeDate = [[FDKeychainUserDefaults standardUserDefaults] boolForKey:@"useRelativeDate"];
    
    if (useRelativeDate)
    {
        return relativeDate(isoDate);
    }
    return formatDateTime(isoDate);
}

// Is "useRelativeDate" Setting aware
NSString *formatDocumentDateFromDate(NSDate *dateObj)
{
    BOOL useRelativeDate = [[FDKeychainUserDefaults standardUserDefaults] boolForKey:@"useRelativeDate"];
    
    if (useRelativeDate)
    {
        return relativeDateFromDate(dateObj);
    }
    return formatDateTimeFromDate(dateObj);
}

NSString *replaceStringWithNamedParameters(NSString *stringTemplate, NSDictionary *namedParameters)
{
    NSString *key = nil;
    
    for (key in namedParameters)
    {
        NSString *parameter = [NSString stringWithFormat:@"{%@}", key];
        stringTemplate = [stringTemplate stringByReplacingOccurrencesOfString:parameter withString:[namedParameters objectForKey:key]];
    }
    
    return stringTemplate;
}

BOOL stringToBoolWithNumericDefault(NSString *string, NSNumber *defaultValue)
{
    if ([defaultValue isEqualToNumber:[NSNumber numberWithInt:0]])
    {
        return stringToBoolWithDefault(string, NO);
    }
    return stringToBoolWithDefault(string, YES);
}

BOOL stringToBoolWithDefault(NSString *string, BOOL defaultValue)
{
    BOOL retv = defaultValue;
    if (nil == string)
    {
        return retv;
    }
    NSString *comp = [[string lowercaseString] trimWhiteSpace];
    if (NO == defaultValue)
    {
        if ([comp isEqualToString:@"yes"]) retv = YES;
        if ([comp isEqualToString:@"true"]) retv = YES;
        if ([comp isEqualToString:@"1"]) retv = YES;
    }
    else
    {
        if ([comp isEqualToString:@"no"]) retv = NO;
        if ([comp isEqualToString:@"false"]) retv = NO;
        if ([comp isEqualToString:@"0"]) retv = NO;
    }
    return retv;
}

NSString *defaultString(NSString *string, NSString *defaultValue)
{
    if (nil != string && [string length] > 0)
    {
        return string;
    }
    return defaultValue;
}

// Working around <rdar://problem/11017158>> by forcing the symbol to be weak import
// and prevent "dyld: Symbol not found: _NSURLIsExcludedFromBackupKey" when running
// in iOS ver < 5.1
// Note: we also need to link CoreFoundation.framework and make it optional!
// See discussion at https://github.com/ShareKit/ShareKit/pull/394
extern NSString *const NSURLIsExcludedFromBackupKey __attribute__((weak_import));

BOOL addSkipBackupAttributeToItemAtURL(NSURL *URL)
{
    BOOL returnValue = NO;

    if (SYSTEM_VERSION_LESS_THAN(@"5.1"))
    {
        const char *filePath = [[URL path] fileSystemRepresentation];
        const char *attrName = "com.apple.MobileBackup";
        u_int8_t attrValue = 1;
        
        int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
        returnValue = (result == 0);
    }
    else
    {
        NSError *error = nil;
        returnValue = [URL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&error];
    }
    
    return returnValue;
}

void showConnectionErrorMessage(ASIHTTPRequest *request)
{
    showConnectionErrorMessageWithError(request, request.error);
}

void showConnectionErrorMessageWithError(ASIHTTPRequest *request, NSError *error)
{
    // Quick fix to show the public cloud URL instead of the API endpoint
    NSString *cloudHostname = [AppProperties propertyForKey:kAlfrescoCloudHostname];
    NSString *cleanedUrl = [request.url.host stringByReplacingOccurrencesOfString:@"a.alfresco.me" withString:cloudHostname];
    NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(@"serviceDocumentRequestFailureMessage", @"Failed to connect to the repository"), cleanedUrl];
    NSString *errorTitle = NSLocalizedString(@"asihttprequest.connection.failure", @"A connection failure occurred");

    // Check the underlying error for an SSL-related issue
    NSError *underlyingError = [error.userInfo objectForKey:NSUnderlyingErrorKey];

    // Note underlying error codes are -ve, hence the "backwards" range check here...
    if ([error.domain isEqualToString:NetworkRequestErrorDomain] && errSSLProtocol > underlyingError.code && underlyingError.code > errSSLLast)
    {
        errorMessage = error.localizedDescription;
        errorTitle = cleanedUrl;
    }

    displayErrorMessageWithTitle(errorMessage, errorTitle);
}

void styleButtonAsDefaultAction(UIBarButtonItem *button)
{
    if ([button respondsToSelector:@selector(setTintColor:)])
    {
        UIColor *actionColor = [UIColor colorWithHue:0.61 saturation:0.44 brightness:0.9 alpha:0];
        [button setTintColor:actionColor];
    }
}

void styleButtonAsDestructiveAction(UIBarButtonItem *button)
{
    if ([button respondsToSelector:@selector(setTintColor:)])
    {
        UIColor *actionColor = [UIColor colorWithHue:0 saturation:0.80 brightness:0.71 alpha:0];
        [button setTintColor:actionColor];
    }
}

#pragma mark - MBProgressHUD

/**
 * Utility methods to help make our use of MBProgressHUD more consistent
 */

MBProgressHUD *createProgressHUDForView(UIView *view)
{
    // Protecting the app when we try to initialize a HUD and the view is not init'd yet
    if(!view)
    {
        return nil;
    }
    
    MBProgressHUD *hud = [[[MBProgressHUD alloc] initWithView:view] autorelease];
    [hud setRemoveFromSuperViewOnHide:YES];
    [hud setTaskInProgress:YES];
    [hud setMode:MBProgressHUDModeIndeterminate];
    [hud setMinShowTime:kHUDMinShowTime];
    [hud setGraceTime:KHUDGraceTime];
	[view addSubview:hud];
    return hud;
}

MBProgressHUD *createAndShowProgressHUDForView(UIView *view)
{
    MBProgressHUD *hud = createProgressHUDForView(view);
    [hud show:YES];
    return hud;
}

void stopProgressHUD(MBProgressHUD *hud)
{
    [hud setTaskInProgress:NO];
    [hud setDelegate:nil];
    [hud hide:YES];
}

/**
 * Utility method to retreive external API keys that are not committed to source control.
 * Keys are passed from ENV vars to the compiler via the OTHER_CFLAGS in the target's .xcconfig file.
 */
NSString *externalAPIKey(APIKey apiKey)
{
    if (!apiKeys)
    {
        // We could use an NSArray here, but the binding between enum value and array index would be weak
        apiKeys = [[NSDictionary alloc] initWithObjectsAndKeys:
                   API_FLURRY, [NSNumber numberWithInt:APIKeyFlurry],
                   API_QUICKOFFICE, [NSNumber numberWithInt:APIKeyQuickoffice],
                   API_ALFRESCO_CLOUD, [NSNumber numberWithInt:APIKeyAlfrescoCloud],
                   nil];
    }
    return [apiKeys objectForKey:[NSNumber numberWithInt:apiKey]];
}

/**
 * Notice Messages
 */
SystemNotice *displayErrorMessage(NSString *message)
{
    return displayErrorMessageWithTitle(message, nil);
}

SystemNotice *displayErrorMessageWithTitle(NSString *message, NSString *title)
{
    return [SystemNotice showErrorNoticeInView:activeView() message:message title:title];
}

SystemNotice *displayWarningMessageWithTitle(NSString *message, NSString *title)
{
    return [SystemNotice showWarningNoticeInView:activeView() message:message title:title];
}

SystemNotice *displayInformationMessage(NSString *message)
{
    return [SystemNotice showInformationNoticeInView:activeView() message:message];
}

UIView *activeView(void)
{
    AlfrescoAppDelegate *appDelegate = (AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate];
    DetailNavigationController *detailNavigation = (DetailNavigationController *)[[(UISplitViewController *)appDelegate.mainViewController viewControllers] objectAtIndex:1];
    if (appDelegate.mainViewController.presentedViewController)
    {
        //To work around a system notice that is tried to be presented in a modal view controller
        return appDelegate.mainViewController.presentedViewController.view;
    }
    else if (IS_IPAD)
    {
        if (detailNavigation.masterPopoverController.popoverVisible)
        {
            // Work around for displaying the alert on top of the UIPopoverView in Portrait mode
            return appDelegate.mainViewController.view.superview;
        }
        else if (detailNavigation.isExpanded)
        {
            return detailNavigation.view;
        }
    }
    return appDelegate.mainViewController.view;
}
