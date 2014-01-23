//
//  CMISUploadFileRequest.h
//  FreshDocs
//
//  Created by bdt on 1/20/14.
//
//

#import <Foundation/Foundation.h>
#import "CMISUploadFileHTTPRequest.h"
#import "CMISAppendContentHTTPRequest.h"
#import "UploadInfo.h"

@interface CMISUploadFileRequest : NSOperation <ASIHTTPRequestDelegate>

@property (nonatomic, strong) UploadInfo *uploadInfo;

@property (assign, nonatomic) id delegate;
@property (retain, nonatomic) id queue;
@property (assign, nonatomic) id uploadProgressDelegate;

@property (assign) SEL didStartSelector;
@property (assign) SEL didFinishSelector;
@property (assign) SEL didFailSelector;

@property (nonatomic, assign, readonly) uint64_t    totalBytes;
@property (nonatomic, assign, readonly) uint64_t    sentBytes;

+(CMISUploadFileRequest*)cmisUploadRequestWithUploadInfo:(UploadInfo*) info;


- (void)clearDelegatesAndCancel;
@end
