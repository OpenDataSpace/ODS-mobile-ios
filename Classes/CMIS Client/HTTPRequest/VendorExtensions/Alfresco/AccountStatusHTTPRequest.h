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
//  AccountStatusHTTPRequest.h
//
// Queries an account status and holds a FDAccountStatus property
// where the current status of the account is recorded after the request finished.
// If the request fails the default value will be "FDAccountStatusActive"

#import "BaseHTTPRequest.h"
#import "AccountInfo.h"

@interface AccountStatusHTTPRequest : BaseHTTPRequest
@property (nonatomic, retain) AccountInfo *accountInfo;
@property (nonatomic, assign) FDAccountStatus accountStatus;

/*
 Static constructor. It builds an AccountStatusHTTPRequest to retrieve the 
 account status.
 */
+ (AccountStatusHTTPRequest *)accountStatusWithAccount:(AccountInfo *)accountInfo;
@end
