//
//  IFLinkCellController.m
//  Thunderbird
//
//	Created by Craig Hockenberry on 1/29/09.
//	Copyright 2009 The Iconfactory. All rights reserved.
//
//  Based on work created by Matt Gallagher on 27/12/08.
//  Copyright 2008 Matt Gallagher. All rights reserved.
//	For more information: http://cocoawithlove.com/2008/12/heterogeneous-cells-in.html
//

#import "IFMultilineCellController.h"

#import "IFGenericTableViewController.h"
#import "IFTemporaryModel+CustomDescription.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
#define IS_IPAD ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
#endif

@implementation IFMultilineCellController

@synthesize title;
@synthesize subtitle;
@synthesize defaultSubtitle;
@synthesize controllerClass;
@synthesize key;
@synthesize backgroundColor;
@synthesize tableController;
@synthesize selectionTarget;
@synthesize selectionAction;
@synthesize cellIndexPath;
@synthesize isRequired;
@synthesize titleTextColor;
@synthesize subtitleTextColor;
@synthesize titleFont;
@synthesize subTitleFont;

#define CONST_Cell_height 44.0f
#define CONST_textLabelFontSize 17
#define CONST_detailLabelFontSize 15

//
// dealloc
//
// Releases instance memory.
//
- (void)dealloc
{
	
	self.title = nil;
	self.subtitle = nil;
	self.defaultSubtitle = nil;
	self.key = nil;
	self.backgroundColor = nil;
	self.tableController = nil;
	self.cellIndexPath = nil;
	self.titleTextColor = nil;
	self.subtitleTextColor = nil;
	self.titleFont = nil;
	self.subTitleFont = nil;
	
	[model release];
	
	[super dealloc];
}

//
// init
//
// Init method for the object.
//
- (id)initWithTitle:(NSString *)newTitle andSubtitle:(NSString *)newSubtitle inModel:(id<IFCellModel>)newModel
{
		self = [super init];
	if (self != nil)
	{
		title = [newTitle retain];
		subtitle = [newSubtitle retain];
		defaultSubtitle = [newSubtitle retain];
		controllerClass = nil;
		model = [newModel retain];
		
		backgroundColor = nil;
		isRequired = NO;
	}
	return self;
}

- (UIFont *) titleFont {
	
	if (titleFont == nil) self.titleFont = [UIFont boldSystemFontOfSize:CONST_textLabelFontSize];
	return titleFont;
	
}

- (UIFont *) subTitleFont {
	
	if (subTitleFont == nil) self.subTitleFont = [UIFont systemFontOfSize:CONST_detailLabelFontSize];
	return subTitleFont;
	
}

- (UIColor *) subtitleTextColor {

	if(subtitleTextColor == nil) self.subtitleTextColor = [UIColor blackColor];
	return subtitleTextColor;

}

- (UIColor *) titleTextColor {
	
	if(titleTextColor == nil) self.titleTextColor = [UIColor blackColor];
	return titleTextColor;
	
}

- (UIColor *) backgroundColor {
	
	if(backgroundColor == nil) self.backgroundColor = [UIColor whiteColor];
	return backgroundColor;
	
}


//
// tableView:heightForRowAtIndexPath
//
// Returns the height for a given indexPath
//
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return [self heightForSelfSavingHieght:YES];
}

- (CGFloat)heightForSelfSavingHieght:(BOOL)saving
{
	CGFloat maxWidth = [UIScreen mainScreen].bounds.size.width;
	CGFloat maxHeight = 4000;
	
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	if (IS_IPAD) {
		maxWidth -= 120.0f;
	} else
#endif
	{
		maxWidth -= 60.0f;
	}
	
	CGSize titleSize    = {0.0f, 0.0f};
	CGSize subtitleSize = {0.0f, 0.0f};
	
	if (title && ![title isEqualToString:@""])
		titleSize = [title sizeWithFont:[self titleFont] 
					  constrainedToSize:CGSizeMake(maxWidth, maxHeight) 
						  lineBreakMode:UILineBreakModeWordWrap];
	if (subtitle && ![subtitle isEqualToString:@""])
		subtitleSize = [subtitle sizeWithFont:[self subTitleFont] 
							constrainedToSize:CGSizeMake(maxWidth, maxHeight) 
								lineBreakMode:UILineBreakModeWordWrap];
	
	int height = 20 + titleSize.height + subtitleSize.height;
	CGFloat myCellHeight = (height < CONST_Cell_height ? CONST_Cell_height : height);
	if (saving) {
		cellHeight = myCellHeight;
	}
	return myCellHeight;
}

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.tableController = (UITableViewController *)tableView.dataSource;
	self.cellIndexPath = indexPath;
	
	static NSString *cellIdentifier = @"MultilineDataCell";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier] autorelease];
		cell.textLabel.numberOfLines = 0;
		cell.textLabel.font = [self titleFont];
		
		cell.detailTextLabel.numberOfLines = 0;
		cell.detailTextLabel.font = [self subTitleFont];
	}
	
	if (nil != controllerClass || nil != selectionTarget) {
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	} else {
        cell.accessoryType = UITableViewCellAccessoryNone;   
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
	
	cell.backgroundColor = self.backgroundColor;

	IFTemporaryModel *tModel = (IFTemporaryModel *)model;
	if ([tModel respondsToSelector:@selector(isCustomDescriptionAvailable)] && [tModel performSelector:@selector(isCustomDescriptionAvailable)]) {
		[self setSubtitle:[(IFTemporaryModel *)model description]];
	} else if (key && [tModel objectForKey:key]) {
		[self setSubtitle:[tModel objectForKey:key]];
	} else {
		[self setSubtitle:defaultSubtitle];
	}

	
	cell.textLabel.text = title;
	cell.textLabel.textColor = self.titleTextColor;
	cell.detailTextLabel.text = subtitle;
	cell.detailTextLabel.textColor = self.subtitleTextColor;
	
	CGFloat testHeight = [self heightForSelfSavingHieght:NO];
	
	if (cellHeight != testHeight) {
		[self performSelector:@selector(reloadCell) withObject:nil afterDelay:0.1f];
	}

    return cell;
}
	 
- (void)reloadCell
{
	[[tableController tableView] reloadRowsAtIndexPaths:[NSArray arrayWithObject:cellIndexPath] 
									   withRowAnimation:UITableViewRowAnimationFade];
}

//
// tableView:didSelectRowAtIndexPath:
//
// Handle row selection
//
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.tableController = (UITableViewController *)tableView.dataSource;
	
	if (nil != controllerClass) {
		UITableViewController *tableViewController = (UITableViewController *)tableView.dataSource;
		IFGenericTableViewController *linkTableViewController = (IFGenericTableViewController *)[[[controllerClass alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
		[linkTableViewController setModel:model];
		linkTableViewController.navigationItem.title = title;

		if (selectionTarget && [selectionTarget respondsToSelector:selectionAction])
		{
			[selectionTarget performSelector:selectionAction withObject:self];
		}
		
		[tableViewController.navigationController pushViewController:linkTableViewController animated:YES];
	} else {
		if (selectionTarget && [selectionTarget respondsToSelector:selectionAction])
		{
			[selectionTarget performSelector:selectionAction withObject:self];
		}		
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

}

- (id<IFCellModel>)model
{
	return model;
}

@end
