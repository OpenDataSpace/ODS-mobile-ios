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
//  CMISSearchDownload.m
//

#import "CMISSearchDownload.h"
#import "Utility.h"
#import "RepositoryServices.h"

@implementation CMISSearchDownload

- (id)initWithSearchPattern:(NSString *)pattern delegate:(id <AsynchronousDownloadDelegate>)del
{
    BOOL usingAlfresco = [[RepositoryServices shared] isCurrentRepositoryVendorNameEqualTo:kAlfrescoRepositoryVendorName];
	NSString *selectFromClause = @"SELECT * FROM cmis:document ";
	NSString *whereClauseTemplate = @"";
	if (userPrefFullTextSearch()) {
		whereClauseTemplate = @"WHERE CONTAINS('%@') ";
	}
	else {
        if (usingAlfresco) {
            whereClauseTemplate = @"WHERE CONTAINS('~cmis:name:\\'*%@*\\'')";
        }
        else {
            if ([[RepositoryServices shared] isCurrentRepositoryVendorNameEqualTo:kMicrosoftVendorName]) {
                // if using Microsoft we can only use somple comparision.  It 
                // appears that the LIKE predicate is not supported as of October 4th, 2011
                whereClauseTemplate = @"WHERE cmis:name = '%@'";   
            }
            else {
                whereClauseTemplate = @"WHERE cmis:name LIKE '%%%@%%'";
            }
        }
	}
    NSString *cmisQLTemplate = [NSString stringWithFormat:@"%@ %@", selectFromClause, whereClauseTemplate];
	NSString *cql = [[NSString alloc] initWithFormat:cmisQLTemplate, pattern];
	CMISSearchDownload *me = [self initWithQuery:cql delegate:del];
	[cql release];
	
	return me;
}

@end
