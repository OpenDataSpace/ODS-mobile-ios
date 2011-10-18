//
//  IFSegmentedCellController.h
//  Thunderbird
//
//	Created by Bindu Wavell from Craig's Switch and Choice code
//  Copyright 2010 Zia Consulting, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IFCellController.h"
#import "IFCellModel.h"

@interface IFSegmentedCellController : NSObject <IFCellController>
{
	NSString *label;
	NSArray *choices;
	id<IFCellModel> model;
	NSString *key;
	
	UIColor *backgroundColor;

	SEL updateAction;
	id updateTarget;
}

@property (nonatomic, retain) UIColor *backgroundColor;

@property (nonatomic, assign) SEL updateAction;
@property (nonatomic, assign) id updateTarget;

- (id)initWithLabel:(NSString *)newLabel andChoices:(NSArray *)newChoices atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel;

@end
