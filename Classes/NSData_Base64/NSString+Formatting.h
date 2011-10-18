//
//  NSString+Formatting.h
//  FreshDocs
//
//  Created by Gi Hyun Lee on 11/9/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (Formatting)

+ (NSString *)stringForFileSize:(unsigned long long)size;

@end
