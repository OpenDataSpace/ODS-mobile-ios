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
//  KeychainManager.h
//

#import <Foundation/Foundation.h>
@class DataKeychainItemWrapper;

@interface KeychainManager : NSObject
@property (nonatomic, retain) DataKeychainItemWrapper *keychain; //Keychain wrapper that writes to the keychain

/*
 Returns the account list currently stored in the current keychain.
 */
- (NSMutableArray *)accountList;
/*
 Saved the account list (list2Save) into the current keychain.
 */
- (BOOL)saveAccountList:(NSMutableArray *)list2Save;

/*
 Creates a new KeychainManager object with a given keychain.
 */
- (id)initWithKeychain:(DataKeychainItemWrapper *)keychain;

/*
 Returns a default instance of the KeychainManager. The keychain identifier used is a constant for the user
 generated accounts.
 */
+ (KeychainManager *)sharedManager;
@end
