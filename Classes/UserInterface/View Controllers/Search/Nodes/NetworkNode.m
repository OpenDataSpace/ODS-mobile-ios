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
//  NetworkNode.m
//

#import "NetworkNode.h"
#import "RepositoryInfo.h"
#import "AccountInfo.h"
#import "AccountManager.h"

@implementation NetworkNode

- (NSString *)title {
    RepositoryInfo *repoInfo = (RepositoryInfo *)self.value;
    NSString *labelText = [repoInfo repositoryName];
    if ([repoInfo tenantID]) {
        labelText = [repoInfo tenantID];
    }
    return labelText;
}

- (NSString *)breadcrumb {
    AccountInfo *account = [[AccountManager sharedManager] accountInfoForUUID:self.accountUUID];
    return [NSString stringWithFormat:@"%@ >", [account description]];
}

- (UIImage *)cellImage {
    return [UIImage imageNamed:kNetworkIcon_ImageName];
}

-(BOOL)isEqual:(id)object {
    RepositoryInfo *repoInfo = (RepositoryInfo *)self.value;
    //Same class, same accountUUID and same tenantID
    if([object isKindOfClass:[NetworkNode class]]) {
        NetworkNode *otherNode = (NetworkNode *)object;
        RepositoryInfo *otherRepo = (RepositoryInfo *)[otherNode value];
        return [self.accountUUID isEqualToString:[object accountUUID]] && [[repoInfo tenantID] isEqual:[otherRepo tenantID]]; 
    }
    
    return NO;
}

- (NSString *)tenantID {
    RepositoryInfo *repoInfo = (RepositoryInfo *)self.value;
    return [repoInfo tenantID];
}

@end
