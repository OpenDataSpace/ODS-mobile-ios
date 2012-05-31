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
//  Activity.m
//

#import "Activity.h"
#import "Utility.h"
#import "SBJSON.h"
#import "TTTAttributedLabel.h"
#import "AccountInfo.h"

@interface Activity(PrivateMethods)
- (NSString *) stringForKey: (NSString *) key inDictionary: (NSDictionary *) dictionary;
- (NSArray *) activityDocumentType;
@end

@implementation Activity
@synthesize activityType;
@synthesize accountUUID;
@synthesize tenantID;

static CGFloat const kBoldTextFontSize = 17;
static NSArray *headers;
static NSArray *activityDocumentTypes;


- (void) dealloc 
{
    [itemTitle release];
    [user release];
    [following release];
    [custom1 release];
    [custom2 release];
    [status release];
    [siteLink release];
    [activityType release];
    [postDate release];
    [replacedActivityText release];
    [objectId release];
    [mutableString release];
    [accountUUID release];
    [tenantID release];
    
    [super dealloc];
}

- (Activity *) initWithJsonDictionary:(NSDictionary *) json {
    
    self = [super init];
    
    if(self) {
        activityType = [[json objectForKey:@"activityType"] copy];
        
        
        SBJSON *jsonObj = [SBJSON new];
        NSDictionary *activitySummary = [jsonObj objectWithString:[json objectForKey:@"activitySummary"]];
        [jsonObj release];
        
        itemTitle = [[self stringForKey:@"title" inDictionary:activitySummary] copy];
        
        if ([activityType isEqualToString:@"org.alfresco.site.user-joined"] ||
            [activityType isEqualToString:@"org.alfresco.site.user-left"] ||
            [activityType isEqualToString:@"org.alfresco.site.user-role-changed"])
        {
            user = [[NSString stringWithFormat:@"%@ %@", [self stringForKey:@"memberFirstName" inDictionary:activitySummary], [self stringForKey:@"memberLastName" inDictionary:activitySummary]] copy];
        }
        else
        {
            user = [[NSString stringWithFormat:@"%@ %@", [self stringForKey:@"firstName" inDictionary:activitySummary], [self stringForKey:@"lastName" inDictionary:activitySummary]] copy];
            
            following = [[NSString stringWithFormat:@"%@ %@", [self stringForKey:@"userFirstName" inDictionary:activitySummary], [self stringForKey:@"userLastName" inDictionary:activitySummary]] copy];
            
        }
        status = [[self stringForKey:@"status" inDictionary:activitySummary] copy];

        //seems like custom1 is always the role
        custom1 = [[self stringForKey:@"role" inDictionary:activitySummary] copy];
        //seems like custom2 is not used
        custom2 = [[NSString stringWithString:@""] copy];
        objectId = [[self stringForKey:@"nodeRef" inDictionary:activitySummary] copy];
        
        siteLink = [[self stringForKey:@"siteNetwork" inDictionary:json] copy];
        
        NSDate *formattedDate = dateFromIso([self stringForKey:@"postDate" inDictionary:json]);
        postDate = [formattedDate retain];
        
        NSArray *documentsType = [self activityDocumentType];
        isDocument = [documentsType containsObject:activityType];
        
        self.accountUUID = [json objectForKey:@"accountUUID"];
        self.tenantID = [json objectForKey:@"tenantID"];
    }
    
    if(headers == nil) {
        headers = [[NSArray arrayWithObjects:@"Today", @"Yesterday", @"Older", nil] retain];
    }
    
    return self;
}

// We need to try and force any object to string
- (NSString *) stringForKey: (NSString *) key inDictionary: (NSDictionary *) dictionary {
    id val = [dictionary objectForKey:key];
    
    if([val respondsToSelector:@selector(stringValue)]) {
        return [val performSelector:@selector(stringValue)];
    } else if(val == nil){
        return @"";
    } else {
        return val;
    }
}

- (NSString *)activityText {
    if(replacedActivityText == nil) {
        NSString *text = NSLocalizedStringFromTable(activityType, @"Activities", @"Activity type text");
        
        
        replacedActivityText = [[self replaceIndexPointsIn:text withValues: [self replacements]] retain];
    }
    
    return replacedActivityText;
}

- (NSString *) replaceIndexPointsIn:(NSString *)string withValues:(NSArray *) replacements {
    
    for(NSInteger index = 0; index < [replacements count]; index++) {
        NSString *indexPoint = [NSString stringWithFormat:@"{%d}", index];
        
        string = [string stringByReplacingOccurrencesOfString:indexPoint withString:[replacements objectAtIndex:index]];
    }
    
    return string;
}

- (NSArray *)replacements {
 
    return [NSArray arrayWithObjects:itemTitle, user, custom1, custom2, siteLink,following,status, nil];
}

- (NSMutableAttributedString *) boldReplacements:(NSArray *) replacements inString:(NSMutableAttributedString *)attributed {
    if(!mutableString) {
        UIFont *boldSystemFont = [UIFont boldSystemFontOfSize:kBoldTextFontSize]; 
        CTFontRef boldFont = CTFontCreateWithName((CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
        
        for(NSInteger index = 0; index < [replacements count]; index++) {
            NSString *replacement = [replacements objectAtIndex:index];
            NSRange replacementRange = [attributed.string rangeOfString:replacement];
            
            if (replacementRange.length > 0 && boldFont) {
                [attributed addAttribute:(NSString *)kCTFontAttributeName value:(id)boldFont range:replacementRange];
            }
        }
        
        if(boldFont) CFRelease(boldFont);
        mutableString = [attributed retain];
    }
    
    return mutableString;
}

- (NSString *)activityDate {
    return formatDocumentDateFromDate(postDate);
}

- (NSString *)groupHeader {
    NSCalendar *cal = [NSCalendar currentCalendar];
    
    NSDateComponents *postDateComponents =
        [cal components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:postDate];
    NSDateComponents *todayComponents =
        [cal components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[NSDate date]];
    NSDate *today = [cal dateFromComponents:todayComponents];
    NSDate *postDateDay = [cal dateFromComponents:postDateComponents];
    
    NSTimeInterval interval = [today timeIntervalSinceDate:postDateDay];
    
    if(interval == 0) {
        return [headers objectAtIndex:0];
    } else if(interval ==  60*60*24){
        return [headers objectAtIndex:1];
    } else {
        return [headers objectAtIndex:2];
    }
    

}

- (UIImage *) iconImage {
    if(isDocument) {
        //The itemTitle is the file name when the activity is related to a document
        return imageForFilename(itemTitle);
    } else {
        return [UIImage imageNamed:@"avatar.png"];
    }
}

- (NSString *) objectId {
    return objectId;
}

- (BOOL)isDocument {
    return isDocument;
}

#pragma mark - private methods
- (NSArray *) activityDocumentType {
    if(!activityDocumentTypes) {
        activityDocumentTypes = [[NSArray arrayWithObjects:@"org.alfresco.documentlibrary.file-added",
                                            @"org.alfresco.documentlibrary.file-created",
                                            @"org.alfresco.documentlibrary.file-deleted",
                                            @"org.alfresco.documentlibrary.file-updated",
                                            @"org.alfresco.documentlibrary.file-liked", nil] retain];
    }
    
    return activityDocumentTypes;
}

@end
