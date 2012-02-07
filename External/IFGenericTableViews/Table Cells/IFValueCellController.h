//
//  IFValueCellController.h
//  Thunderbird
//
//	Created by Craig Hockenberry on 1/29/09.
//	Copyright 2009 The Iconfactory. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IFCellController.h"
#import "IFCellModel.h"

@interface IFValueCellController : NSObject <IFCellController>
{
	NSString *label;
	id<IFCellModel> model;
	NSString *key;
	
	UIColor *backgroundColor;

	NSInteger indentationLevel;
	
	NSURL *url;
	NSString *defaultValue;
}

@property (nonatomic, retain) UIColor *backgroundColor;

@property (nonatomic, assign) NSInteger indentationLevel;
@property (nonatomic, retain) NSURL *url;
@property (nonatomic, retain) NSString *defaultValue;

- (id)initWithLabel:(NSString *)newLabel atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel;
- (id)initWithLabel:(NSString *)newLabel atKey:(NSString *)newKey withURL:(NSURL *)newURL inModel:(id<IFCellModel>)newModel;

@end
