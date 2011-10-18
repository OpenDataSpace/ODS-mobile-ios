//
//  NodeRef.m
//  FreshDocs
//
//  Created by Gi Hyun Lee on 7/20/11.
//  Copyright 2011 Zia Consulting. All rights reserved.
//

#import "NodeRef.h"

@implementation NodeRef
@synthesize cmisObjectId;
@synthesize storeType;
@synthesize storeId;
@synthesize objectId;

-(void)dealloc
{
    if (cmisObjectId != nil)
        [cmisObjectId release];
    cmisObjectId = nil;
    
    if (storeType != nil)    
        [storeType release];
    storeType = nil;
    
    if (storeId != nil)
        [storeId release];
    storeId = nil;
    
    if (objectId != nil)
        [objectId release];
    objectId = nil;
    
    [super dealloc];
}

- (id)initWithCmisObjectId:(NSString *)theCmisObjectId
{   
    self = [super init];
    if (self) {
        if (theCmisObjectId) {
            cmisObjectId = [theCmisObjectId retain];
            
            NSArray *storeTypeSplit = [theCmisObjectId componentsSeparatedByString:@"://"];
            NSArray *idSplit = [[storeTypeSplit objectAtIndex:1] componentsSeparatedByString:@"/"];
            storeType = [[storeTypeSplit objectAtIndex:0] retain];
            storeId = [[idSplit objectAtIndex:0] retain]; 
            objectId = [[idSplit objectAtIndex:1] retain];
            
            NSLog(@"StoreType: %@, StoreId: %@, ObjectID: %@", storeType, storeId, objectId);
        }
    }
    return self;
}

+ (id)nodeRefFromCmisObjectId:(NSString *)theCmisObjectId
{
    return [[[NodeRef alloc] initWithCmisObjectId:theCmisObjectId] autorelease];   
}

@end
