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
//  AccountNode.m
//

#import "AccountNode.h"
#import "AccountInfo.h"

@implementation AccountNode

- (NSString *)title
{
    AccountInfo *account = (AccountInfo *)self.value;
    return [account description];
}

- (NSString *)breadcrumb
{
    return @"";
}

- (UIImage *)cellImage
{
    AccountInfo *account = (AccountInfo *) self.value;
    NSString *imageName = (account.isMultitenant ? kCloudIcon_ImageName : kServerIcon_ImageName);
    return [UIImage imageNamed:imageName];
}

- (NSString *)tenantID
{
    return nil;
}

- (BOOL)isEqual:(id)object
{
    AccountInfo *account = (AccountInfo *)self.value;
    AccountNode *otherNode = (AccountNode *)object;
    return [object isKindOfClass:[AccountNode class]] && [[account uuid] isEqual:[otherNode.value uuid]]; 
}
            
@end
