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
//  CMISSearchDownload.m
//

#import "CMISSearchDownload.h"
#import "Utility.h"
#import "RepositoryServices.h"
#import "RepositoryItemsParser.h"
#import "RepositoryItem.h"

@implementation CMISSearchDownload

- (id)initWithSearchPattern:(NSString *)pattern delegate:(id <AsynchronousDownloadDelegate>)del
{
    BOOL usingAlfresco = [[RepositoryServices shared] isCurrentRepositoryVendorNameEqualTo:kAlfrescoRepositoryVendorName];
    
	// TODO: US687
	//NSString *cqlTemplate = @"SELECT score() as Relevance, cmis:contentStreamLength as ContentStreamLength FROM Document where contains('%@')";
	//NSString *cqlTemplate = @"SELECT * FROM Document where contains('%@')";
//	NSString *selectFromClause = @"SELECT cmis:objectId, cmis:name, cmis:lastModificationDate, cmis:contentStreamLength, cmis:contentStreamMimeType FROM cmis:document ";
	NSString *selectFromClause = @"SELECT * FROM cmis:document ";
	NSString *whereClauseTemplate = @"";
	if (userPrefFullTextSearch()) {
		whereClauseTemplate = @"WHERE CONTAINS('%@') ";
	}
	else {
        if (usingAlfresco) {
            whereClauseTemplate = @"WHERE CONTAINS('~cmis:name:\\'*%@*\\'')";
        }
        else if ([[RepositoryServices shared] isCurrentRepositoryVendorNameEqualTo:kMicrosoftRepositoryVendorName]) {
            whereClauseTemplate = @"WHERE cmis:name = '%@'";
        }
        else {
            whereClauseTemplate = @"WHERE cmis:name LIKE '%%%@%%'";
        }
	}
    NSString *cmisQLTemplate = [NSString stringWithFormat:@"%@ %@", selectFromClause, whereClauseTemplate];
	NSString *cql = [[NSString alloc] initWithFormat:cmisQLTemplate, pattern];
	CMISSearchDownload *me = [self initWithQuery:cql delegate:del];
	[cql release];
	
	return me;
}

- (id)initWIthSearchPattern:(NSString *)pattern siteObjectId:(NSString *)siteObjectId delegate:(id <AsynchronousDownloadDelegate>)del
{
    BOOL usingAlfresco = [[RepositoryServices shared] isCurrentRepositoryVendorNameEqualTo:kAlfrescoRepositoryVendorName];
	NSString *selectFromClause = @"SELECT * FROM cmis:document ";
	NSString *whereClauseTemplate = @"";
	if (userPrefFullTextSearch()) {
		whereClauseTemplate = @"WHERE CONTAINS('%@') ";
	}
	else {
        if (usingAlfresco) {
            whereClauseTemplate = @"WHERE CONTAINS('~cmis:name:\\'*%@*\\'') ";
        }
        else if ([[RepositoryServices shared] isCurrentRepositoryVendorNameEqualTo:kMicrosoftRepositoryVendorName]) {
            whereClauseTemplate = @"WHERE cmis:name = '%@' ";
        }
        else {
            whereClauseTemplate = @"WHERE cmis:name LIKE '%%%@%%' ";
        }
	}
    
    if (usingAlfresco && siteObjectId && ([siteObjectId length] > 0)) {
        whereClauseTemplate = [whereClauseTemplate stringByAppendingFormat:@"AND IN_TREE('%@') ", siteObjectId];
    }
    
    NSString *cmisQLTemplate = [NSString stringWithFormat:@"%@ %@", selectFromClause, whereClauseTemplate];
	NSString *cql = [[NSString alloc] initWithFormat:cmisQLTemplate, pattern];
	CMISSearchDownload *me = [self initWithQuery:cql delegate:del];
	[cql release];
	
	return me;
}

@end
