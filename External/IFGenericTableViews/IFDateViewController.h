//
//  IFDateViewController.h
//  XpenserUtility
//
//  Created by Bindu Wavell on 1/9/10.
//  Copyright 2010 Zia Consulting, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IFCellModel.h"

@interface IFDateViewController : UIViewController {
    UIDatePicker *datePicker;
	id<IFCellModel> model;
	NSString *key;
	UIDatePickerMode datePickerMode;
    
	UIColor *backgroundColor;
}

@property (nonatomic, retain) IBOutlet UIDatePicker *datePicker;
@property (nonatomic, retain) id<IFCellModel> model;
@property (nonatomic, retain) NSString *key;
@property (nonatomic, assign) UIDatePickerMode datePickerMode;
@property (nonatomic, retain) UIColor *backgroundColor;

- (IBAction)dateChanged;

@end

