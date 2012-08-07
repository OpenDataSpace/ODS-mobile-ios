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
//  ConnectivityManager.m
//

#import "ConnectivityManager.h"

@implementation ConnectivityManager
@synthesize hostReach = _hostReach;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_hostReach release];
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if(self)
    {
        //NSString *host = @"http://www.alfresco.com/"; // Put your host here
        
        // Set up host reach property
        _hostReach = [[Reachability reachabilityForInternetConnection] retain];
                          
        // Enable the status notifications
        [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
        [_hostReach startNotifier];
    }
    return self;
}

- (void)reachabilityChanged:(NSNotification *)note {
    Reachability *reachability = [note object];
    NSParameterAssert([reachability isKindOfClass:[Reachability class]]);
    if(reachability == _hostReach)
    {
        //If we need to take some action when we have/loss internet connection
        //we should put the code in here
    }
}

- (BOOL)hasInternetConnection
{
    return [self.hostReach currentReachabilityStatus] != NotReachable;
}


+ (ConnectivityManager *)sharedManager
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}
@end
