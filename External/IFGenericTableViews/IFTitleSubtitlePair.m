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
 * Portions created by the Initial Developer are Copyright (C) 2011
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  IFKeyValuePair.m
//

#import "IFTitleSubtitlePair.h"

@implementation IFTitleSubtitlePair

@synthesize key, pairTitle, pairSubtitle;

- (void)dealloc {
	[key release];
	[pairTitle release];
	[pairSubtitle release];
	[super dealloc];
}


- (id)initWithTitle:(NSString *)newTitle andSubtitle:(NSString *)newSubtitle 
{
	self = [super init];
	if (self != nil)
	{		
		pairTitle    = [newTitle retain];
		pairSubtitle = [newSubtitle retain];
	}
	return self;
}

+ (IFTitleSubtitlePair *)titleSubtitlePairWithTitle:(NSString *)newTitle andSubtitle:(NSString *)newSubtitle 
{
	return [[[IFTitleSubtitlePair alloc] initWithTitle:newTitle andSubtitle:newSubtitle] autorelease];
}

@end
