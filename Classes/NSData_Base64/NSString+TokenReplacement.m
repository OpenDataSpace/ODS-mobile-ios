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
//  NSString+TokenReplacement.m
//

#import "NSString+TokenReplacement.h"

@implementation NSString (TokenReplacement)

- (NSString *)stringBySubstitutingTokensInDict:(NSDictionary *)tokenDict
{
	NSMutableString *mString = [NSMutableString stringWithString:self];
	NSScanner *scanner = [NSScanner scannerWithString:self];
    
	while (![scanner isAtEnd])
	{
		if ([scanner scanString:@"$" intoString:nil])
		{
			NSString *tokenName;
			if ([scanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&tokenName])
			{
				id value = [tokenDict objectForKey:tokenName];
				if (value && [value isKindOfClass:[NSString class]])
				{
					[mString replaceOccurrencesOfString:[@"$" stringByAppendingString:tokenName] 
                                             withString:value 
                                                options:NSLiteralSearch 
                                                  range:NSMakeRange(0, [mString length])];
				}
			}
		}
        
		[scanner scanUpToString:@"$" intoString:nil];
	}
    
	return [NSString stringWithString:mString];
}

@end
