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
//  FDKeychainCellModel.m
//

#import "FDKeychainCellModel.h"
#import "FDKeychainUserDefaults.h"

@implementation FDKeychainCellModel

- (void)setObject:(id)value forKey:(NSString *)key
{
    [[FDKeychainUserDefaults standardUserDefaults] setObject:value forKey:key];
    [[FDKeychainUserDefaults standardUserDefaults] synchronize];
}
- (id)objectForKey:(NSString *)key
{
    //Most of the IFCellController don't support any other class than NSString so we need to cast it
    id originalObject = [[FDKeychainUserDefaults standardUserDefaults] objectForKey:key];
    if([originalObject isKindOfClass:[NSNumber class]])
    {
        originalObject = [originalObject stringValue];
    }
    
    return originalObject;
}

- (void)removeObjectForKey:(NSString *)key
{
    [[FDKeychainUserDefaults standardUserDefaults] removeObjectForKey:key];
}

@end
