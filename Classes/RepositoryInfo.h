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
//  RepositoryInfo.h
//

#import <Foundation/Foundation.h>

/*
 <cmis:repositoryId>DaphneA</cmis:repositoryId>
 <cmis:repositoryName>DaphneA</cmis:repositoryName>
 <cmis:repositoryDescription>DaphneA</cmis:repositoryDescription>
 <cmis:vendorName>IBM</cmis:vendorName>
 <cmis:productName>IBM FileNet P8 Content Manager</cmis:productName>
 <cmis:productVersion>5.0.0</cmis:productVersion>
 <cmis:rootFolderId>idf_0F1E2D3C-4B5A-6978-8796-A5B4C3D2E1F0</cmis:rootFolderId>
 <cmis:capabilities>
	 <cmis:capabilityACL>none</cmis:capabilityACL>
	 <cmis:capabilityAllVersionsSearchable>true</cmis:capabilityAllVersionsSearchable>
	 <cmis:capabilityChanges>none</cmis:capabilityChanges>
	 <cmis:capabilityContentStreamUpdatability>pwconly</cmis:capabilityContentStreamUpdatability>
	 <cmis:capabilityGetDescendants>true</cmis:capabilityGetDescendants>
	 <cmis:capabilityGetFolderTree>true</cmis:capabilityGetFolderTree>
	 <cmis:capabilityMultifiling>true</cmis:capabilityMultifiling>
	 <cmis:capabilityPWCSearchable>true</cmis:capabilityPWCSearchable>
	 <cmis:capabilityPWCUpdatable>true</cmis:capabilityPWCUpdatable>
	 <cmis:capabilityQuery>bothcombined</cmis:capabilityQuery>
	 <cmis:capabilityRenditions>none</cmis:capabilityRenditions>
	 <cmis:capabilityUnfiling>true</cmis:capabilityUnfiling>
	 <cmis:capabilityVersionSpecificFiling>false</cmis:capabilityVersionSpecificFiling>
	 <cmis:capabilityJoin>innerandouter</cmis:capabilityJoin>
 </cmis:capabilities>
 <cmis:cmisVersionSupported>1.0</cmis:cmisVersionSupported>
 */


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
    
    // URI Templates
    NSString *objectByIdUriTemplate;
    NSString *objectByPathUriTemplate;
    NSString *typeByIdUriTemplate;
    NSString *queryUriTemplate;
    NSString *productVersion;
    NSString *accountUuid;
    NSString *tenantID;
}
@property (nonatomic, retain) NSString *repositoryId;
@property (nonatomic, retain) NSString *repositoryName;
@property (nonatomic, retain) NSString *vendorName;

@property (nonatomic, retain) NSString *rootFolderId;
@property (nonatomic, retain) NSString *cmisVersionSupported;

@property (nonatomic, retain) NSString *rootFolderHref;
@property (nonatomic, retain) NSString *cmisQueryHref;

@property (nonatomic, retain) NSString *objectByIdUriTemplate;
@property (nonatomic, retain) NSString *objectByPathUriTemplate;
@property (nonatomic, retain) NSString *typeByIdUriTemplate;
@property (nonatomic, retain) NSString *queryUriTemplate;
@property (nonatomic, retain) NSString *productVersion;

@property (nonatomic, retain) NSString *accountUuid;
@property (nonatomic, retain) NSString *tenantID;

@end
