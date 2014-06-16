//
//  DateInputTableViewCell.h
//  FreshDocs
//
//  Created by bdt on 5/4/14.
//
//

#import <UIKit/UIKit.h>

@protocol DateInputDelegate <NSObject>

@optional
- (void) dateValueChanged:(NSDate*) date;
@end

@interface DateInputTableViewCell : UITableViewCell <UIPopoverControllerDelegate> {
	UIPopoverController *popoverController;
	UIToolbar *inputAccessoryView;
}

@property (nonatomic, strong) NSDate *dateValue;
@property (nonatomic, assign) UIDatePickerMode datePickerMode;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) UIDatePicker *datePicker;

@property (nonatomic, assign) id <DateInputDelegate> delegate;

- (void)setMaxDate:(NSDate *)max;
- (void)setMinDate:(NSDate *)min;

@end
