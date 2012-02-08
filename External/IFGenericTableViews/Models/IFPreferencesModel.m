//
//  IFPreferencesModel.m
//  Thunderbird
//
//  Created by Craig Hockenberry on 1/30/09.
//  Copyright 2009 The Iconfactory. All rights reserved.
//

#import "IFPreferencesModel.h"

@implementation IFPreferencesModel

- (void)setObject:(id)value forKey:(NSString *)key
{
	if (nil == key) return;

	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:value forKey:key];
	[userDefaults synchronize];
}

- (id)objectForKey:(NSString *)key
{
	if (nil == key) return nil;
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	return [userDefaults objectForKey:key];
}

- (BOOL)registeredForNotifications
{
	NSLog(@"wtf");
	return YES;
}

- (void)setViewIsDisappearing:(BOOL)newValue
{
	NSLog(@"wtf");
}

@end
