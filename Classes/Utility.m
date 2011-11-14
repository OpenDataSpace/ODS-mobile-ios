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
//
//  Utility.m
//  Alfresco
//

#import "Utility.h"
#import "ISO8601DateFormatter.h"
#import "NSString+Trimming.h"
#import "RepositoryServices.h"
#import "AppProperties.h"

#define DEFAULT_HTTP_PORT @"80"
#define DEFAULT_HTTPS_PORT @"443"
#define HTTP @"http"
#define HTTPS @"https"

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
	NSDictionary *mapping = [NSDictionary dictionaryWithObjectsAndKeys:
							 @"img.png", @".png", 
							 @"img.png", @".jpeg", 
							 @"img.png", @".jpg", 
							 @"img.png", @".gif", 
							 @"doc.png", @".doc", 
							 @"doc.png", @".docx", 
							 @"xls.png", @".xls", 
							 @"xls.png", @".xlsx", 
							 @"ppt.png", @".ppt", 
							 @"ppt.png", @".pptx", 
							 @"xml.png", @".xml", 
							 @"txt.png", @".txt", 
							 @"pdf.png", @".pdf", 
							 @"archive.png", @".zip", 
							 @"archive.png", @".sit", 
							 @"archive.png", @".gz", 
							 @"archive.png", @".tar", 
							 @"audio.png", @".mp3", 
							 @"audio.png", @".wav", 
							 @"img.png", @".tif", 
							 @"img.png", @".tiff", 
							 nil];
	NSUInteger location = [filename rangeOfString:@"." options: NSBackwardsSearch].location;
	if (location != NSNotFound) {
		NSString *ext = [[filename substringFromIndex:location] lowercaseString];
		if ([mapping objectForKey:ext]) {
			imageName = [mapping objectForKey:ext];
		}
	}
    
    if (imageName == nil || [imageName length] == 0) {
        imageName = @"generic.png";
    }

	return [UIImage imageNamed:imageName];
}

NSString* mimeTypeForFilename(NSString* filename) 
{
    
    NSString *fileExtension = [filename pathExtension];
    fileExtension = [fileExtension lowercaseString];
    NSString *mimeType = @"text/plain";
    static NSDictionary *mimeMapping = nil;
    
    if(!mimeMapping) {
        mimeMapping = [[NSDictionary dictionaryWithObjectsAndKeys:
                       @"image/png", @"png", 
                       @"image/jpeg", @"jpeg", 
                       @"image/jpeg", @"jpg", 
                       @"image/gif", @"gif", 
                       @"application/msword", @"doc", 
                       @"application/msword", @"docx", 
                       @"application/vnd.ms-excel", @"xls", 
                       @"application/vnd.ms-excel", @"xlsx", 
                       @"application/vnd.ms-powerpoint", @"ppt", 
                       @"application/vnd.ms-powerpoint", @"pptx", 
                       @"text/xml", @"xml", 
                       @"text/plain", @"txt", 
                       @"application/pdf", @"pdf", 
                       @"application/zip", @"zip", 
                       @"application/stuffit", @"sit", 
                       @"application/x-gzip", @"gz", 
                       @"application/x-tar", @"tar", 
                       @"audio/mpeg", @"mp3", 
                       @"audio/vnd.wave", @"wav", 
                       @"image/tiff", @"tif", 
                       @"image/tiff", @"tiff", 
                       @"video/quicktime", @"mov", 
                       @"audio/m4a", @"m4a", 
                       nil] retain];
    }

    if (fileExtension && ([fileExtension length] > 0) && [mimeMapping
         objectForKey:fileExtension])
    {
        mimeType = [mimeMapping objectForKey:fileExtension];
    } 
    
    return mimeType;
}

BOOL isVideoExtension(NSString *extension) {
    static NSArray *videoExtensions = nil;
    extension = [extension lowercaseString];
    
    if(!videoExtensions) {
        videoExtensions = [[NSArray arrayWithObjects:@"mov", @"mp4", @"mpv", @"3gp",
                        nil] retain];
    }
    
    return [videoExtensions containsObject:extension];
}

BOOL isMimeTypeVideo(NSString *mimeType) {
    static NSArray *videoMimeTypes = nil;
    mimeType = [mimeType lowercaseString];
    
    if(!videoMimeTypes) {
        videoMimeTypes = [[NSArray arrayWithObjects:
                            @"video/quicktime", @"video/mp4", @"video/mpv", @"video/3gpp", @"video/3gp",
                            nil] retain];
    }
    
    return [videoMimeTypes containsObject:mimeType];
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

NSString* userPrefUsername() 
{
	return [[[NSUserDefaults standardUserDefaults] stringForKey:@"username"] 
            stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

NSString* userPrefPassword() 
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:@"password"];
}

NSString* userPrefHostname() 
{
	return [[[NSUserDefaults standardUserDefaults] stringForKey:@"host"] 
            stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

NSString* userPrefPort() 
{
    NSString *port = [[NSUserDefaults standardUserDefaults] stringForKey:@"port"];
    
    if ((nil != port)) 
    {
        port = [port stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        //
        // TODO: We should move this validation into the app delegate or somewhere such that this is only executed once per session
        //
        
        BOOL updateSettings = NO;
        if ([port length] == 0)
        {
            updateSettings = YES;
            port = nil;            
        }
        else if ([port isEqualToString:DEFAULT_HTTP_PORT] && [HTTPS isEqualToString:userPrefProtocol()])
        {
            port = DEFAULT_HTTPS_PORT;
            updateSettings = YES;
        }
        else if ([port isEqualToString:DEFAULT_HTTPS_PORT] && [HTTP isEqualToString:userPrefProtocol()])
        {
            port = DEFAULT_HTTP_PORT;
            updateSettings = YES;
        }

        if (updateSettings) 
        {
            [[NSUserDefaults standardUserDefaults] setObject:port forKey:@"port"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    
    if (port == nil) {
        port = (([@"https" isEqualToString:userPrefProtocol()]) ? @"443" : @"80");
    }
    
	return port;
}

NSString* serviceDocumentURIString()
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *serviceDocumentURI = [[userDefaults objectForKey:@"webapp"] stringWithTrailingSlashRemoved];
	
	// This will be the new key, we are setting this value so that we can easily remove the 
	// webapp user setting when needed in future releases;
	if (NO == [[userDefaults stringForKey:@"settingsServiceDocumentURI"] isEqualToString:serviceDocumentURI]) {
		[userDefaults setObject:serviceDocumentURI forKey:@"settingsServiceDocumentURI"];
		[userDefaults synchronize];
	}
	
	return serviceDocumentURI;		
}

BOOL userPrefShowHiddenFiles() {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"showHidden"];
}

BOOL userPrefShowCompanyHome() {
	if ([[RepositoryServices shared] isCurrentRepositoryVendorNameEqualTo:kAlfrescoRepositoryVendorName]) {
		return [[NSUserDefaults standardUserDefaults] boolForKey:@"showCompanyHome"];	
	}
	else {	
		return YES;
	}
	
}

NSString* userPrefProtocol() {
	return [[NSUserDefaults standardUserDefaults] objectForKey:@"protocol"];
}

BOOL userPrefFullTextSearch() {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"fullTextSearch"];
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

BOOL isIPad() {
	return IS_IPAD;
}

BOOL isPrintingAvailable() {
    if(NSClassFromString(@"UIPrintInteractionController")) {
        return [UIPrintInteractionController isPrintingAvailable];
    } else {
        return NO;
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
