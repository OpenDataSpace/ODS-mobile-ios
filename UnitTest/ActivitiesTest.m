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
//  ActivitiesTest.m
//

#import <GHUnitIOS/GHUnit.h>
#import "SBJSON.h"
#import "ISO8601DateFormatter.h"
#import "Activity.h"

@interface ActivitiesTest : GHTestCase { }
@end

@implementation ActivitiesTest

- (void)testParse {       
    NSString* path = [[NSBundle mainBundle] pathForResource:@"activities" 
                                                     ofType:@"json"];
    NSString* sampleJson = [NSString stringWithContentsOfFile:path
                                                     encoding:NSUTF8StringEncoding
                                                        error:NULL];
    SBJSON *jsonParser = [SBJSON new];
    id json = [jsonParser objectWithString:sampleJson];
    GHTestLog(@"Json Parsed");
    
    GHAssertNotNil(json, @"parsed json was nil", nil);
    GHAssertTrue([json count] == 70, @"The activities feed must be 70 items long was %d", [json count]);
    
    [jsonParser release];
}

- (void)testActivityTodayGroup {       
    NSString* path = [[NSBundle mainBundle] pathForResource:@"activity_template" 
                                                     ofType:@"json"];
    NSString* jsonTemplate = [NSString stringWithContentsOfFile:path
                                                     encoding:NSUTF8StringEncoding
                                                        error:NULL];
    SBJSON *jsonParser = [SBJSON new];
    ISO8601DateFormatter *isoFormatter = [[ISO8601DateFormatter alloc] init];	
    NSString *formattedDate = [isoFormatter stringFromDate:[NSDate date]];
    
    
    NSString *activityFromToday = [NSString stringWithFormat:jsonTemplate, formattedDate];
    NSDictionary *json = [jsonParser objectWithString:activityFromToday];
    GHTestLog(@"Json Parsed %@", activityFromToday);
    Activity *today = [[Activity alloc] initWithJsonDictionary:json];
    GHTestLog(@"Activity initialized");
    
    GHAssertNotNil(json, @"parsed json was nil", nil);
    GHAssertEqualStrings([today groupHeader], @"Today", @"The group header must be 'Today'", nil);
    
    NSDate *yesterdayDate = [[NSDate date] dateByAddingTimeInterval:-3600*24];
    NSString *formattedDateYesterday = [isoFormatter stringFromDate:yesterdayDate];
    NSString *activityFromYesterday = [NSString stringWithFormat:jsonTemplate, formattedDateYesterday];
    NSDictionary *jsonYesterday = [jsonParser objectWithString:activityFromYesterday];
    GHTestLog(@"Json Parsed %@", activityFromYesterday);
    Activity *yesterday = [[Activity alloc] initWithJsonDictionary:jsonYesterday];
    GHTestLog(@"Activity initialized");
    
    GHAssertNotNil(jsonYesterday, @"parsed json was nil", nil);
    GHAssertEqualStrings([yesterday groupHeader], @"Yesterday", @"The group header must be 'Yesterday'", nil);
    
    NSDate *olderDate = [[NSDate date] dateByAddingTimeInterval:-3600*240];
    NSString *formattedDateOlder = [isoFormatter stringFromDate:olderDate];
    NSString *activityFromOlder = [NSString stringWithFormat:jsonTemplate, formattedDateOlder];
    NSDictionary *jsonOlder = [jsonParser objectWithString:activityFromOlder];
    GHTestLog(@"Json Parsed %@", activityFromOlder);
    Activity *older = [[Activity alloc] initWithJsonDictionary:jsonOlder];
    GHTestLog(@"Activity initialized");
    
    GHAssertNotNil(jsonOlder, @"parsed json was nil", nil);
    GHAssertEqualStrings([older groupHeader], @"Older", @"The group header must be 'Older'", nil);
    
    [isoFormatter release];
    [jsonParser release];
    [today release];
    [yesterday release];
    [older release];
}

/*
 * Using the activities.json we test the first 5 activity text returned by the
 * Activity object.
 * We assume that the file is constant. Plase look at the activities.json file
 * for each of the activity json
 */
- (void)testActivityText {
    NSString* path = [[NSBundle mainBundle] pathForResource:@"activities" 
                                                     ofType:@"json"];
    NSString* sampleJson = [NSString stringWithContentsOfFile:path
                                                     encoding:NSUTF8StringEncoding
                                                        error:NULL];
    SBJSON *jsonParser = [SBJSON new];
    NSArray *json = [jsonParser objectWithString:sampleJson];
    GHTestLog(@"Json Parsed");
    
    GHAssertNotNil(json, @"parsed json was nil", nil);
    GHAssertTrue([json count] == 70, @"The activities feed must be 70 items long was %d", [json count]);
    
    Activity *activity1 = [[Activity alloc] initWithJsonDictionary:[json objectAtIndex:0]];
    GHTestLog(@"Activity test: %@", [activity1 activityText]);
    GHAssertEqualStrings([activity1 activityText], @"Special Announcements wiki page updated by CPG Demo Admin", @"The activity1 text was incorrect", nil);
    
    Activity *activity2 = [[Activity alloc] initWithJsonDictionary:[json objectAtIndex:1]];
    GHTestLog(@"Activity test: %@", [activity2 activityText]);
    GHAssertEqualStrings([activity2 activityText], @"List of Staff (Contact List) data list created by Scott Rost", @"The activity2 text was incorrect", nil);
    
    Activity *activity3 = [[Activity alloc] initWithJsonDictionary:[json objectAtIndex:2]];
    GHTestLog(@"Activity test: %@", [activity3 activityText]);
    GHAssertEqualStrings([activity3 activityText], @"Company BBQ calendar event created by Administrator ", @"The activity3 text was incorrect", nil);
    
    Activity *activity4 = [[Activity alloc] initWithJsonDictionary:[json objectAtIndex:3]];
    GHTestLog(@"Activity test: %@", [activity4 activityText]);
    GHAssertEqualStrings([activity4 activityText], @"CPG Demo joined site cpgdemo with role SiteConsumer", @"The activity4 text was incorrect", nil);
    
    Activity *activity5 = [[Activity alloc] initWithJsonDictionary:[json objectAtIndex:4]];
    GHTestLog(@"Activity test: %@", [activity5 activityText]);
    GHAssertEqualStrings([activity5 activityText], @"Mailings and Communications wiki page updated by CPG Demo Admin", @"The activity5 text was incorrect", nil);
    
    [activity1 release];
    [activity2 release];
    [activity3 release];
    [activity4 release];
    [activity5 release];
    [jsonParser release];

}

@end
