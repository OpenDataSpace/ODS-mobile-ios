//
//  ***** BEGIN LICENSE BLOCK *****
//  Version: MPL 1.1
//
//  The contents of this file are subject to the Mozilla Public License Version
//  1.1 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS" basis,
//  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
//  for the specific language governing rights and limitations under the
//  License.
//
//  The Original Code is the Alfresco Mobile App.
//  The Initial Developer of the Original Code is Zia Consulting, Inc.
//  Portions created by the Initial Developer are Copyright (C) 2011
//  the Initial Developer. All Rights Reserved.
//
//
//  ***** END LICENSE BLOCK *****
//
//
//  RepositoryInfo.h
//


#import <Foundation/Foundation.h>


/**
 * NOTE: Make sure that the property name matches the element name (without the namespace) from the
 * service document and by key-value coding, the property will be set when the service document is loaded.
 *
 * Currently does not handle capabilities.
 */

@interface RepositoryInfo : NSObject {
@private
	NSString *repositoryId;
	NSString *repositoryName;
	NSString *vendorName;
	
	NSString *rootFolderId;
	NSString *cmisVersionSupported;
	
	NSString *rootFolderHref;
	NSString *cmisQueryHref;
//	NSString *queryHref;  TODO: Implement 
}
@property (nonatomic, retain) NSString *repositoryId;
@property (nonatomic, retain) NSString *repositoryName;
@property (nonatomic, retain) NSString *vendorName;

@property (nonatomic, retain) NSString *rootFolderId;
@property (nonatomic, retain) NSString *cmisVersionSupported;

@property (nonatomic, retain) NSString *rootFolderHref;
@property (nonatomic, retain) NSString *cmisQueryHref;

- (BOOL)isPreReleaseCmis;

@end
