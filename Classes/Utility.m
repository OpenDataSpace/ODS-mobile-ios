//
//  ***** BEGIN LICENSE BLOCK *****
//  Version: MPL 1.1
//
//  The contents of this file are subject to the Mozilla Public License Version
//  1.1 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS" basis,
//  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
//  for the specific language governing rights and limitations under the
//  License.
//
//  The Original Code is the Alfresco Mobile App.
//  The Initial Developer of the Original Code is Zia Consulting, Inc.
//  Portions created by the Initial Developer are Copyright (C) 2011
//  the Initial Developer. All Rights Reserved.
//
//
//  ***** END LICENSE BLOCK *****
//
//
//  Utility.m
//

#import "Utility.h"
#import "ISO8601DateFormatter.h"
#import "NSString+Trimming.h"
#import "RepositoryServices.h"

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
        else if ([port isEqualToString:@"80"] && [@"https" isEqualToString:userPrefProtocol()])
        {
            port = @"443";
            updateSettings = YES;
        }
        else if ([port isEqualToString:@"443"] && [@"http" isEqualToString:userPrefProtocol()])
        {
            port = @"80";
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

BOOL userPrefEnableAmpersandHack() {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"ampersandHack"];
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

NSString* formatDateTime(NSString *isoDate) {
	if (nil == isoDate) {
		return [NSString string];
	}
	ISO8601DateFormatter *isoFormatter = [[ISO8601DateFormatter alloc] init];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[NSLocale currentLocale]];
	
	NSDate *date = [isoFormatter dateFromString:isoDate];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	NSString *humanReadableDate = [dateFormatter stringFromDate:date];
	
	[dateFormatter release];
	[isoFormatter release];
	
	return humanReadableDate;
}

BOOL isIPad() {
	return IS_IPAD;
}
