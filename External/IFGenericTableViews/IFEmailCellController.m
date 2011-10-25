//
//  ***** BEGIN LICENSE BLOCK *****
//  Version: MPL 1.1
//
//  The contents of this file are subject to the Mozilla Public License Version
//  1.1 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS" basis,
//  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
//  for the specific language governing rights and limitations under the
//  License.
//
//  The Original Code is the Alfresco Mobile App.
//  The Initial Developer of the Original Code is Zia Consulting, Inc.
//  Portions created by the Initial Developer are Copyright (C) 2011
//  the Initial Developer. All Rights Reserved.
//
//
//  ***** END LICENSE BLOCK *****
//
//
//  IFEmailCellController.m
//


#import "IFEmailCellController.h"

#import "IFGenericTableViewController.h"
#import "IFControlTableViewCell.h"
#import "IFNamedImage.h"
#import "UIImageUtils.h"

@implementation IFEmailCellController

@synthesize subject, toRecipients;
@synthesize backgroundColor;
@synthesize selectionStyle;
@synthesize updateTarget, updateAction;
@synthesize indentationLevel;
@synthesize cellControllerFirstResponderHost, tableController, cellIndexPath;

//
// dealloc
//
// Releases instance memory.
//
- (void)dealloc
{
	[label release];
	
	[subject release];
	[toRecipients release];
	
	[backgroundColor release];
	
	[tableController release];
	[cellIndexPath release];
		
	[super dealloc];
}

//
// init
//
// Init method for the object.
//
- (id)initWithLabel:(NSString *)newLabel
{
	self = [super init];
	if (self != nil)
	{
		label = [newLabel retain];
		
		subject = nil;
		toRecipients = nil;
		
		backgroundColor = nil;
		selectionStyle = UITableViewCellSelectionStyleBlue;
		indentationLevel = 0;
		
		autoAdvance = NO;
	}
	return self;
}

- (void)showEmailViewForTableViewController:(UITableViewController *)tableViewController {
	MFMailComposeViewController *mail;
	@try {
		mail = [[MFMailComposeViewController alloc] init];
		mail.mailComposeDelegate = self;
		
		if (nil != subject) {
			[mail setSubject:subject];
		}
		if (nil != toRecipients) {
			[mail setToRecipients:toRecipients];
		}
		
		if (autoAdvance) {
			((IFGenericTableViewController *)tableViewController).controllerForReturnHandler = self;
			autoAdvance = NO;
		}
		
		// following is a nasty hack so that if an ipad is rotated while the mail compose
		// window is displayed, this controller doesn't get released (because we rebuild 
		// the current table view on rotate and apparently on the ipad the table view is 
		// active even while the email window is displayed.
		[self retain];
		[tableViewController.navigationController presentModalViewController:mail animated:YES];			
	}
	@catch (NSException * e) {
		NSLog(@"Exception setting up MFMailComposeViewController: %@", [e description]);
	}
	@finally {
		[mail release];
	}
}

//
// tableView:didSelectRowAtIndexPath:
//
// Handle row selection
//
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewController *tableViewController = (UITableViewController *)tableView.dataSource;
	
	if ([MFMailComposeViewController canSendMail]) { 
		[tableView deselectRowAtIndexPath:indexPath animated:NO];
		[self performSelector:@selector(showEmailViewForTableViewController:) withObject:tableViewController afterDelay:0.1];
	} else {
		NSString *title = NSLocalizedString(@"Email Error",@"Title for alert about not being able to send email");
		NSString *msg = NSLocalizedString(@"Device does not support sending email",@"Message about not being able to send email");
		NSString *button = NSLocalizedString(@"OK",@"Button for alert that tells user they can't send email");
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
														message:msg delegate:nil
											  cancelButtonTitle:button otherButtonTitles:nil]; 
		[alert show]; 
		[alert release];
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
	}	
}

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.cellIndexPath = indexPath;
	self.tableController = (UITableViewController *)tableView.dataSource;
	
	static NSString *cellIdentifier = @"EmailDataCell";
	
    IFControlTableViewCell *cell = (IFControlTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
		cell = [[[IFControlTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellIdentifier] autorelease];
    }
	
	if (nil != backgroundColor) [cell setBackgroundColor:backgroundColor];
	
	cell.textLabel.font = [UIFont boldSystemFontOfSize:17.0f];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.indentationLevel = indentationLevel;
	cell.textLabel.text = label;
	cell.selectionStyle = selectionStyle;
	
    return cell;
}

#pragma mark IFCellControllerFirstResponder
-(void)assignFirstResponderHost: (NSObject<IFCellControllerFirstResponderHost> *)hostIn
{
	[self setCellControllerFirstResponderHost: hostIn];
}

-(void)becomeFirstResponder
{
	@try {
		autoAdvance = YES;
		[self tableView:(UITableView *)tableController.view didSelectRowAtIndexPath: self.cellIndexPath];
	}
	@catch (NSException *ex) {
		NSLog(@"unable to become first responder");
	}
}

-(void)resignFirstResponder
{
	NSLog(@"resign first responder is noop for email cells");
}

#pragma mark MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	[controller dismissModalViewControllerAnimated:YES];
	
	NSString *msg = nil;	
	switch (result) {
		case MFMailComposeResultCancelled:
			// user cancelled so nothing to do
			break;
		case MFMailComposeResultSaved:
			msg = NSLocalizedString(@"Your message has been saved and will be sent at a later date", @"Message when email is saved prior to being sent");
			break;
		case MFMailComposeResultSent:
			// message sent don't bother doing anything
			break;
		case MFMailComposeResultFailed:
			msg = NSLocalizedString(@"Unable to send your email: %@", @"Prefix for message about email sending failure, actual error message will passed into first string parameter");
			msg = [NSString stringWithFormat:msg, [error localizedDescription]];
			break;
		default:
			msg = NSLocalizedString(@"An unknown error occured sending your email, it is quite possible your email was not sent", @"Message displayed if the mail framework responds with an undocumented response");
			break;
	}
	
	if (nil != msg) {
		NSString *title = NSLocalizedString(@"Email",@"Title for alert about email result");
		NSString *button = NSLocalizedString(@"OK", @"Button for alert about email result");
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:button otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
	
	// following is part of the nasty hack that allows the backing table view conroller
	// to be rebuilt while the mail view is being displayed. We retain in 
	// showEmailViewForTableViewController: above...
	[self release];
}

#pragma mark UINavigationControllerDelegate
- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
}

@end

