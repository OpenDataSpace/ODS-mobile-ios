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
//  FDKeychainUserDefaults.h
//
// Provides an interface to store and read user settings from the key chain
// It mirrors the methods in NSUserDefault so it can be used as a drop in replacement.
// It will not save to the keychain after every set but we need to call the synchronize method so
// the changed are persisted into the keychain

#import <Foundation/Foundation.h>
@class DataKeychainItemWrapper;

@interface FDKeychainUserDefaults : NSObject 
{
    DataKeychainItemWrapper *_keychainWrapper;
    NSMutableDictionary *_userDefaultsCache;
}

- (id)initWithKeychainWrapper:(DataKeychainItemWrapper *)keychainWrapper;

/*
 Returns an object for a given key
 */
- (id)objectForKey:(NSString *)defaultName;
/*
 Sets an object (value) for a given key
 */
- (void)setObject:(id)value forKey:(NSString *)defaultName;
/*
 Removed the object stored at the given key
 */
- (void)removeObjectForKey:(NSString *)defaultName;

// Helper getters for specific types
- (NSString *)stringForKey:(NSString *)defaultName;
- (NSArray *)arrayForKey:(NSString *)defaultName;
- (NSDictionary *)dictionaryForKey:(NSString *)defaultName;
- (NSData *)dataForKey:(NSString *)defaultName;
- (NSArray *)stringArrayForKey:(NSString *)defaultName;
- (NSInteger)integerForKey:(NSString *)defaultName;
- (float)floatForKey:(NSString *)defaultName;
- (double)doubleForKey:(NSString *)defaultName;
- (BOOL)boolForKey:(NSString *)defaultName;

// Helper setters for specific types
- (void)setInteger:(NSInteger)value forKey:(NSString *)defaultName;
- (void)setFloat:(float)value forKey:(NSString *)defaultName;
- (void)setDouble:(double)value forKey:(NSString *)defaultName;
- (void)setBool:(BOOL)value forKey:(NSString *)defaultName;

// Helper method to read set default values to the user defaults
- (void)registerDefaults:(NSDictionary *)registrationDictionary;
- (NSDictionary *)dictionaryRepresentation;

/*
 Will persist the changes made with any setter and also read the latest data in the keychain.
 */
- (BOOL)synchronize;

+ (FDKeychainUserDefaults *)standardUserDefaults;
@end
