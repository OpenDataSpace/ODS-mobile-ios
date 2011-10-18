//
//  IFLinkCellController.h
//  Thunderbird
//
//	Created by Craig Hockenberry on 1/29/09.
//	Copyright 2009 The Iconfactory. All rights reserved.
//
//  Based on work created by Matt Gallagher on 27/12/08.
//  Copyright 2008 Matt Gallagher. All rights reserved.
//	For more information: http://cocoawithlove.com/2008/12/heterogeneous-cells-in.html
//

#import <UIKit/UIKit.h>

#import "IFCellController.h"
#import "IFTitleSubtitlePair.h"
#import "IFCellModel.h"

@interface IFMultilineCellController : NSObject <IFCellController>
{
	NSString *title;
	NSString *subtitle;
	NSString *defaultSubtitle;
	Class controllerClass;
	id<IFCellModel> model;
	NSString *key;
	UIColor *backgroundColor;
	UITableViewController *tableController;
	
	SEL selectionAction;
	id selectionTarget;
	NSIndexPath *cellIndexPath;
	CGFloat cellHeight;
	BOOL isRequired;
	
	UIColor *titleTextColor;
	UIColor *subtitleTextColor;
	UIFont	*titleFont;
	UIFont	*subTitleFont;
}

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *subtitle;
@property (nonatomic, retain) NSString *defaultSubtitle;
@property (nonatomic, assign) Class controllerClass;
@property (nonatomic, retain) NSString *key;
@property (nonatomic, retain) UIColor *backgroundColor;
@property (nonatomic, retain) UITableViewController *tableController;
@property (nonatomic, assign) SEL selectionAction;
@property (nonatomic, assign) id selectionTarget;
@property (nonatomic, assign) NSIndexPath *cellIndexPath;
@property (nonatomic, assign) BOOL isRequired;
@property (nonatomic, retain) UIColor *titleTextColor;
@property (nonatomic, retain) UIColor *subtitleTextColor;
@property (nonatomic, retain) UIFont *titleFont;
@property (nonatomic, retain) UIFont *subTitleFont;

- (id)initWithTitle:(NSString *)newTitle andSubtitle:(NSString *)newSubtitle inModel:(id<IFCellModel>)newModel;
- (id<IFCellModel>)model;
- (CGFloat)heightForSelfSavingHieght:(BOOL)saving;
- (void)reloadCell;

@end
