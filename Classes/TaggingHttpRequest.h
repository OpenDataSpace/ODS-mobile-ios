//
//  TaggingHttpRequest.h
//  FreshDocs
//
//  Created by Gi Hyun Lee on 8/4/11.
//  Copyright 2011 Zia Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest+Utils.h"
#import "ASIHttpRequest+Alfresco.h"
#import "JSON.h"
#import "SBJSON.h"
#import "Utility.h"
#import "NodeRef.h"

extern NSString * const kListAllTags;
extern NSString * const kGetNodeTags;
extern NSString * const kAddTagsToNode;
extern NSString * const kCreateTag;

@interface TaggingHttpRequest : ASIHTTPRequest {
@private
    NodeRef *nodeRef;
    NSString *apiMethod;
    NSMutableDictionary *userDictionary;
}

@property (nonatomic, retain) NSString *apiMethod;
@property (nonatomic, readonly) NSDictionary *userDictionary;

- (void)addUserProvidedObject:(id)object forKey:(NSString *)userKey;

//
// GET /alfresco/service/api/node/{store_type}/{store_id}/{id}/tags
// GET /alfresco/service/api/path/{store_type}/{store_id}/{id}/tags
+ (id)httpRequestListAllTags;

//
// POST /alfresco/service/api/tag/{store_type}/{store_id}
+ (id)httpRequestCreateNewTag:(NSString *)tag;

//
// GET /alfresco/service/api/node/{store_type}/{store_id}/{id}/tags
// GET /alfresco/service/api/path/{store_type}/{store_id}/{id}/tags
+ (id)httpRequestGetNodeTagsForNode:(NodeRef *)nodeRef;

//
// POST /alfresco/service/api/node/{store_type}/{store_id}/{id}/tags
// POST /alfresco/service/api/path/{store_type}/{store_id}/{id}/tags
+ (id)httpRequestAddTags:(NSArray *)tags toNode:(NodeRef *)nodeRef;


// Helper Method
+ (NSArray *)tagsArrayWithResponseString:(NSString *)responseString;

@end
