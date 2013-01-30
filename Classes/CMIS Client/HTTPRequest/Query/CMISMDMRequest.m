//
//  CMISMDMRequest.m
//  FreshDocs
//
//  Created by Mohamad Saeedi on 07/01/2013.
//
//

#import "CMISMDMRequest.h"

@implementation CMISMDMRequest
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
    NSString *selectFromClause = [NSString stringWithFormat:@"SELECT d.cmis:objectId, m.mdm:offlineExpiresAfter"
                                  " FROM cmis:document AS d"
                                  " JOIN mdm:restrictedAspect AS m"
                                  " ON d.cmis:objectId = m.cmis:objectId"];
    
	NSString *whereClauseTemplate = nil;
	
    whereClauseTemplate = [NSString stringWithFormat:@"WHERE %@", pattern];
    
    NSString *cql = [NSString stringWithFormat:@"%@ %@", selectFromClause, whereClauseTemplate];
    
    self = [self initWithQuery:cql accountUUID:uuid tenantID:aTenantID];
    
    if (self)
    {
        folderObjectId = [objectId retain];
    }
	
	return self;
}

@end

