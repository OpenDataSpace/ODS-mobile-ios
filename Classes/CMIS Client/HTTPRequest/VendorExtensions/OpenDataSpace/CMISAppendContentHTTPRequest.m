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

+ (CMISAppendContentHTTPRequest *)cmisAppendRequestWithUploadInfo:(UploadInfo *)uploadInfo contentData:(NSMutableData*) contentData isLastChunk:(BOOL)isLastChunk
{
    RepositoryItem *repoItem = [uploadInfo repositoryItem];
    
    NSAssert(repoItem != nil, @"Append content stream request repository information.");
    
    NSString *contentDisposition = [NSString stringWithFormat:@"attachment;filename*=UTF-8''%@",[uploadInfo.completeFileName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSString *appendURLString = [NSString stringWithFormat:@"%@&append=true&isLastChunk=%@%@",[CMISAppendContentHTTPRequest appendURLFromUploadInfo:uploadInfo], isLastChunk?@"true":@"false", uploadInfo.repositoryItem.changeToken?[NSString stringWithFormat:@"&changeToken=%@", uploadInfo.repositoryItem.changeToken]:@""];
    
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

+ (NSString*) appendURLFromUploadInfo:(UploadInfo*) uploadInfo
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(rel == %@)" argumentArray:[NSArray arrayWithObjects:@"edit-media", nil]];
	NSArray *result = [[uploadInfo.repositoryItem linkRelations] filteredArrayUsingPredicate:predicate];
	if ([result count] != 1) {
		AlfrescoLogDebug(@"Hierarchy Navigation Link Relation could not be determined for given link relations: %@", [uploadInfo.repositoryItem linkRelations]);
		return nil;
	}
	
	NSString *href = [[result objectAtIndex:0] valueForKey:@"href"];
    
    return href;
}

@end
