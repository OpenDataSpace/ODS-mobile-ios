//
//  CMISFavoriteDocsHTTPRequest.m
//  FreshDocs
//
//  Created by Mohamad Saeedi on 01/08/2012.
//  Copyright (c) 2012 . All rights reserved.
//

#import "CMISFavoriteDocsHTTPRequest.h"
#import "Utility.h"
#import "RepositoryServices.h"
#import "RepositoryItemsParser.h"
#import "RepositoryItem.h"
#import "AccountManager.h"

@implementation CMISFavoriteDocsHTTPRequest
@synthesize folderObjectId;

- (void)dealloc
{
    [folderObjectId release];
    
    [super dealloc];
}

- (id)initWithSearchPattern:(NSString *)pattern accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
	return [self initWithSearchPattern:pattern folderObjectId:nil accountUUID:uuid tenantID:aTenantID];
}

- (id)initWithSearchPattern:(NSString *)pattern folderObjectId:(NSString *)objectId accountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
    //BOOL usingAlfresco = [[AccountManager sharedManager] isAlfrescoAccountForAccountUUID:uuid];
	NSString *selectFromClause = [NSString stringWithFormat:@"SELECT %@ FROM cmis:document ", kCMISDefaultPropertyFilterValue];
	NSString *whereClauseTemplate = nil;
	
    whereClauseTemplate = [NSString stringWithFormat:@"WHERE %@", pattern];
    
    NSString *cql = [NSString stringWithFormat:@"%@ %@", selectFromClause, whereClauseTemplate];
    self = [self initWithQuery:cql accountUUID:uuid tenantID:aTenantID];
    
    if (self) {
        folderObjectId = [objectId retain];
        [self setShow500StatusError:NO];
    }
	
	return self;
}

@end

