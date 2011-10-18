//
//  IFCustomSwitchCellController.h
//  Denver311
//
//  Created by Gi Hyun Lee on 8/11/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IFCellController.h"
#import "IFCellModel.h"

#import "CSCustomSwitch.h"

@interface IFCustomSwitchCellController : NSObject {
	NSString *label;
	id<IFCellModel> model;
	NSString *key;
	
	UIColor *backgroundColor;
	
	SEL updateAction;
	id updateTarget;
}

@property (nonatomic, retain) UIColor *backgroundColor;

@property (nonatomic, assign) SEL updateAction;
@property (nonatomic, assign) id updateTarget;

- (id)initWithLabel:(NSString *)newLabel atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel;
- (BOOL)equalToYes:(NSString *)value;

@end
