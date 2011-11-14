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
//  MetaDataViewController.m
//

#import "MetaDataViewController.h"
#import "MetaDataTableViewCell.h"
#import "PropertyInfo.h"
#import "EditMetaDataViewController.h"
#import "Theme.h"

@implementation MetaDataViewController

@synthesize metadata;
@synthesize propertyInfo;
@synthesize documentURL;
@synthesize updateAction;
@synthesize updateTarget;

- (void)dealloc {
	[metadata release];
	[propertyInfo release];
	[documentURL release];
    [super dealloc];
}


#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editButtonPressed)];
    self.navigationItem.rightBarButtonItem = button;
	[button release];
	
	[Theme setThemeForUITableViewController:self];
}

- (void)editButtonPressed {
	//EditMetaDataViewController *e = [[EditMetaDataViewController alloc] initWithNibName:nil bundle:nil];
	EditMetaDataViewController *e = [[EditMetaDataViewController alloc] initWithStyle:UITableViewStyleGrouped];
	e.metadata = self.metadata;
	e.propertyInfo = self.propertyInfo;
	e.documentURL = self.documentURL;
	
	[e setUpdateAction:@selector(metaDataChanged:)];
	[e setUpdateTarget:self];
	
	[self.navigationController pushViewController:e animated:YES];
	[e release];
}
	 
- (void)metaDataChanged:(NSMutableDictionary *)updatedMetadata
{
	[self setMetadata:updatedMetadata];
	[[self tableView] reloadData];
	
	if (updateAction && updateTarget) {
		if ([updateTarget respondsToSelector:updateAction]) {
			[updateTarget performSelector:updateAction];
		}
	}
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Override to allow orientations other than the default portrait orientation.
    return YES;
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [metadata count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	MetaDataTableViewCell *cell = (MetaDataTableViewCell *) [tableView dequeueReusableCellWithIdentifier:MetaDataCellIdentifier];
    if (cell == nil) {
		NSArray *nibItems = [[NSBundle mainBundle] loadNibNamed:@"MetaDataTableViewCell" owner:self options:nil];
		cell = [nibItems objectAtIndex:0];
		NSAssert(nibItems, @"Failed to load object from NIB");
    }
	
	NSString *key = [[[metadata allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] objectAtIndex:indexPath.row];
	NSString *value = [metadata valueForKey:key];
	
	PropertyInfo *i = [self.propertyInfo objectForKey:key];
	
	if ([i.propertyType isEqualToString:@"datetime"]) {
		value = formatDateTime(value);
	}
	
	NSString *displayKey = i.displayName ? i.displayName : key;
	displayKey = [NSString stringWithFormat:@"%@:", displayKey];

	cell.name.text = displayKey;
	cell.value.text = value;
	
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	/*
	 <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
	 [self.navigationController pushViewController:detailViewController animated:YES];
	 [detailViewController release];
	 */
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


@end

