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
 * Portions created by the Initial Developer are Copyright (C) 2011
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  RepositoryServices.h
//

#import <Foundation/Foundation.h>
#import "RepositoryInfo.h"

extern NSString * const kAlfrescoRepositoryVendorName;
extern NSString * const kIBMRepositoryVendorName;
extern NSString * const kMicrosoftRepositoryVendorName;


@interface RepositoryServices : NSObject {
@private
	NSMutableDictionary *repositories;
	RepositoryInfo *currentRepositoryInfo;
}

@property (nonatomic, retain) RepositoryInfo *currentRepositoryInfo;

- (void)addRepositoryInfo:(RepositoryInfo *)repositoryInfo forRepositoryId:(NSString *)repositoryId;
- (void)unloadRepositories;

// Repository Services methods
- (RepositoryInfo *)getRepositoryInfoByRepositoryId:(NSString *)repositoryId makeCurrent:(BOOL)makeCurrent;

// Utility Methods
- (BOOL)isCurrentRepositoryVendorNameEqualTo:(NSString *)testVendorName;

+ (id)shared;
@end
