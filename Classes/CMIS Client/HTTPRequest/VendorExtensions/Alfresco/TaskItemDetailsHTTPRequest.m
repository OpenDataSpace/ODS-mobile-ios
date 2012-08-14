//
//  TaskItemDetailsHTTPRequest.m
//  FreshDocs
//
//  Created by Tijs Rademakers on 14/08/2012.
//  Copyright (c) 2012 U001b. All rights reserved.
//

#import "TaskItemDetailsHTTPRequest.h"
#import "SBJSON.h"

@interface TaskItemDetailsHTTPRequest () // Private
@property (nonatomic, readwrite, retain) NSArray *taskItems;
@end

@implementation TaskItemDetailsHTTPRequest

@synthesize taskItems = _taskItems;

- (void)dealloc
{
    [_taskItems release];
    [super dealloc];
}

- (void)requestFinishedWithSuccessResponse
{
	// create a JSON parser
	SBJSON *jsonObj = [SBJSON new];
    
    // parse the returned string
    NSDictionary *responseJSONObject = [jsonObj objectWithString:[self responseString]];
    NSArray *itemArray = [responseJSONObject valueForKeyPath:@"data.items"];
    
#if MOBILE_DEBUG
    NSLog(@"Task item details: %@", itemArray);
#endif
    
    [jsonObj release];
    
	[self setTaskItems:itemArray];
}

+ (TaskItemDetailsHTTPRequest *)taskItemDetailsRequestForItems:(NSArray *)items accountUUID:(NSString *)uuid tenantID:(NSString *)tenantID
{
    TaskItemDetailsHTTPRequest *request = [TaskItemDetailsHTTPRequest requestForServerAPI:kServerAPITaskItemDetailsCollection accountUUID:uuid tenantID:tenantID];
    
    NSMutableDictionary *postDict = [NSMutableDictionary dictionaryWithCapacity:2];
    [postDict setObject:@"nodeRef" forKey:@"itemValueType"];
    NSArray *itemArray = [NSArray arrayWithArray:items];
    [postDict setObject:itemArray forKey:@"items"];
    
    SBJSON *jsonObj = [SBJSON new];
    NSString *postBody = [jsonObj stringWithObject:postDict];
    NSMutableData *postData = [NSMutableData dataWithData:[postBody dataUsingEncoding:NSUTF8StringEncoding]];
    [request setPostBody:postData];
    
    [request setRequestMethod:@"POST"];
    [request setContentLength:[postData length]];
    [request addRequestHeader:@"Content-Type" value:@"application/json"];
    
    return request;
}

@end
