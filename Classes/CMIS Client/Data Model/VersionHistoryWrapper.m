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
//  VersionHistoryWrapper.m
//

#import "VersionHistoryWrapper.h"

@implementation VersionHistoryWrapper

- (void)dealloc
{
    [_repositoryItem release];
    [super dealloc];
}

- (id)initWithRepositoryItem:(RepositoryItem *)initialRepositoryItem
{
    self = [super init];
    if (self)
    {
        self.repositoryItem = initialRepositoryItem;
#if TARGET_ALFRESCO
        self.useNonZeroInitialVersion = YES;
#endif
    }
    
    return self;
}

- (NSString *)lastAuthor
{
    return [self.repositoryItem.metadata objectForKey:@"cmis:lastModifiedBy"];
}

- (NSString *)comment
{
    return [self.repositoryItem.metadata objectForKey:@"cmis:checkinComment"];
}

- (NSString *)versionLabel
{
    
    NSString *label = [self.repositoryItem.metadata objectForKey:@"cmis:versionLabel"];
    if (self.useNonZeroInitialVersion && [label isEqual:@"0.0"])
    {
        label = @"1.0";
    }
    return label;
}

- (BOOL)isLatestVersion
{
    return [[self.repositoryItem.metadata objectForKey:@"cmis:isLatestVersion"] boolValue];
}

@end
