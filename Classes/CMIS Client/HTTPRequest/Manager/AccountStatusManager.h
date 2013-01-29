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
//  AccountStatusManager.h
//
// A "fire and forget" service. It manages all the operations that are related with the account status.

#import <Foundation/Foundation.h>
@class ASINetworkQueue;

@interface AccountStatusManager : NSObject

/* Retrieves all the accounts that have an "Awaiting Verification" status and requests the current status.
 In the case the status changed to "Active" the manager will update that account
 Since the Manager will not notify any delegate only the observers for the kNotificationAccountListUpdated notification
 will know if anything in the account changed.
 */
- (void)requestAllAccountStatus;

// Singleton instance for this manager.
+ (AccountStatusManager *)sharedManager;

@end
