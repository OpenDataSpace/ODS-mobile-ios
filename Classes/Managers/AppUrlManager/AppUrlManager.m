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
//  AppUrlManager.m
//

#import "AppUrlManager.h"
#import "AddAccountUrlHandler.h"
#import "FileUrlHandler.h"

@implementation AppUrlManager

- (void)dealloc
{
    [_handlers release];
    [super dealloc];
}

- (id)initWithHandlers:(NSArray *)handlers
{
    self = [super init];
    if(self)
    {
        NSMutableDictionary *handlersDict = [NSMutableDictionary dictionaryWithCapacity:[handlers count]];
        for(id<AppUrlHandlerProtocol> handler in handlers)
        {
            [handlersDict setObject:handler forKey:[handler hostHandle]];
        }
        _handlers = [[NSDictionary alloc] initWithDictionary:handlersDict];
    }
    return self;
}

- (BOOL)handleUrl:(NSURL *)url annotation:(id)annotation
{
    // Would be nice to use a keypath for this but I (BW) could get that working...
    // This pulls the first urlScheme from the main bundle.
    NSArray *urlTypes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleURLTypes"];
    NSDictionary *urlType = (nil == urlTypes ? nil : [urlTypes objectAtIndex:0]);
    NSArray *urlSchemes = (nil == urlType ? nil : [urlType objectForKey:@"CFBundleURLSchemes"]);
    NSString *urlScheme = (nil == urlSchemes ? nil : [urlSchemes objectAtIndex:0]);
    
    NSString *incomingProtocol = [url scheme];
    NSString *incomingHost     = [url host];
    id<AppUrlHandlerProtocol> handler = [_handlers objectForKey:incomingHost];
    if (nil != urlScheme && [incomingProtocol isEqual:urlScheme] && handler) 
    {
        [handler handleUrl:url annotation:annotation];
    }
    else
    {
        return NO;
    }
    return YES;
}

#pragma mark - Shared instance
static AppUrlManager *_sharedInstance;

+ (AppUrlManager *)sharedManager
{
    if(!_sharedInstance)
    {
        AddAccountUrlHandler *addAccountHandler = [[AddAccountUrlHandler alloc] init];
        FileUrlHandler *fileHandler = [[FileUrlHandler alloc] init];
        NSArray *handlers = [NSArray arrayWithObjects:addAccountHandler, fileHandler, nil];
        _sharedInstance = [[AppUrlManager alloc] initWithHandlers:handlers];
        [addAccountHandler release];
        [fileHandler release];
    }
    
    return _sharedInstance;
}

@end
