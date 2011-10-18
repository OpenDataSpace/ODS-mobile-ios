//
//  ServiceDocumentRequest.h
//  FreshDocs
//
//  Created by Gi Hyun Lee on 11/10/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"

@interface ServiceDocumentRequest : ASIHTTPRequest {
}

+ (id)httpGETRequest;
// !!!: Implement following method when needed
// + (id)httpGETRequestWithOptionalArgumentRepositoryId:(NSString *)repositoryId;


@end
