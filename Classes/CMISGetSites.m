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
//  CMISGetSites.m
//

#import "CMISGetSites.h"
#import "RepositoryServices.h"
#import "RepositoryItem.h"

@implementation CMISGetSites

// FIXME: Remove this class after we have a atom doc parser

- (CMISGetSites *)initWithDelegate:(id <AsynchronousDownloadDelegate>)del
{
	NSString *cql;
	if ([[[RepositoryServices shared] currentRepositoryInfo] isPreReleaseCmis]) {
		cql = @"select * from folder as f where f.ObjectTypeId = 'F/st_site'";
	} else {
		// TODO: The site queryName or objectTypeId should be discovered by the type collection
//		cql = @"SELECT cmis:name FROM cmis:folder where cmis:objectTypeId = 'F:st:site'";
		cql = @"SELECT * FROM st:site";
	}
	 
	return (CMISGetSites *) [self initWithQuery:cql delegate:del];
}
@end
