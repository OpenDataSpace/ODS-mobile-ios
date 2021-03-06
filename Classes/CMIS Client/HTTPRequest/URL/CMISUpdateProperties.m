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
//  CMISUpdateProperties.m
//

#import "CMISUpdateProperties.h"
#import "PropertyInfo.h"
#import "CMISMediaTypes.h"

@implementation CMISUpdateProperties

- (void) dealloc {
	[super dealloc];
}

- (id) initWithURL:(NSURL *)u propertyInfo:(NSMutableDictionary *)propertyInfo originalMetadata:(NSMutableDictionary *)orig editedMetadata:(NSMutableDictionary *) edit accountUUID:(NSString *)uuid 
{
	self = [self initWithURL:u accountUUID:uuid];
    if(self) {
        NSMutableString *propertyElements = [NSMutableString stringWithString:@""];
        
        NSString *stringPropertyTemplate = @"<propertyString displayName=\"%@\" localName=\"%@\" propertyDefinitionId=\"%@\"><value>%@</value></propertyString>";	
        
        // get the key (name) for every property
        for (id key in orig) {
            
            // if the value has changed
            if (![[orig objectForKey:key] isEqualToString:[edit objectForKey:key]]) {
                
                AlfrescoLogDebug(@"%@ changed!  old value %@, new value %@", key, [orig objectForKey:key], [edit objectForKey:key]);
                
                // if we know anything about this property
                PropertyInfo *info = [propertyInfo objectForKey:key];
                if (info != nil) {
                    
                    // if the value is a string
                    if ([info.propertyType isEqualToString:@"string"]) {
                        [propertyElements appendFormat:stringPropertyTemplate, info.displayName, info.localName, key, [edit objectForKey:key]];
                    }
                    else {
                        AlfrescoLogDebug(@"unsupported type '%@' for property '%@'", info.propertyType, key);
                    }
                    
                }
                else {
                    AlfrescoLogDebug(@"property '%@' changed, but we don't know its datatype, so we're ignoring it", key);
                }
            }
        }
        
        NSString *entryTemplate= @"<ns3:entry xmlns:ns5=\"http://docs.oasis-open.org/ns/cmis/restatom/200908/\" xmlns:ns3=\"http://www.w3.org/2005/Atom\" xmlns=\"http://docs.oasis-open.org/ns/cmis/core/200908/\">"
		"<ns5:object><properties>%@</properties></ns5:object></ns3:entry>";
        
        NSString *body = [[NSString alloc] initWithFormat:entryTemplate, propertyElements];
        AlfrescoLogDebug(@"PUT: %@", body);
        // create a post request
        NSData *d = [body dataUsingEncoding:NSUTF8StringEncoding];
        [body release];

        [self addRequestHeader:@"Content-Type" value:kAtomEntryMediaType];
        [self setPostBody:[NSMutableData dataWithData:d]];
        [self setContentLength:[d length]];
        [self setRequestMethod:@"PUT"];
        
        [self setShouldContinueWhenAppEntersBackground:YES];
    }
	
	return self;
}


@end
