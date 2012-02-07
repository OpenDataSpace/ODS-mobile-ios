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
//  AtomFeedParserTest.m
//

#import <GHUnitIOS/GHUnit.h>
#import "AtomFeedParser.h"
#import "Feed.h"
#import "Entry.h"

@interface AtomFeedParserTest : GHTestCase { }
@end

@implementation AtomFeedParserTest

// Expected values used in testing the testViewVersionsFeed test
static NSString *kViewVersion_ResourceName = @"version-history-feed";
static NSString *kViewVersion_AtomId = @"http://www.alfresco.org/rss/atom/urn:uuid:23150434-4a8b-46d3-82f8-5a166a633d04-versions";
static NSString *kViewVersion_AtomTitle = @"Versions of /Company Home/Sites/gitestsite/documentLibrary";
static int kViewVersion_LinkRelationCt = 3;
static int kViewVersion_AtomEntriesCt = 2;

- (void)testViewVersionsFeed
{
    GHTestLog(@"Begining Test on Parsing Atom Feed for view versions");
    NSString *filePath = [[NSBundle mainBundle] pathForResource:kViewVersion_ResourceName ofType:@"xml"];
    GHAssertNotNil(filePath, @"Resource version-history-feed.xml could not be found", nil);
    
    Feed *feed;
    NSData *xmlData = [NSData dataWithContentsOfFile:filePath];
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:xmlData];
    AtomFeedParser *feedParser = [[AtomFeedParser alloc] init];
    [parser setDelegate:feedParser];
    [parser setShouldProcessNamespaces:YES];
    [parser parse];

    feed = [feedParser currentFeed];
    GHTestLog([feed atomId]);
    GHTestLog([feed atomTitle]);
    GHAssertTrue([kViewVersion_AtomId isEqualToString:[feed atomId]], @"", nil);
    GHAssertTrue([kViewVersion_AtomTitle isEqualToString:[feed atomTitle]], @"", nil);
    GHAssertTrue([[feed linkRelations] count] == kViewVersion_LinkRelationCt, @"", nil);
    GHAssertTrue([[feed atomEntries] count] == kViewVersion_AtomEntriesCt, nil, nil);
    
    NSArray *atomEntries = [feed atomEntries];
    GHAssertTrue((2 == [atomEntries count]), nil, nil);
    
    for (Entry *entry in atomEntries) {
        NSArray *cmisProperties = [entry cmisProperties];
        NSLog(@"%d COUNTX", [cmisProperties count]);
        GHAssertTrue((23 <= [cmisProperties count]), nil, nil);
        GHAssertTrue((0 == [[entry allowableActions] count]), nil, nil);        
        GHAssertTrue((13 == [[entry linkRelations] count]), nil, nil);
    }
    
    [feedParser release];
    [parser release];
}

@end
