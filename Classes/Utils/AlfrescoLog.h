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
//  AlfrescoLog.h
//

#import <Foundation/Foundation.h>

@interface AlfrescoLog : NSObject

typedef enum
{
    AlfrescoLogLevelOff = 0,
    AlfrescoLogLevelError,
    AlfrescoLogLevelWarning,
    AlfrescoLogLevelInfo,
    AlfrescoLogLevelDebug,
    AlfrescoLogLevelTrace
} AlfrescoLogLevel;

@property (nonatomic, assign) AlfrescoLogLevel logLevel;

/**
 * Returns the shared singleton
 */
+ (AlfrescoLog *)sharedInstance;

/**
 * Designated initializer. Can be used when not instanciating this class in singleton mode.
 */
- (id)initWithLogLevel:(AlfrescoLogLevel)logLevel;

- (NSString *)stringForLogLevel:(AlfrescoLogLevel)logLevel;

- (void)logErrorFromError:(NSError *)error;
- (void)logErrorFromString:(NSString *)errorMsg;
- (void)logWarning:(NSString *)warningMsg;
- (void)logInfo:(NSString *)infoMsg;
- (void)logDebug:(NSString *)debugMsg;
- (void)logTrace:(NSString *)traceMsg;

@end

/**
 * Global logging utility function
 */
void alfrescoLog(AlfrescoLogLevel logLevel, NSString *formatString, ...);
