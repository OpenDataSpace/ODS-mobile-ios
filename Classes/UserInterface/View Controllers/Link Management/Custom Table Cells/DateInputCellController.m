//
//  DateInputCellController.m
//  FreshDocs
//
//  Created by bdt on 5/4/14.
//
//

#import "DateInputCellController.h"
#import "IFGenericTableViewController.h"

@implementation DateInputCellController
@synthesize datePickerMode;
@synthesize dateFormat;
@synthesize selectionStyle;
@synthesize indentationLevel;
@synthesize tableViewController;
@synthesize cellIndexPath;

//
// dealloc
//
// Releases instance memory.
//
- (void)dealloc
{
	label = nil;
	key = nil;
	model = nil;
	dateFormat = nil;
	tableViewController = nil;
	cellIndexPath = nil;
}

//
// init
//
// Init methods for the object.
//
- (id)initWithLabel:(NSString *)newLabel atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel
{
	self = [super init];
	if (self != nil)
	{
		label = newLabel;
		key = newKey;
		model = newModel;
		
		datePickerMode = UIDatePickerModeDate;
		dateFormat = [[NSDateFormatter alloc] init];
		[dateFormat setDateStyle:NSDateFormatterLongStyle];
		[dateFormat setTimeStyle:NSDateFormatterNoStyle];
		
		indentationLevel = 0;
		selectionStyle = UITableViewCellSelectionStyleBlue;
	}
	return self;
}

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"DateDataCell";
    DateInputTableViewCell *cell = (DateInputTableViewCell*)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[DateInputTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
        cell.delegate = self;
    }
    [cell setMinDate:[NSDate date]];
    cell.selectionStyle = selectionStyle;
	cell.indentationLevel = indentationLevel;
    
	cell.textLabel.text = label;
    
    return cell;
}

- (void) dateValueChanged:(NSDate*) date {
    [model setObject:date forKey:key];
}

@end
