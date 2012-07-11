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
//  CMISObjectAndChildrenRequest.h
//

#import <Foundation/Foundation.h>
@class RepositoryItem;
@class FolderItemsHTTPRequest;

@interface CMISObjectAndChildrenRequest : NSObject

@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) RepositoryItem *item;
@property (nonatomic, retain) NSArray *children; 
@property (nonatomic, retain) id objectRequest;
@property (nonatomic, retain) FolderItemsHTTPRequest *childrenRequest;
@property (nonatomic, assign) SEL didFinishSelector;
@property (nonatomic, assign) SEL didFailSelector;
@property (nonatomic, copy) NSString *accountUUID;
@property (nonatomic, copy) NSString *tenantID;

@property (nonatomic, assign) SEL objectRequestFactory;
@property (nonatomic, copy) NSString *objectId;
@property (nonatomic, copy) NSString *cmisPath;

- (id)initWithObjectId:(NSString *)objectId accountUUID:(NSString *)uuid tenantID:(NSString *)tenantID;
- (id)initWithPath:(NSString *)path accountUUID:(NSString *)uuid tenantID:(NSString *)tenantID;
- (id)initWithObjectRequestFactory:(SEL)objectRequestFactory accountUUID:(NSString *)uuid tenantID:(NSString *)tenantID;
- (void)startAsynchronous;

@end
