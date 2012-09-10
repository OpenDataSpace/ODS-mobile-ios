//
//  ReadUnreadManager.m
//  FreshDocs
//
//  Created by Tijs Rademakers on 10/09/2012.
//  Copyright (c) 2012 U001b. All rights reserved.
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
