//
//  IFKeyValuePair.h
//  XpenserUtility
//
//  Created by Bindu Wavell on 1/10/10.
//  Copyright 2010 Zia Consulting, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFLabelValuePair.h"

@interface IFLabelValuePair : NSObject {
	NSString *pairLabel;
	NSString *pairValue;
}

@property (nonatomic, retain) NSString *pairLabel;
@property (nonatomic, retain) NSString *pairValue;

- (id)initWithLabel:(NSString *)newLabel andValue:(NSString *)newValue;
+ (IFLabelValuePair *)labelValuePairWithLabel:(NSString *)newLabel andValue:(NSString *)newValue;

@end
