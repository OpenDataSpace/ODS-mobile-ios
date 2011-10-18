//
//  IFCellFirstResponderDelegate.h
//  XpenserUtility
//
//  Created by Bindu Wavell on 12/20/09.
//  Copyright 2009 Zia Consulting, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFCellController.h"

@protocol IFCellControllerFirstResponderHost
- (void)advanceToNextResponderFromCellController: (id<IFCellController>)cellController;
- (void)lastResponderIsDone: (id<IFCellController>)cellController;
@end


@protocol IFCellControllerFirstResponder
	-(void)assignFirstResponderHost: (NSObject<IFCellControllerFirstResponderHost> *)hostIn;
	-(void)becomeFirstResponder;
	-(void)resignFirstResponder;
@end
