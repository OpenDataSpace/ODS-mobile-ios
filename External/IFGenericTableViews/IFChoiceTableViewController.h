//
//  IFChoiceTableViewController.h
//  Thunderbird
//
//  Created by Craig Hockenberry on 1/29/09.
//  Copyright 2009 The Iconfactory. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IFCellModel.h"

@class IFChoiceTableViewController;

@interface IFChoiceTableViewController : UITableViewController
{
	SEL updateAction;
	id updateTarget;

	NSString *footerNote;
	
	NSArray *choices;
	id<IFCellModel> model;
	NSString *key;
	
	BOOL selectionOptional;
	NSString *separator;
	
	UIColor *backgroundColor;
	UITableViewCellSelectionStyle selectionStyle;
}

@property (nonatomic, assign) SEL updateAction;
@property (nonatomic, assign) id updateTarget;

@property (nonatomic, retain) NSString *footerNote;
	
@property (nonatomic, retain) NSArray *choices;
@property (nonatomic, retain) id<IFCellModel> model;
@property (nonatomic, retain) NSString *key;

@property (nonatomic, assign) BOOL selectionOptional;
@property (nonatomic, retain) NSString *separator;

@property (nonatomic, retain) UIColor *backgroundColor;
@property (nonatomic, assign) UITableViewCellSelectionStyle selectionStyle;

@end

