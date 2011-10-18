//
//  IFTemporaryModel.m
//  Thunderbird
//
//  Created by Craig Hockenberry on 1/30/09.
//  Copyright 2009 The Iconfactory. All rights reserved.
//

#import "IFTemporaryModel.h"

@implementation IFTemporaryModel

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		_temporaryModel = [[NSMutableDictionary dictionary] retain];
	}
	return self;
}

- (id)initWithDictionary:(NSMutableDictionary *)dictionary
{
	self = [super init];
	if (self != nil)
	{
		_temporaryModel = [[NSMutableDictionary dictionaryWithDictionary:dictionary] retain];
	}
	return self;
}


- (void)dealloc
{
	[_temporaryModel release];

	[super dealloc];
}

- (void)setObject:(id)value forKey:(NSString *)key
{
	if (nil == key) return;
	
	[_temporaryModel setValue:value forKey:key];
}

- (id)objectForKey:(NSString *)key
{
	if (nil == key) return nil;
	
	return [_temporaryModel valueForKey:key];
}

- (NSMutableDictionary *)dictionary
{
//	return [NSMutableDictionary dictionaryWithDictionary:_temporaryModel];
	return _temporaryModel;
}

@end
