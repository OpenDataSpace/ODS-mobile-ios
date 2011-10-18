//
//  IFGenericTableViewController.h
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

#import "IFCellModel.h"
#import "IFCellFirstResponder.h"

@interface IFGenericTableViewController : UITableViewController<IFCellControllerFirstResponderHost>
{
	NSArray *tableGroups;
	NSArray *tableHeaders;
	NSArray *tableFooters;

	NSObject<IFCellModel> *model;
	BOOL addonstartup;
	
	NSObject<IFCellController> *controllerForReturnHandler;
}

- (void)constructTableGroups;
- (void)assignFirstResponderHostToCellControllers;
- (void)resignAllFirstResponders;
- (void)advanceToNextResponderFromCellController: (NSObject<IFCellController> *)cellController;
- (NSObject<IFCellController> *)cellControllerForIndexPath: (NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForCellController: (NSObject<IFCellController> *)cellController;
- (void)updateAndReload;
- (void)updateAndRefresh;

@property (nonatomic, retain) NSObject<IFCellModel> *model;
@property (nonatomic, assign) NSObject<IFCellController> *controllerForReturnHandler;

@end
