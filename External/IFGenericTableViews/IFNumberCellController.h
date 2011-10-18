//
//  IFNumberCellController.h
//  XpenserUtility
//
//  Created by Bindu Wavell on 12/22/09.
//  Copyright 2009 Zia Consulting, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFTextCellController.h"

@interface IFNumberCellController : IFTextCellController {
	UIButton *returnKeyButton;
}

- (void)destroyButton;

@end
