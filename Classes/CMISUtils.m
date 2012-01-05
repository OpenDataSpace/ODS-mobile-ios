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
//  CMISUtils.m
//

#import "CMISUtils.h"
#import "NSString+Utils.h"

@implementation CMISUtils
+ (BOOL)isAtomNamespace:(NSString *)namespace
{
	return [[namespace stringWithTrailingSlashRemoved] isEqualToString:@"http://www.w3.org/2005/Atom"];
}

+ (BOOL)isAtomPubNamespace:(NSString *)namespace
{
	return [[namespace stringWithTrailingSlashRemoved] isEqualToString:@"http://www.w3.org/2007/app"];
}

+ (BOOL)isCmisNamespace:(NSString *)namespace
{
	return [namespace hasPrefix:@"http://docs.oasis-open.org/ns/cmis/core"];
}

+ (BOOL)isCmisRestAtomNamespace:(NSString *)namespace
{
	return [[namespace stringWithTrailingSlashRemoved] isEqualToString:@"http://docs.oasis-open.org/ns/cmis/restatom/200908"];
}
@end
