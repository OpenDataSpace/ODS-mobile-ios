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
//  FDSettingsPlistReader.h
//
// Reads the settings from a settings plist. It's compatible with the standard Root.plist supported by the iOS.
// Will remove enterprise settings if the user does not have a qualifying account.

#import <Foundation/Foundation.h>

@interface FDSettingsPlistReader : NSObject
{
    NSDictionary *_plist;
    NSArray *_allSettings;
}

/*
 Inits the FDSettingsPlistReader with a path of the plist
*/
- (id)initWithPlistPath:(NSString *)plistPath;
/*
 Returns an array of dictionaries with all the settings entries in the plist,
 Contains logic to filter enterprise settings
 */
- (NSArray *)allSettings;

/*
 Returns the table (string file) in which we should look for the localizable strings of titles.
 */
- (NSArray *)stringsTable;

/*
 Returns the title of the settings navigation bar
 */
- (NSString *)title;
@end
