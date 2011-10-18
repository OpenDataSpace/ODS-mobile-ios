//
//  IFKeyValuePair.h
//  XpenserUtility
//
//  Created by Bindu Wavell on 1/10/10.
//  Copyright 2010 Zia Consulting, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFTitleSubtitlePair.h"

@interface IFTitleSubtitlePair : NSObject {
	NSString *key;
	NSString *pairTitle;
	NSString *pairSubtitle;
}

@property (nonatomic, retain) NSString *key;
@property (nonatomic, retain) NSString *pairTitle;
@property (nonatomic, retain) NSString *pairSubtitle;

- (id)initWithTitle:(NSString *)newTitle andSubtitle:(NSString *)newSubtitle;
+ (IFTitleSubtitlePair *)titleSubtitlePairWithTitle:(NSString *)newTitle andSubtitle:(NSString *)newSubtitle;

@end
