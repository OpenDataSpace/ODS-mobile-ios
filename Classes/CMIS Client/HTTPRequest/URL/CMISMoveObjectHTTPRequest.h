//
//  CMISMoveObjectHTTPRequest.h
//  FreshDocs
//
//  Created by bdt on 11/4/13.
//
//

#import "BaseHTTPRequest.h"

@interface CMISMoveObjectHTTPRequest : BaseHTTPRequest
//Parameter:repositoryId,objectId,targetFolderId,sourceFolderId
//return:objectId:SHOULD NOT change, or this is the new identifer for the object.
- (id) initWithURL:(NSURL *)u  moveParam:(NSDictionary*) moveParam accountUUID:(NSString *)uuid;

@end
