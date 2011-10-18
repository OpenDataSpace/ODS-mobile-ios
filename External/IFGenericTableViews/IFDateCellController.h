//
//  IFDateCellController.h
//

#import <UIKit/UIKit.h>

#import "IFCellController.h"
#import "IFCellModel.h"
#import "IFDateViewController.h"

@interface IFDateCellController : NSObject <IFCellController>
{
	NSString *label;
	id<IFCellModel> model;
	NSString *key;
	UIDatePickerMode datePickerMode;
	NSDateFormatter *dateFormat;
	
	UIColor *backgroundColor;
	UIColor *viewBackgroundColor;
	UITableViewCellSelectionStyle selectionStyle;

	NSInteger indentationLevel;
	
	UITableViewController *tableViewController;
	NSIndexPath *cellIndexPath;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	// UIPopoverController *
	id popover;
#endif	
}

@property (nonatomic, assign) UIDatePickerMode datePickerMode;
@property (nonatomic, retain) NSDateFormatter *dateFormat;
@property (nonatomic, retain) UIColor *backgroundColor;
@property (nonatomic, retain) UIColor *viewBackgroundColor;
@property (nonatomic, assign) UITableViewCellSelectionStyle selectionStyle;
@property (nonatomic, assign) NSInteger indentationLevel;
@property (nonatomic, retain) UITableViewController *tableViewController;
@property (nonatomic, retain) NSIndexPath *cellIndexPath;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
@property (nonatomic, retain) id popover;
#endif

- (id)initWithLabel:(NSString *)newLabel atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel;

@end
