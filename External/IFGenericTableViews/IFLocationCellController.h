//
//  IFLocationCellController.h
//  Denver311
//
//  Created by Gi Hyun Lee on 7/15/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IFCellController.h"
#import "IFCellModel.h"
#import "LocationViewController.h"

@interface IFLocationCellController : NSObject <IFCellController> {
	NSString *label;
	id<IFCellModel> model;
	NSString *key;
	
	UIColor *backgroundColor;
	UIColor *viewBackgroundColor;
	UITableViewCellSelectionStyle selectionStyle;
	
	NSInteger indentationLevel;
	
	UITableViewController *tableViewController;
	NSIndexPath *cellIndexPath;
}

@property (nonatomic, retain) UIColor *backgroundColor;
@property (nonatomic, retain) UIColor *viewBackgroundColor;
@property (nonatomic, assign) UITableViewCellSelectionStyle selectionStyle;
@property (nonatomic, assign) NSInteger indentationLevel;
@property (nonatomic, retain) UITableViewController *tableViewController;
@property (nonatomic, retain) NSIndexPath *cellIndexPath;

- (id)initWithLabel:(NSString *)newLabel atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel;

@end
