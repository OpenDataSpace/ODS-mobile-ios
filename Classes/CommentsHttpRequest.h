//
//  CommentsHttpRequest.h
//  FreshDocs
//
//  Created by Gi Hyun Lee on 7/20/11.
//  Copyright 2011 Zia Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"
#import "ASIHttpRequest+Alfresco.h"
#import "NodeRef.h"


@interface CommentsHttpRequest : ASIHTTPRequest {
@private
    NodeRef *nodeRef;
    NSDictionary *commentsDictionary;
    NSString *requestType;
}
@property (nonatomic, retain) NodeRef *nodeRef;
@property (nonatomic, readonly) NSDictionary *commentsDictionary;

+ (NSString *)alfrescoRepositoryTaggingApiUrlFormatString;

// Get all comments
+ (id)commentsHttpGetRequestWithNodeRef:(NodeRef *)nodeRef;

// Add new Comment
+ (id)CommentsHttpPostRequestForNodeRef:(NodeRef *)nodeRef comment:(NSString *)comment;
@end
