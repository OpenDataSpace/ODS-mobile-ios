//
//  DateInputCellController.h
//  FreshDocs
//
//  Created by bdt on 5/4/14.
//
//

#import <UIKit/UIKit.h>

#import "IFCellController.h"
#import "IFCellModel.h"
#import "DateInputTableViewCell.h"


@interface DateInputCellController : NSObject <IFCellController, DateInputDelegate>
{
	NSString *label;
	id<IFCellModel> model;
	NSString *key;
	UIDatePickerMode datePickerMode;
	NSDateFormatter *dateFormat;
    
    UITableViewCellSelectionStyle selectionStyle;
    
	NSInteger indentationLevel;
	
	UITableViewController *tableViewController;
	NSIndexPath *cellIndexPath;
}

@property (nonatomic, assign) UIDatePickerMode datePickerMode;
@property (nonatomic, retain) NSDateFormatter *dateFormat;

@property (nonatomic, assign) UITableViewCellSelectionStyle selectionStyle;
@property (nonatomic, assign) NSInteger indentationLevel;
@property (nonatomic, retain) UITableViewController *tableViewController;
@property (nonatomic, retain) NSIndexPath *cellIndexPath;

- (id)initWithLabel:(NSString *)newLabel atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel;
@end
