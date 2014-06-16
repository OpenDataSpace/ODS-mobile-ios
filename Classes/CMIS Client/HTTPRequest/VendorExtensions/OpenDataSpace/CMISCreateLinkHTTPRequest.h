//
//  CMISCreateLinkHTTPRequest.h
//  FreshDocs
//
//  Created by bdt on 5/23/14.
//
//

#import "BaseHTTPRequest.h"
#import "RepositoryItem.h"

@interface CMISCreateLinkHTTPRequest : BaseHTTPRequest

+ (CMISCreateLinkHTTPRequest*) cmisCreateLinkRequestWithItem:(RepositoryItem*)repositoryItem destURL:(NSURL*)destUrl linkType:(NSString*) linkType linkInfo:(NSDictionary*)linkInfo accountUUID:(NSString *)accountUUID;

@end
