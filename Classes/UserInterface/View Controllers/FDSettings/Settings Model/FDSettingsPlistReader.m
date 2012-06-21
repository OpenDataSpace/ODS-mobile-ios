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
//  FDSettingsPlistReader.m
//

#import "FDSettingsPlistReader.h"
#import "AccountManager+FileProtection.h"

@implementation FDSettingsPlistReader

- (void)dealloc
{
    [_allSettings release];
    [_plist release];
    [super dealloc];
}

- (id)initWithPlistPath:(NSString *)plistPath
{
    self = [super init];
    if(self)
    {
        _plist = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
        _allSettings = [[_plist objectForKey:@"PreferenceSpecifiers"] retain];
    }
    return self;
}

- (NSArray *)allSettings
{
    NSMutableArray *filteredSettings = [NSMutableArray arrayWithCapacity:[_allSettings count]];
    BOOL enterpriseEnabled = [[AccountManager sharedManager] hasQualifyingAccount];
    for(NSDictionary *setting in _allSettings)
    {
        NSString *permission = [setting objectForKey:@"Permission"];
        NSString *interfaceIdiom = [setting objectForKey:@"OnlyDisplayOnInterfaceIdiom"];
        
        BOOL isValidIphone = !interfaceIdiom || ([interfaceIdiom isEqualToString:@"Phone"] && !IS_IPAD);
        BOOL isValidIpad = !interfaceIdiom || ([interfaceIdiom isEqualToString:@"Pad"] && IS_IPAD);
        
        // If the seetings contains the Permission element we need to make sure the current user meets the permission
        // If the permission is not met, then we filter the setting
        // It also must be a valid iPhone or iPad idiom, since the plist can be configured to work only on ipad or iphone
        if((!permission || ![permission isEqualToString:@"Enterprise"] || ([permission isEqualToString:@"Enterprise"] && enterpriseEnabled)) && (isValidIphone || isValidIpad))
        {
            [filteredSettings addObject:setting];
        }
    }
    
    return filteredSettings;
}

- (NSArray *)stringsTable
{
    return [_plist objectForKey:@"StringsTable"];
}

- (NSString *)title
{
    return [_plist objectForKey:@"Title"];
}

@end
