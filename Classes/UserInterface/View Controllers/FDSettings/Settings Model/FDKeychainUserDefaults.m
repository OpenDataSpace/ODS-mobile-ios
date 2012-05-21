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
//  FDKeychainUserDefaults.m
//

#import "FDKeychainUserDefaults.h"
#import "DataKeychainItemWrapper.h"
#import "NSNotificationCenter+CustomNotification.h"
#import "FDSettingsPlistReader.h"
NSString * const kKeychainUserDefaults_Identifier = @"UserDefaults";

@implementation FDKeychainUserDefaults

- (void)dealloc
{
    [_keychainWrapper release];
    [_userDefaultsCache release];
    [super dealloc];
}

- (id)initWithKeychainWrapper:(DataKeychainItemWrapper *)keychainWrapper
{
    self = [super init];
    if(self)
    {
        _keychainWrapper = [keychainWrapper retain];
        NSData *serializedAccountListData = [_keychainWrapper objectForKey:(id)kSecValueData];
        if (serializedAccountListData) 
        {
            NSMutableDictionary *deserializedDict = [NSKeyedUnarchiver unarchiveObjectWithData:serializedAccountListData];
            if (deserializedDict)
            {
                _userDefaultsCache = [deserializedDict retain];
            } 
            else
            {
                _userDefaultsCache = [[NSMutableDictionary alloc] init];
            }
        }
    }
    return self;
}


- (id)objectForKey:(NSString *)defaultName
{
    return [_userDefaultsCache objectForKey:defaultName];
}

- (void)setObject:(id)value forKey:(NSString *)defaultName
{
    [_userDefaultsCache setObject:value forKey:defaultName];
}

- (void)removeObjectForKey:(NSString *)defaultName
{
    [_userDefaultsCache removeObjectForKey:defaultName];
}

// Helper getters for specific types
- (NSString *)stringForKey:(NSString *)defaultName
{
    return [_userDefaultsCache objectForKey:defaultName];
}

- (NSArray *)arrayForKey:(NSString *)defaultName
{
    return [_userDefaultsCache objectForKey:defaultName];
}
- (NSDictionary *)dictionaryForKey:(NSString *)defaultName
{
    return [_userDefaultsCache objectForKey:defaultName];
}
- (NSData *)dataForKey:(NSString *)defaultName
{
    return [_userDefaultsCache objectForKey:defaultName];
}
- (NSArray *)stringArrayForKey:(NSString *)defaultName
{
    return [_userDefaultsCache objectForKey:defaultName];
}
- (NSInteger)integerForKey:(NSString *)defaultName
{
    return [[_userDefaultsCache objectForKey:defaultName] intValue];
}
- (float)floatForKey:(NSString *)defaultName
{
    return [[_userDefaultsCache objectForKey:defaultName] floatValue];
}
- (double)doubleForKey:(NSString *)defaultName
{
    return [[_userDefaultsCache objectForKey:defaultName] doubleValue];
}
- (BOOL)boolForKey:(NSString *)defaultName
{
    return [[_userDefaultsCache objectForKey:defaultName] boolValue];
}

// Helper setters for specific types
- (void)setInteger:(NSInteger)value forKey:(NSString *)defaultName
{
    [_userDefaultsCache setObject:[NSNumber numberWithInt:value] forKey:defaultName];
}
- (void)setFloat:(float)value forKey:(NSString *)defaultName
{
    [_userDefaultsCache setObject:[NSNumber numberWithFloat:value] forKey:defaultName];
}
- (void)setDouble:(double)value forKey:(NSString *)defaultName
{
    [_userDefaultsCache setObject:[NSNumber numberWithDouble:value] forKey:defaultName];
}
- (void)setBool:(BOOL)value forKey:(NSString *)defaultName
{
    [_userDefaultsCache setObject:[NSNumber numberWithBool:value] forKey:defaultName];
}

- (void)registerDefaults:(NSDictionary *)registrationDictionary
{
    for(NSString *key in registrationDictionary)
    {
        if(![self objectForKey:key])
        {
            //If there's no object set into the userDefaults we use the one in the defaults
            [self setObject:[registrationDictionary objectForKey:key] forKey:key];
        }
    }
}

- (NSDictionary *)dictionaryRepresentation
{
    return [NSDictionary dictionaryWithDictionary:_userDefaultsCache];
}

- (void)removePersistentDomainForName:(NSString *)domainName
{
    [_userDefaultsCache removeAllObjects];
}

- (NSArray *)defaultPreferences
{
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Root" ofType:@"plist"];
    FDSettingsPlistReader *plistReader = [[[FDSettingsPlistReader alloc] initWithPlistPath:plistPath] autorelease];
    return [plistReader allSettings];
}

/*
 Will persist the changes made with any setter and also read the latest data in the keychain.
 */
- (BOOL)synchronize
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:_userDefaultsCache];
    [_keychainWrapper setObject:data forKey:(id)kSecValueData];
    [[NSNotificationCenter defaultCenter] postKeychainUserDefaultsDidChangeNotification];
    return YES;
}

#pragma mark - Standard Instance

static FDKeychainUserDefaults *sharedKeychainUserDefaults = nil;
+ (FDKeychainUserDefaults *)standardUserDefaults
{
    if (sharedKeychainUserDefaults == nil) {
        DataKeychainItemWrapper *keychain = [[[DataKeychainItemWrapper alloc] initWithIdentifier:kKeychainUserDefaults_Identifier accessGroup:nil] autorelease];
        [keychain setObject:@"UserDefaultsService" forKey:(id)kSecAttrService];
        sharedKeychainUserDefaults = [[super alloc] initWithKeychainWrapper:keychain];
    }
    
    return sharedKeychainUserDefaults;
}

@end
