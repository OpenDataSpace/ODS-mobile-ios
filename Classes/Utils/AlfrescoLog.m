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
 * Copyright (C) 2011-2013 Alfresco Software Limited.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  AlfrescoLog.m
//

#import "AlfrescoLog.h"

@implementation AlfrescoLog

#pragma mark - Lifecycle methods

+ (AlfrescoLog *)sharedInstance
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

- (id)init
{
    return [self initWithLogLevel:ALFRESCO_LOG_LEVEL];
}

- (id)initWithLogLevel:(AlfrescoLogLevel)logLevel
{
    self = [super init];
    if (self)
    {
        _logLevel = logLevel;
    }
    return self;
}

#pragma mark - Info methods

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ Log level: %@", [super description], [self stringForLogLevel:self.logLevel]];
}

- (NSString *)stringForLogLevel:(AlfrescoLogLevel)logLevel
{
    NSString *result = nil;
    
    switch(logLevel)
    {
        case AlfrescoLogLevelOff:
            result = @"OFF";
            break;
        case AlfrescoLogLevelError:
            result = @"ERROR";
            break;
        case AlfrescoLogLevelWarning:
            result = @"WARN";
            break;
        case AlfrescoLogLevelInfo:
            result = @"INFO";
            break;
        case AlfrescoLogLevelDebug:
            result = @"DEBUG";
            break;
        case AlfrescoLogLevelTrace:
            result = @"TRACE";
            break;
        default:
            result = @"UNKNOWN";
    }
    
    return result;
}

#pragma mark - Logging methods

- (void)logErrorFromError:(NSError *)error
{
    if (self.logLevel != AlfrescoLogLevelOff)
    {
        NSString *message = [NSString stringWithFormat:@"[%ld] %@", (long)error.code, error.localizedDescription];
        [self logMessage:message forLogLevel:AlfrescoLogLevelError];
    }
}

- (void)logError:(NSString *)format, ...
{
    if (self.logLevel != AlfrescoLogLevelOff)
    {
        // Build log message string from variable args list
        va_list args;
        va_start(args, format);
        NSString *message = [[[NSString alloc] initWithFormat:format arguments:args] autorelease];
        va_end(args);

        [self logMessage:message forLogLevel:AlfrescoLogLevelError];
    }
}

- (void)logWarning:(NSString *)format, ...
{
    if (self.logLevel >= AlfrescoLogLevelWarning)
    {
        // Build log message string from variable args list
        va_list args;
        va_start(args, format);
        NSString *message = [[[NSString alloc] initWithFormat:format arguments:args] autorelease];
        va_end(args);
        
        [self logMessage:message forLogLevel:AlfrescoLogLevelWarning];
    }
}

- (void)logInfo:(NSString *)format, ...
{
    if (self.logLevel >= AlfrescoLogLevelInfo)
    {
        // Build log message string from variable args list
        va_list args;
        va_start(args, format);
        NSString *message = [[[NSString alloc] initWithFormat:format arguments:args] autorelease];
        va_end(args);
        
        [self logMessage:message forLogLevel:AlfrescoLogLevelInfo];
    }
}

- (void)logDebug:(NSString *)format, ...
{
    if (self.logLevel >= AlfrescoLogLevelDebug)
    {
        // Build log message string from variable args list
        va_list args;
        va_start(args, format);
        NSString *message = [[[NSString alloc] initWithFormat:format arguments:args] autorelease];
        va_end(args);
        
        [self logMessage:message forLogLevel:AlfrescoLogLevelDebug];
    }
}

- (void)logTrace:(NSString *)format, ...
{
    if (self.logLevel == AlfrescoLogLevelTrace)
    {
        // Build log message string from variable args list
        va_list args;
        va_start(args, format);
        NSString *message = [[[NSString alloc] initWithFormat:format arguments:args] autorelease];
        va_end(args);
        
        [self logMessage:message forLogLevel:AlfrescoLogLevelTrace];
    }
}

#pragma mark - Helper methods

- (void)logMessage:(NSString *)message forLogLevel:(AlfrescoLogLevel)logLevel
{
    NSString *callingMethod = [self methodNameFromCallStack:[[NSThread callStackSymbols] objectAtIndex:2]];
    NSLog(@"%@ %@ %@", [self stringForLogLevel:logLevel], callingMethod, message);
}

- (NSString *)methodNameFromCallStack:(NSString *)topOfStack
{
    NSString *methodName = nil;
    
    if (topOfStack != nil)
    {
        NSRange startBracketRange = [topOfStack rangeOfString:@"[" options:NSBackwardsSearch];
        if (NSNotFound != startBracketRange.location)
        {
            NSString *start = [topOfStack substringFromIndex:startBracketRange.location];
            NSRange endBracketRange = [start rangeOfString:@"]" options:NSBackwardsSearch];
            if (NSNotFound != endBracketRange.location)
            {
                methodName = [start substringToIndex:endBracketRange.location + 1];
            }
        }
    }
    
    return methodName;
}

@end

#pragma mark - Global logging utility function

void alfrescoLog(AlfrescoLogLevel logLevel, NSString *formatString, ...)
{
    AlfrescoLog *logger = [AlfrescoLog sharedInstance];
    if (logger.logLevel >= logLevel)
    {
        // Build log message string from variable args list
        va_list args;
        va_start(args, formatString);
        NSString *message = [[[NSString alloc] initWithFormat:formatString arguments:args] autorelease];
        va_end(args);
        
        [logger logMessage:message forLogLevel:logLevel];
    }
}
