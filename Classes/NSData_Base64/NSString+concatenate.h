//
//  NSString+concatenate.h
//  FreshDocs
//
//  Created by Michael Muller on 5/11/10.
//  Copyright 2010 Michael J Muller. All rights reserved.
//  Copyright 2011 Zia Consulting, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (concatenate)

+ (NSString *) stringByAppendingString:(NSString *)string toString:(NSString *) otherString;

@end
