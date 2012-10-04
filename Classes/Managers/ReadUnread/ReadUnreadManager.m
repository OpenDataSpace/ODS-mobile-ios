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
//  ReadUnreadManager.m
//

#import "ReadUnreadManager.h"
#import "FileUtils.h"

NSString * const kReadUnreadStoreFilename = @"ReadStatusDataStore.plist";

@interface ReadUnreadManager ()
{
    NSMutableDictionary *_readUnreadCache;
}

@end

@implementation ReadUnreadManager

- (void)dealloc
{
    [_readUnreadCache release];
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if(self)
    {
        _readUnreadCache = [[NSKeyedUnarchiver unarchiveObjectWithFile:[FileUtils pathToConfigFile:kReadUnreadStoreFilename]] retain];
        if(!_readUnreadCache)
        {
            _readUnreadCache = [[NSMutableDictionary alloc] init];
        }
    }
    return self;
}

- (BOOL)readStatusForTaskId:(NSString *)taskId
{
    if ([_readUnreadCache objectForKey:taskId] != nil)
    {
        return [[_readUnreadCache objectForKey:taskId] boolValue];
    }
    else 
    {
        return NO;
    }
}

- (void)saveReadStatus:(BOOL)readStatus taskId:(NSString *)taskId
{
    [_readUnreadCache setObject:[NSNumber numberWithBool:readStatus] forKey:taskId];
    [self synchronize];
}

- (void)removeReadStatusForTaskId:(NSString *)taskId
{
    [_readUnreadCache removeObjectForKey:taskId];
    [self synchronize];
}

- (void)synchronize
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:_readUnreadCache];
    NSError *error = nil;
    NSString *path= [FileUtils pathToConfigFile:kReadUnreadStoreFilename];
    [data writeToFile:path options:NSDataWritingAtomic error:&error];
}

#pragma mark - Singleton

static ReadUnreadManager *sharedReadUnreadManager = nil;

+ (ReadUnreadManager *)sharedManager
{
    if (sharedReadUnreadManager == nil) {
        sharedReadUnreadManager = [[super allocWithZone:NULL] init];
    }
    return sharedReadUnreadManager;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [[self sharedManager] retain];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax;  //denotes an object that cannot be released
}

- (oneway void)release
{
    //do nothing
}

- (id)autorelease
{
    return self;
}

@end
