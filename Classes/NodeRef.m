/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Alfresco Mobile App.
 *
 * The Initial Developer of the Original Code is Zia Consulting, Inc.
 * Portions created by the Initial Developer are Copyright (C) 2011
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  NodeRef.m
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
    NSRange range = [theCmisObjectId rangeOfString:@";"];
    if (range.location != NSNotFound) {
        theCmisObjectId = [theCmisObjectId substringToIndex:range.location];
    }
    return [[[NodeRef alloc] initWithCmisObjectId:theCmisObjectId] autorelease];   
}

@end
