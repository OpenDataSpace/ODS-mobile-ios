//
//  TaskItemListHTTPRequest.m
//  FreshDocs
//
//  Created by Tijs Rademakers on 14/08/2012.
//  Copyright (c) 2012 U001b. All rights reserved.
//

#import "TaskItemListHTTPRequest.h"
#import "SBJSON.h"

@interface TaskItemListHTTPRequest () // Private
@property (nonatomic, readwrite, retain) NSArray *taskItems;
@end

@implementation TaskItemListHTTPRequest

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
    NSString *itemsString = [responseJSONObject valueForKeyPath:@"data.formData.assoc_packageItems"];
    
#if MOBILE_DEBUG
    NSLog(@"Task items: %@", itemsString);
#endif
    
    NSMutableArray *itemArray = [NSMutableArray array];
    if(itemsString && [itemsString class] != [NSNull class])
    {
        NSArray *splittedItemsArray = [itemsString componentsSeparatedByString:@","];
        if (splittedItemsArray)
        {
            for (NSString *item in splittedItemsArray) {
                [itemArray addObject:item];
            }
        }
    }
    
    [jsonObj release];
    
	[self setTaskItems:itemArray];
}

+ (TaskItemListHTTPRequest *)taskItemRequestForTaskId:(NSString *)taskId accountUUID:(NSString *)uuid tenantID:(NSString *)tenantID
{
    TaskItemListHTTPRequest *request = [TaskItemListHTTPRequest requestForServerAPI:kServerAPITaskItemCollection accountUUID:uuid tenantID:tenantID];
    request.accountUUID = uuid;
    request.tenantID = tenantID;
    
    NSMutableDictionary *postDict = [NSMutableDictionary dictionaryWithCapacity:3];
    [postDict setValue:@"task" forKey:@"itemKind"];
    [postDict setValue:taskId forKey:@"itemId"];
    NSArray *fieldArray = [NSArray arrayWithObject:@"packageItems"];
    [postDict setObject:fieldArray forKey:@"fields"];
    
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
