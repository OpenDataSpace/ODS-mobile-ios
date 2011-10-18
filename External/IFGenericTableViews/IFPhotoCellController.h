//
//  IFPhotoCellController.h
//  XpenserUtility
//
//  Created by Bindu Wavell on 1/3/10.
//  Copyright 2010 Zia Consulting, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IFControlTableViewCell.h"
#import "IFCellController.h"
#import "IFCellFirstResponder.h"
#import "IFCellModel.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
#define IS_IPAD ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
#endif

@interface IFPhotoCellController : NSObject <IFCellController, IFCellControllerFirstResponder, UIImagePickerControllerDelegate, UINavigationControllerDelegate,UIActionSheetDelegate> {
	NSString *label;
	id<IFCellModel> model;
	NSString *key;
	
	UIColor *backgroundColor;
	UITableViewCellSelectionStyle selectionStyle;
	
	SEL updateAction;
	id updateTarget;
	
	NSInteger indentationLevel;
	
	UITableViewController *tableController;
	NSIndexPath *cellIndexPath;
	id<IFCellControllerFirstResponderHost>cellControllerFirstResponderHost;
	
	BOOL autoAdvance;
	CGFloat maxWidth;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	// UIPopoverController *
	id popover;
#endif
}

@property (nonatomic, retain) UIColor *backgroundColor;
@property (nonatomic, assign) UITableViewCellSelectionStyle selectionStyle;

@property (nonatomic, assign) SEL updateAction;
@property (nonatomic, assign) id updateTarget;

@property (nonatomic, assign) NSInteger indentationLevel;

@property (nonatomic, retain) UITableViewController *tableController;
@property (nonatomic, retain) NSIndexPath *cellIndexPath;
@property (nonatomic, assign) id<IFCellControllerFirstResponderHost>cellControllerFirstResponderHost;
@property (nonatomic, assign) CGFloat maxWidth;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
@property (nonatomic, retain) id popover;
#endif

- (id)initWithLabel:(NSString *)newLabel atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel;
- (CGFloat)imageHeightToWidthRatio:(UIImage *)image;

@end
