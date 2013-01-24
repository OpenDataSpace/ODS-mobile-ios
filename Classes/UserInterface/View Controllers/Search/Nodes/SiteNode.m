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
//  SiteNode.m
//

#import "SiteNode.h"
#import "RepositoryItem.h"
#import "AccountManager.h"

@implementation SiteNode

- (NSString *)title {
    RepositoryItem *site = (RepositoryItem *)self.value;
    return [site title];
}

- (NSString *)breadcrumb {
    AccountInfo *account = [[AccountManager sharedManager] accountInfoForUUID:self.accountUUID];
    return [NSString stringWithFormat:@"%@ >", [account description]];
}

- (UIImage *)cellImage {
    return [UIImage imageNamed:@"site.png"];
}

-(BOOL)isEqual:(id)object {
    RepositoryItem *site = (RepositoryItem *)self.value;
    //Same class, same accountUUID and same site guid should be equal
    if([object isKindOfClass:[SiteNode class]]) {
        SiteNode *otherNode = (SiteNode *)object;
        RepositoryItem *otherSite = (RepositoryItem *)[otherNode value];
        return [self.accountUUID isEqualToString:[object accountUUID]] && [[site guid] isEqual:[otherSite guid]]; 
    }
    
    return NO;
}

@end
