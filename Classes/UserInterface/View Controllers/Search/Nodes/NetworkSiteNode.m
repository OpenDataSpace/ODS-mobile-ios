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
//  NetworkSiteNode.m
//

#import "NetworkSiteNode.h"
#import "RepositoryItem.h"
#import "AccountInfo.h"
#import "AccountManager.h"
#import "RepositoryInfo.h"
#import "RepositoryServices.h"

@implementation NetworkSiteNode
@synthesize tenantID;

- (void)dealloc {
    [tenantID release];
    [super dealloc];
}

- (NSString *)title {
    RepositoryItem *site = (RepositoryItem *)value;
    return [site title];
}

- (NSString *)breadcrumb {
    AccountInfo *account = [[AccountManager sharedManager] accountInfoForUUID:accountUUID];
    RepositoryInfo *repoInfo = [[RepositoryServices shared] getRepositoryInfoForAccountUUID:accountUUID tenantID:tenantID];
    NSString *repoLabel = [repoInfo repositoryName];
    if ([repoInfo tenantID]) {
        repoLabel = [repoInfo tenantID];
    }
    
    return [NSString stringWithFormat:@"%@ > %@ >", [account description], repoLabel];
}

- (UIImage *)cellImage {
    return [UIImage imageNamed:@"site.png"];
}

-(BOOL)isEqual:(id)object {
    RepositoryItem *site = (RepositoryItem *)value;
    //Same class, same accountUUID, same tenantID, same site guid
    if([object isKindOfClass:[NetworkSiteNode class]]) {
        NetworkSiteNode *otherNode = (NetworkSiteNode *)object;
        RepositoryItem *otherSite = (RepositoryItem *)[otherNode value];
        return [accountUUID isEqualToString:[object accountUUID]] && [tenantID isEqual:[otherNode tenantID]] && [[site guid] isEqualToString:[otherSite guid]]; 
    }
    
    return NO;
}

@end
