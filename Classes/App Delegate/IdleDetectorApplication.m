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
//  IdleDetectorApplication.m
//

#import "IdleDetectorApplication.h"
#import "SessionKeychainManager.h"

@interface IdleDetectorApplication (Private)
- (void)resetIdleTimer;
@end

@implementation IdleDetectorApplication

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [idleTimer release];
    [timerStartedAt release];
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if(self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    
    return self;
}

- (NSInteger)maxIdleTime
{
    return [[FDKeychainUserDefaults standardUserDefaults] integerForKey:@"sessionForgetTimeout"] * 60;
}

#pragma mark - Detecting user idle time

- (void)sendEvent:(UIEvent *)event 
{
    [super sendEvent:event];
    
    // Only want to reset the timer on a Began touch or an Ended touch, to reduce the number of timer resets.
    NSSet *allTouches = [event allTouches];
    if ([allTouches count] > 0) 
    {
        // allTouches count only ever seems to be 1, so anyObject works here.
        UITouchPhase phase = ((UITouch *)[allTouches anyObject]).phase;
        if (phase == UITouchPhaseBegan || phase == UITouchPhaseEnded)
        {
            [self resetIdleTimer];
        }
    }
}

#pragma mark - Timer management

- (void)resetIdleTimer 
{
    if (idleTimer)
    {
        [idleTimer invalidate];
        [idleTimer release];
    }
    if (timerStartedAt)
    {
        [timerStartedAt release];
    }
    
    idleTimer = [[NSTimer scheduledTimerWithTimeInterval:[self maxIdleTime] target:self selector:@selector(idleTimerExceeded) userInfo:nil repeats:NO] retain];
    timerStartedAt = [[NSDate date] retain];
}

- (void)idleTimerExceeded 
{
    AlfrescoLogDebug(@"idle time exceeded");
    [[SessionKeychainManager sharedManager] clearSession];
}

- (void)invalidateIdleTimer
{
    [idleTimer invalidate];
    [idleTimer release];
    idleTimer = nil;
    [timerStartedAt release];
    timerStartedAt = nil;
}

#pragma mark - Notification handlers

- (void)handleDidBecomeActiveNotification:(NSNotification *)notification
{
    if ([idleTimer isValid])
    {
        // Reset the timer to fire at the correct time
        [idleTimer setFireDate:[NSDate dateWithTimeInterval:[self maxIdleTime] sinceDate:timerStartedAt]];
    }
}

@end
