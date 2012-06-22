//
//  IFChoiceCellController.h
//  Thunderbird
//
//	Created by Craig Hockenberry on 1/29/09.
//	Copyright 2009 The Iconfactory. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IFCellController.h"
#import "IFCellFirstResponder.h"
#import "IFCellModel.h"

#import "IFChoiceTableViewController.h"

@interface IFChoiceCellController : NSObject <IFCellController, IFCellControllerFirstResponder>
{
	NSString *label;
	NSArray *choices;
	id<IFCellModel> model;
	NSString *key;
	
	UIColor *backgroundColor;
	UIColor *viewBackgroundColor;
	UITableViewCellSelectionStyle selectionStyle;

	SEL refreshAction;
	id refreshTarget;
	SEL updateAction;
	id updateTarget;

	NSString *footerNote;
	
	NSInteger indentationLevel;
	
	UITableViewController *tableController;
	NSIndexPath *cellIndexPath;
	id<IFCellControllerFirstResponderHost>cellControllerFirstResponderHost;
	
	BOOL selectionOptional;
	BOOL autoAdvance;
	NSString *separator;
	BOOL showSelectedValueAsLabel;
	
	UINavigationController *navigationController;
}

@property (nonatomic, retain) NSArray *choices;
@property (nonatomic, retain) UIColor *backgroundColor;
@property (nonatomic, retain) UIColor *viewBackgroundColor;
@property (nonatomic, assign) UITableViewCellSelectionStyle selectionStyle;
 
@property (nonatomic, assign) SEL refreshAction;
@property (nonatomic, assign) id refreshTarget;
@property (nonatomic, assign) SEL updateAction;
@property (nonatomic, assign) id updateTarget;

@property (nonatomic, retain) NSString *footerNote;
	
@property (nonatomic, assign) NSInteger indentationLevel;

@property (nonatomic, retain) UITableViewController *tableController;
@property (nonatomic, retain) NSIndexPath *cellIndexPath;
@property (nonatomic, assign) id<IFCellControllerFirstResponderHost>cellControllerFirstResponderHost;

@property (nonatomic, assign) BOOL selectionOptional;
@property (nonatomic, retain) NSString *separator; // if specified then allow multile selection
@property (nonatomic, assign) BOOL showSelectedValueAsLabel;

- (id)initWithLabel:(NSString *)newLabel andChoices:(NSArray *)newChoices atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel;
- (NSString *)labelForValue:(NSString *)value;

@end
