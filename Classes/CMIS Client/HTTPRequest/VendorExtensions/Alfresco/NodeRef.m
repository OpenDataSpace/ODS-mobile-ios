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
 * Portions created by the Initial Developer are Copyright (C) 2011-2012
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  NodeRef.m
//

#import "NodeRef.h"

@interface NodeRef ()
@property (nonatomic, readwrite, copy) NSString *cmisObjectId;
@property (nonatomic, readwrite, copy) NSString *storeType;
@property (nonatomic, readwrite, copy) NSString *storeId;
@property (nonatomic, readwrite, copy) NSString *objectId;
@end

@implementation NodeRef
@synthesize cmisObjectId;
@synthesize storeType;
@synthesize storeId;
@synthesize objectId;

-(void)dealloc
{
    [cmisObjectId release];
    [storeType release];
    [storeId release];
    [objectId release];
    [super dealloc];
}

- (id)initWithCmisObjectId:(NSString *)theCmisObjectId
{   
    self = [super init];
    if (self) {
        if (theCmisObjectId) {
            [self setCmisObjectId:theCmisObjectId];
            
            NSArray *storeTypeSplit = [theCmisObjectId componentsSeparatedByString:@"://"];
            NSArray *idSplit = [[storeTypeSplit objectAtIndex:1] componentsSeparatedByString:@"/"];
            [self setStoreType:[storeTypeSplit objectAtIndex:0]];
            [self setStoreId:[idSplit objectAtIndex:0]];
            [self setObjectId:[idSplit objectAtIndex:1]];
            
            AlfrescoLogDebug(@"StoreType: %@, StoreId: %@, ObjectID: %@", storeType, storeId, objectId);
        }
    }
    return self;
}

+ (NSString *)removeAfterSemiColon:(NSString *)string
{
    NSRange range = [string rangeOfString:@";"];
    if (range.location != NSNotFound) {
        string = [string substringToIndex:range.location];
    }
    
    return string;
}

+ (id)nodeRefFromCmisObjectId:(NSString *)theCmisObjectId
{
    theCmisObjectId = [NodeRef removeAfterSemiColon:theCmisObjectId];
    return [[[NodeRef alloc] initWithCmisObjectId:theCmisObjectId] autorelease];   
}

@end
