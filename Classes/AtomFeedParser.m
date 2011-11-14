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
//  AtomFeedParser.m
//

#import "AtomFeedParser.h"
#import "AtomEntryParser.h"

@implementation AtomFeedParser
@synthesize currentString;
@synthesize currentFeed;
@synthesize currentEntry;
@synthesize atomEntryParser;

- (void)dealloc
{
    [currentString release];
    [currentFeed release];
    [currentEntry release];
    [atomEntryParser release];
    
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self) {
        storingCharacters = NO;
        [self setCurrentString:[NSMutableString string]];
        [self setCurrentFeed:[[[Feed alloc] init] autorelease]];
    }
    
    return self;
}

#pragma mark - 
#pragma mark NSXMLParserDelegate Methods

static NSString *kCMISCore_Namespace = @"http://docs.oasis-open.org/ns/cmis/core/200908";
static NSString *kCMISRestAtom_Namespace = @"http://docs.oasis-open.org/ns/cmis/restatom/200908";
static NSString *kAtom_Namespace = @"http://www.w3.org/2005/Atom";
static NSString *kAtomPub_Namespace = @"http://www.w3.org/2007/app";

static NSString *kEntry_Element = @"entry";
static NSString *kId_Element = @"id";
static NSString *kTitle_Element = @"title";
static NSString *kLink_Element = @"link";
static NSString *kRel_Item = @"rel";
static NSString *kHref_Item = @"href";
static NSString *kType_Item = @"type";

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if ([kEntry_Element isEqualToString:elementName] && [namespaceURI isEqualToString:kAtom_Namespace]) {
        Entry *entry = [[Entry alloc] init];
        [self setCurrentEntry:entry];
        [[currentFeed atomEntries] addObject:entry];
        [entry release];
        
        AtomEntryParser *entryParser = [[AtomEntryParser alloc] initWithEntry:currentEntry];
        [self setAtomEntryParser:entryParser];
        [entryParser release];
        
    }
    else if ([self currentEntry]) {
        [[self atomEntryParser] parser:parser didStartElement:elementName namespaceURI:namespaceURI qualifiedName:qName attributes:attributeDict];
        
    }
    else {
        if ([namespaceURI isEqualToString:kAtom_Namespace]) {
            
            if ([elementName isEqualToString:kId_Element] || [elementName isEqualToString:kTitle_Element]) {
                [currentString setString:@""];
                storingCharacters = YES;
            }
            else if ([elementName isEqualToString:kLink_Element]) {
                [[currentFeed linkRelations] addObject:attributeDict];
            }
        }
        
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([kEntry_Element isEqualToString:elementName] && [namespaceURI isEqualToString:kAtom_Namespace]) {
        [self setCurrentEntry:nil];
        [self setAtomEntryParser:nil];
    }
    else if ([self currentEntry]) {
        // Entry Element Finished
        [[self atomEntryParser] parser:parser didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qName];
    }
    else {
        if ([namespaceURI isEqualToString:kAtom_Namespace]) {
            
            if ([elementName isEqualToString:kId_Element]) {
                [currentFeed setAtomId:[[currentString copy] autorelease]];
            }
            else if ([elementName isEqualToString:kTitle_Element]) {
                [currentFeed setAtomTitle:[[currentString copy] autorelease]];
            }
        }
    }
    storingCharacters = NO;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (storingCharacters) {
        [currentString appendString:string];
    }
    else if ([self currentEntry]) {
        [[self atomEntryParser] parser:parser foundCharacters:string];
    }
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    // FIXME Handle Errors
    NSLog(@"Parse Error: %@", parseError);
}


@end
