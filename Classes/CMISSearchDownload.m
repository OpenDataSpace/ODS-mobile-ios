//
//  CMISSearchDownload.m
//  Alfresco
//
//  Created by Michael Muller on 10/28/09.
//  Copyright 2009 Michael J Muller. All rights reserved.
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
