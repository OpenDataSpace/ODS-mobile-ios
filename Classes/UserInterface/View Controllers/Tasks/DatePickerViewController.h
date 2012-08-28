//
//  DatePickerViewController.h
//  FreshDocs
//
//  Created by Tijs Rademakers on 24/08/2012.
//  Copyright (c) 2012 U001b. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DatePickerDelegate <NSObject>

@required
-(void) datePicked:(NSDate *)date;

@end

@interface DatePickerViewController : UIViewController

@property (nonatomic, assign) id<DatePickerDelegate> delegate;

- (id)initWithNSDate:(NSDate *)date;

@end
