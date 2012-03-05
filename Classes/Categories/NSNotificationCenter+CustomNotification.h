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
//  NSNotificationCenter+CustomNotification.h
//

#import <Foundation/Foundation.h>

@interface NSNotificationCenter (CustomNotification)
/*
 * Used to post notification about account changes.
 * User Info:
 *    (NSString *) "type": can be @"add", @"delete" or @"edit"
 *    (NSNumber *) "reset": Indicates if the account change is from a app reset
 *    (NSString *) "uuid": The UUID of the account added, deleted or edited
 */
- (void)postAccountListUpdatedNotification:(NSDictionary *)userInfo;

/*
 * When the user taps the "Browse Documents" in an account detail this notification should be posted
 * User Info:
 *    (NSString *) "accountUUID": The UUID of the account to browse
 */
- (void)postBrowseDocumentsNotification:(NSDictionary *)userInfo;

/*
 * Used to post notification when the detailViewController Changed.
 * Only for iPad and it's used to deselect if a cell is selected indicating that is displaying
 * in the detailView
 *
 * User Info:
 *    (DownloadMetadata *) "fileMetadata": The download metadata related to the cell. When applicable, to better identify the
 *                       selected cell if the original list is updated
 */
- (void)postDetailViewControllerChangedNotificationWithSender:(id)sender userInfo:(NSDictionary *)userInfo;

/*
 * Used to post notification when a user preference that affects the information displayed in a screen.
 *
 * User Info: None
 */
- (void)postUserPreferencesChangedNotification;

/*
 * Used to post notification when a user default in the keychain changed (after calling the synchronize method)
 *
 * User Info: None
 */
- (void)postKeychainUserDefaultsDidChangeNotification;
@end
