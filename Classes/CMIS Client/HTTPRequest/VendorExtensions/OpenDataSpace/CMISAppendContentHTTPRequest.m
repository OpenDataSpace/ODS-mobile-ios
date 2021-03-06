//
//  CMISAppendContentHTTPRequest.m
//  FreshDocs
//
//  Created by bdt on 1/7/14.
//
//

#import "CMISAppendContentHTTPRequest.h"
#import "UploadInfo.h"
#import "RepositoryItem.h"

@implementation CMISAppendContentHTTPRequest
@synthesize uploadInfo = _uploadInfo;

- (void) failWithError:(NSError *)theError {
    NSLog(@"CMISUploadFileHTTPRequest");
    if ([self responseStatusCode] == 403) {  //HTTP Status 403 - Quota is reached, write is aborted
        displayErrorMessageWithTitle(NSLocalizedString(@"Not enough data space for upload file.", nil), NSLocalizedString(@"Quota is reached", nil));
    }else {
        [super failWithError:theError];
    }
}

+ (CMISAppendContentHTTPRequest *)cmisAppendRequestWithUploadInfo:(UploadInfo *)uploadInfo contentData:(NSMutableData*) contentData isLastChunk:(BOOL)isLastChunk
{
    RepositoryItem *repoItem = nil;
    if (uploadInfo.temporaryRrepositoryItem) {
        repoItem = uploadInfo.temporaryRrepositoryItem;
    }else {
        repoItem = [uploadInfo repositoryItem];
    }
    
    NSString *upLinkRelation = [CMISAppendContentHTTPRequest appendURLFromUploadRepostoryItem:repoItem];
    
    NSAssert(repoItem != nil, @"Append content stream request repository information.");
    
    NSString *contentDisposition = [NSString stringWithFormat:@"attachment;filename*=UTF-8''%@",[uploadInfo.completeFileName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSString *appendURLString = [NSString stringWithFormat:@"%@&append=true&isLastChunk=%@%@",upLinkRelation, isLastChunk?@"true":@"false", repoItem.changeToken?[NSString stringWithFormat:@"&changeToken=%@", repoItem.changeToken]:@""];
    
     AlfrescoLogDebug(@"cmisAppendRequestWithUploadInfo file org guid:%@ temporary object guid:%@ changeToken:%@ --- %@",uploadInfo.repositoryItem.guid, repoItem.guid, repoItem.changeToken, appendURLString);
    
    CMISAppendContentHTTPRequest *request = [CMISAppendContentHTTPRequest requestWithURL:[NSURL URLWithString:appendURLString] accountUUID:[uploadInfo selectedAccountUUID]];
    [request setRequestMethod:@"PUT"];
    [request addRequestHeader:@"Content-Disposition" value:contentDisposition];
    [request addRequestHeader:@"Content-Type" value:@"application/octet-stream"];//text/plain  //[uploadInfo.repositoryItem contentStreamMimeType]
    [request addRequestHeader:@"Transfer-Encoding" value:@"chunked"];
    [request setShouldContinueWhenAppEntersBackground:YES];
    [request setUploadInfo:uploadInfo];
    
    [request setTimeOutSeconds:180];
    
    [request setPostBody:contentData];//[contentData base64EncodedDataWithOptions:NSDataBase64Encoding64CharacterLineLength]
    
    return request;
}

+ (NSString*) appendURLFromUploadRepostoryItem:(RepositoryItem*) repoItem
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(rel == %@)" argumentArray:[NSArray arrayWithObjects:@"edit-media", nil]];
	NSArray *result = [[repoItem linkRelations] filteredArrayUsingPredicate:predicate];
	if ([result count] != 1) {
		AlfrescoLogDebug(@"Hierarchy Navigation Link Relation could not be determined for given link relations: %@", [repoItem linkRelations]);
		return nil;
	}
	
	NSString *href = [[result objectAtIndex:0] valueForKey:@"href"];
    
    return href;
}

@end
