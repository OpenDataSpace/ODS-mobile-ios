//
//  NSURL+HTTPURLUtils.h
//  FreshDocs
//
//  Created by Gi Hyun Lee on 10/14/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSURL (HTTPURLUtils)

- (NSURL *)URLByAppendingParameterString:(NSString *)parameterString;
- (NSURL *)URLByAppendingParameterDictionary:(NSDictionary *)parameterdictionary;

@end
