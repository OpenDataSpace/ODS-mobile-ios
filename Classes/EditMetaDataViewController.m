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
 * Portions created by the Initial Developer are Copyright (C) 2011-2012
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  EditMetaDataViewController.m
//

#import "EditMetaDataViewController.h"
#import "MetaDataTableViewCell.h"
#import "EditMetaDataTableViewCell.h"
#import "PropertyInfo.h"
#import "Utility.h"
#import "MetaDataDatePicker.h"
#import "MetaDataViewController.h"
#import "Theme.h"

@implementation EditMetaDataViewController

@synthesize metadata;
@synthesize originalMetadata;
@synthesize propertyInfo;
@synthesize textFieldBeingEdited;
@synthesize documentURL;
@synthesize updater;
@synthesize editableProperties;
@synthesize updateAction;
@synthesize updateTarget;

- (void)dealloc {
	[metadata release];
	[originalMetadata release];
	[propertyInfo release];
	[textFieldBeingEdited release];
	[documentURL release];
	[updater release];
	[editableProperties release];
	
    [super dealloc];
}

- (void)cancelButtonPressed {
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)saveButtonPressed {
	if (self.textFieldBeingEdited != nil) {
		[self textFieldDidEndEditing:self.textFieldBeingEdited];
	}

	CMISUpdateProperties *u = [[CMISUpdateProperties alloc] initWithURL:self.documentURL propertyInfo:self.propertyInfo 
													   originalMetadata:self.originalMetadata editedMetadata:self.metadata 
                                                            accountUUID:nil];
    //
    // FIXME: Account UUID not set!!!
    //
    
    [u setDelegate:self];
    [self setUpdater:u];
	[u startAsynchronous];
	[u release];
}

#pragma mark -
#pragma mark ASIHTTPRequestDelegate

- (void)requestFinished:(ASIHTTPRequest *)request {
	// FIXME: Parse the AtomPubXML that is returned
	
	if (updateAction && updateTarget) {
		if ([updateTarget respondsToSelector:updateAction]) {
			[updateTarget performSelector:updateAction withObject:metadata];
		}
	}
	
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)requestFailed:(ASIHTTPRequest *)request {
	
}


#pragma mark -
#pragma mark Initialization

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if ((self = [super initWithStyle:style])) {
    }
    return self;
}
*/


#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

	UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed)];
	UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed)];
    styleButtonAsDefaultAction(saveButton);

	self.navigationItem.leftBarButtonItem = cancelButton;
	self.navigationItem.rightBarButtonItem = saveButton;
	
	[cancelButton release];
	[saveButton release];
	
	self.originalMetadata = [NSMutableDictionary dictionaryWithDictionary:self.metadata];
	
	self.editableProperties = [[[NSMutableArray alloc] init] autorelease];
	
	for (NSString *key in metadata) {
		PropertyInfo *pinfo = [self.propertyInfo objectForKey:key];
		if ([pinfo.updatability isEqualToString:@"readwrite"]) {
			[self.editableProperties addObject:key];
		}
	}
	
	[Theme setThemeForUITableViewController:self];
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
    return [self.editableProperties count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	NSString *key = [self.editableProperties objectAtIndex:indexPath.row];
	NSString *value = [metadata valueForKey:key];
	PropertyInfo *i = [self.propertyInfo objectForKey:key];
	
	if ([i.propertyType isEqualToString:@"datetime"]) {
		value = formatDateTime(value);
	}
	
	NSString *displayKey = i.displayName ? i.displayName : key;
	displayKey = [NSString stringWithFormat:@"%@:", displayKey];

	EditMetaDataTableViewCell *cell = (EditMetaDataTableViewCell *) [tableView dequeueReusableCellWithIdentifier:EditMetaDataCellIdentifier];
	if (cell == nil) {
		NSArray *nibItems = [[NSBundle mainBundle] loadNibNamed:@"EditMetaDataTableViewCell-iPad" owner:self options:nil];
		cell = [nibItems objectAtIndex:0];
		NSAssert(nibItems, @"Failed to load object from NIB");
	}
	
	cell.name.text = displayKey;
	cell.value.text = value;
	cell.value.tag = indexPath.row;
	cell.value.returnKeyType = UIReturnKeyDone;

	[cell.value setDelegate:self];
	[cell.value addTarget:self action:@selector(hideKeyboard:) forControlEvents:UIControlEventEditingDidEndOnExit];
	
	return cell;
}

- (IBAction)hideKeyboard:(id)sender {
	[sender resignFirstResponder];
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
	if (self.textFieldBeingEdited != nil) {
		[self.textFieldBeingEdited resignFirstResponder];
	}
	NSString *key = [self.editableProperties objectAtIndex:indexPath.row];
	PropertyInfo *i = [self.propertyInfo objectForKey:key];
	if ([i.propertyType isEqualToString:@"datetime"]) {
		// TODO: edit dates
	}
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

#pragma mark -
#pragma mark Table view delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	self.textFieldBeingEdited = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	int row = textField.tag;
	
	NSString *key = [self.editableProperties objectAtIndex:row];
	[self.metadata setValue:textField.text forKey:key];
	
	self.textFieldBeingEdited = nil;
}

@end

