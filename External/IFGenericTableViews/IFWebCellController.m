/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Alfresco Mobile App.
 *
 * The Initial Developer of the Original Code is Zia Consulting, Inc.
 * Portions created by the Initial Developer are Copyright (C) 2011
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  IFWebCellController.m
//

#import "IFWebCellController.h"

#import "IFGenericTableViewController.h"
#import "IFControlTableViewCell.h"
#import "IFNamedImage.h"

@implementation IFWebCellController

@synthesize url;
@synthesize request;
@synthesize backgroundColor;
@synthesize viewBackgroundColor;
@synthesize selectionStyle;
@synthesize indentationLevel;
@synthesize tableViewController;

//
// dealloc
//
// Releases instance memory.
//
- (void)dealloc
{
	[label release];
	[url release];
	[request release];
	[backgroundColor release];
	[viewBackgroundColor release];
	[tableViewController release];
	
	[super dealloc];
}

//
// init
//
// Init methods for the object.
//
- (id)initWithLabel:(NSString *)newLabel andURL:(NSURL *)newURL
{
	self = [super init];
	if (self != nil)
	{
		label = [newLabel retain];
		url = [newURL retain];
		request = [[NSURLRequest alloc] initWithURL:url];
		
		backgroundColor = nil;
		viewBackgroundColor = nil;
		indentationLevel = 0;
		selectionStyle = UITableViewCellSelectionStyleBlue;
	}
	return self;
}

- (id)initWithLabel:(NSString *)newLabel andURLRequest:(NSURLRequest *)newURLRequest
{
	self = [super init];
	if (self != nil)
	{
		label = [newLabel retain];
		request = [newURLRequest retain];
		url = [[request URL] retain];
		
		backgroundColor = nil;
		viewBackgroundColor = nil;
		indentationLevel = 0;
		selectionStyle = UITableViewCellSelectionStyleBlue;
	}
	return self;
	
}

//
// tableView:didSelectRowAtIndexPath:
//
// Handle row selection
//
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.tableViewController = (UITableViewController *)tableView.dataSource;
	
	IFWebViewController *controller = [[IFWebViewController alloc] init];
	controller.title = label;
	controller.request = request;
	controller.backgroundColor = viewBackgroundColor;
	
	((IFGenericTableViewController *)tableViewController).controllerForReturnHandler = self;
	
	[self.tableViewController.navigationController pushViewController:controller animated:YES];
	
	[controller release];
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"WebDataCell";
	
    IFControlTableViewCell *cell = (IFControlTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
		cell = [[[IFControlTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }
	
	if (nil != backgroundColor) [cell setBackgroundColor:backgroundColor];
	
	cell.textLabel.font = [UIFont boldSystemFontOfSize:17.0f];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.selectionStyle = selectionStyle;
	cell.indentationLevel = indentationLevel;
	
	cell.textLabel.text = label;
	
    return cell;
}

- (void)setUrl:(NSURL *)newURL
{
	[url release];
	url = [newURL retain];
	[request release];
	request = [[NSURLRequest alloc] initWithURL:url];
}

- (void)setRequest:(NSURLRequest *)newURLRequest
{
	[request release];
	request = [newURLRequest retain];
	[url release];
	url = [[request URL] retain];
}

@end
