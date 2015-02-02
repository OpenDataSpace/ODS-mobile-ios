//
//  LogoServiceRequest.m
//  FreshDocs
//
//  Created by  Tim Lei on 1/6/15.
//
//

#import "LogoServiceRequest.h"
#import "LogoServiceParser.h"
#import "CMISMediaTypes.h"
#import "CMISUtils.h"

@implementation LogoServiceRequest
@synthesize confRepositoryInfo = _confRepositoryInfo;

- (void)requestFinishedWithSuccessResponse
{
    // !!!: Check media type
    
    LogoServiceParser *needToReimpl = [[LogoServiceParser alloc] initWithAtomPubServiceDocumentData:self.responseData];
    [needToReimpl setAccountUuid:self.accountUUID];
    [needToReimpl setTenantID:self.tenantID];
    [needToReimpl parse];
    
    _confRepositoryInfo = nil;
    for (RepositoryInfo *repo in [needToReimpl parserResult]) {
        if (repo && [repo.repositoryName caseInsensitiveCompare:@"config"] == NSOrderedSame) {
            _confRepositoryInfo = repo;
        }
    }
}

- (void)failWithError:(NSError *)theError
{
    // TODO: We should be logging something here and doing something!
    [super failWithError:theError];
}

#pragma mark -
#pragma mark Factory Methods

+ (id)httpGETRequestForAccountUUID:(NSString *)uuid tenantID:(NSString *)aTenantID
{
    LogoServiceRequest *getRequest = [LogoServiceRequest requestForServerAPI:kServerAPICMISServiceInfo
                                                                         accountUUID:uuid tenantID:aTenantID];
    [getRequest addRequestHeader:@"Accept" value:kAtomPubServiceMediaType];
    [getRequest setRequestMethod:@"GET"];
    
    return getRequest;
}

+ (id)httpGETRequestForAccountUUID:(NSString *)uuid
{
    LogoServiceRequest *getRequest = [LogoServiceRequest requestForServerAPI:kServerAPICMISServiceInfo
                                                                         accountUUID:uuid];
    [getRequest addRequestHeader:@"Accept" value:kAtomPubServiceMediaType];
    [getRequest setRequestMethod:@"GET"];
    
    return getRequest;
}

@end
