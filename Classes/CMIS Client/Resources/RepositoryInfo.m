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
//  RepositoryInfo.m
//

#import "RepositoryInfo.h"

@implementation RepositoryInfo
@synthesize repositoryId = _repositoryId;
@synthesize repositoryName = _repositoryName;
@synthesize vendorName = _vendorName;

@synthesize rootFolderId = _rootFolderId;
@synthesize cmisVersionSupported = _cmisVersionSupported;

@synthesize rootFolderHref = _rootFolderHref;
@synthesize cmisQueryHref = _cmisQueryHref;

@synthesize objectByIdUriTemplate = _objectByIdUriTemplate;
@synthesize objectByPathUriTemplate = _objectByPathUriTemplate;
@synthesize typeByIdUriTemplate = _typeByIdUriTemplate;
@synthesize queryUriTemplate = _queryUriTemplate;
@synthesize productVersion = _productVersion;
@synthesize productName = _productName;

@synthesize accountUuid = _accountUuid;
@synthesize tenantID = _tenantID;

@synthesize hasValidSession = _hasValidSession;

- (void)dealloc
{
	[_repositoryId release];
	[_repositoryName release];
    [_vendorName release];
	[_rootFolderId release];
	[_cmisVersionSupported release];
	[_rootFolderHref release];
	[_cmisQueryHref release];
    [_objectByIdUriTemplate release];
    [_objectByPathUriTemplate release];
    [_typeByIdUriTemplate release];
    [_queryUriTemplate release];
	[_productVersion release];
    [_productName release];
    [_accountUuid release];
    [_tenantID release];

    [super dealloc];
}

#pragma mark -
#pragma mark Overriden Key-Value Coding Methods
- (id)valueForUndefinedKey:(NSString *)key
{
	AlfrescoLogTrace(@"RepositoryInfo ignoring key: '%@' in valueForUndefinedKey:", key);
	return nil;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
	AlfrescoLogTrace(@"RepositoryInfo ignoring key: '%@' in setValue:forUndefinedKey:", key);	
}

@end
