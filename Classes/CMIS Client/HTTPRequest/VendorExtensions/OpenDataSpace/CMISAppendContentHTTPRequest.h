//
//  CMISAppendContentHTTPRequest.h
//  FreshDocs
//
//  Created by bdt on 1/7/14.
//
//

#import "BaseHTTPRequest.h"
@class UploadInfo;

@interface CMISAppendContentHTTPRequest : BaseHTTPRequest
@property (nonatomic, retain) UploadInfo *uploadInfo;

+ (CMISAppendContentHTTPRequest *)cmisAppendRequestWithUploadInfo:(UploadInfo *)uploadInfo contentData:(NSMutableData*) contentData  isLastChunk:(BOOL)isLastChunk;

@end
