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
//  NSUserDefaults+DefaultPreferences.m
//

#import "NSUserDefaults+DefaultPreferences.h"

@implementation NSUserDefaults (DefaultPreferences)

- (NSArray *)defaultPreferences {
    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
    if(!settingsBundle) {
        NSLog(@"Could not find Settings.bundle");
        return [NSArray array];
    }
	
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];
    return [settings objectForKey:@"PreferenceSpecifiers"];
}

- (id)defaultPreferenceForKey:(NSString *)key
{
    NSArray *preferences = [self defaultPreferences];
    for (NSDictionary *prefSpecification in preferences) 
    {
        NSString *prefKey = [prefSpecification objectForKey:@"Key"];
        if (nil != prefKey && [prefKey isEqualToString:key]) 
        {
            return [prefSpecification objectForKey:@"DefaultValue"];
        }
    }
    return nil;
}

@end
