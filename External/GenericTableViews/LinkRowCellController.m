//
//  LinkRowCellController.m
//  PhoneNumbers
//
//  Created by Matt Gallagher on 27/12/08.
//  Copyright 2008 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "LinkRowCellController.h"

@implementation LinkRowCellController

//
// init
//
// Init method for the object.
//
- (id)initWithLabel:(NSString *)newLabel controllerClass:(Class)newControllerClass
{
	self = [super init];
	if (self != nil)
	{
		label = [newLabel retain];
		controllerClass = newControllerClass;
	}
	return self;
}

//
// dealloc
//
// Releases instance memory.
//
- (void)dealloc
{
	[label release];
	[super dealloc];
}

//
// tableView:didSelectRowAtIndexPath:
//
// Handle row selection
//
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewController *tableViewController = (UITableViewController *)tableView.dataSource;
	[tableViewController.navigationController
		pushViewController:[[[controllerClass alloc] init] autorelease]
		animated:YES];
	[tableView
		deselectRowAtIndexPath:indexPath
		animated:YES];
}

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"LinkDataCell";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
        cell =
			[[[UITableViewCell alloc]
				initWithFrame:CGRectZero
				reuseIdentifier:cellIdentifier]
			autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
	
    // Configure the cell
	cell.text = label;
	
    return cell;
}

@end
