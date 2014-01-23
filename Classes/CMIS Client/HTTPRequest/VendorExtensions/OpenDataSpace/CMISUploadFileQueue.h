//
//  CMISUploadFileQueue.h
//  FreshDocs
//
//  Created by bdt on 1/20/14.
//
//

#import <Foundation/Foundation.h>

@interface CMISUploadFileQueue : NSOperationQueue

@property (assign) BOOL shouldCancelAllRequestsOnFailure;

@property (assign) unsigned long long bytesUploadedSoFar;
@property (assign) unsigned long long totalBytesToUpload;
@property (assign) id delegate;

@property (assign) SEL requestDidStartSelector;
@property (assign) SEL requestDidFinishSelector;
@property (assign) SEL requestDidFailSelector;
@property (assign) SEL queueDidFinishSelector;

@property (assign, nonatomic, setter=setUploadProgressDelegate:) id uploadProgressDelegate;

@property (strong) NSDictionary *userInfo;

// Convenience constructor
+ (CMISUploadFileQueue*) queue;

// This method will start the queue
- (void) go;
@end
