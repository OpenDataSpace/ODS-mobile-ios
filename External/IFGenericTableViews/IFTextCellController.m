//
//  IFTextCellController.m
//  Thunderbird
//
//	Created by Craig Hockenberry on 1/29/09.
//	Copyright 2009 The Iconfactory. All rights reserved.
//

#import "IFTextCellController.h"

#import "TextTableCellView.h"

@implementation IFTextCellController

@synthesize backgroundColor;
@synthesize updateTarget, updateAction;
@synthesize keyboardType, autocapitalizationType, autocorrectionType, returnKeyType, secureTextEntry, indentationLevel;
@synthesize textField, cellControllerFirstResponderHost;

//
// dealloc
//
// Releases instance memory.
//
- (void)dealloc
{
	[label release];
	[placeholder release];
	[key release];
	[model release];
	[backgroundColor release];
	
	[super dealloc];
}

//
// init
//
// Init method for the object.
//
- (id)initWithLabel:(NSString *)newLabel andPlaceholder:(NSString *)newPlaceholder atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel
{
	self = [super init];
	if (self != nil)
	{
		label = [newLabel retain];
		placeholder = [newPlaceholder retain];
		key = [newKey retain];
		model = [newModel retain];

		backgroundColor = nil;
		keyboardType = UIKeyboardTypeASCIICapable;
		autocapitalizationType = UITextAutocapitalizationTypeNone;
		autocorrectionType = UITextAutocorrectionTypeNo;
		secureTextEntry = NO;
		indentationLevel = 0;
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
	static NSString *cellIdentifier = @"TextDataCell";
	
    TextTableCellView *cell = (TextTableCellView *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
		cell = [[[TextTableCellView alloc] initWithFrame:CGRectZero reuseIdentifier:cellIdentifier] autorelease];
    }

	if (nil != backgroundColor) [cell setBackgroundColor:backgroundColor];
	
	cell.textLabel.font = [UIFont boldSystemFontOfSize:17.0f];
	cell.textLabel.text = label;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.indentationLevel = indentationLevel;
		
	// add a text field to the cell
    // the width is calculated in each layoutSubviews call by the TextTableCellView we set 0 here
	CGRect frame = CGRectMake(0.0f, 0.0f, 0, 21.0f);
    UITextField *txtField = [[UITextField alloc] initWithFrame:frame];
	self.textField = txtField;
	[self.textField addTarget:self action:@selector(updateValue:) forControlEvents:UIControlEventEditingChanged];
	[self.textField setDelegate:self];
	NSString *value = [model objectForKey:key];
	[self.textField setText:value];
	[self.textField setFont:[UIFont systemFontOfSize:17.0f]];
	[self.textField setBorderStyle:UITextBorderStyleNone];
	[self.textField setPlaceholder:placeholder];
	[self.textField setReturnKeyType: returnKeyType];
	[self.textField setKeyboardType:keyboardType];
	[self.textField setAutocapitalizationType:autocapitalizationType];
	[self.textField setAutocorrectionType:autocorrectionType];
	[self.textField setBackgroundColor:[cell backgroundColor]];
	[self.textField setTextColor:[UIColor colorWithRed:0.20f green:0.31f blue:0.52f alpha:1.0f]];
	[self.textField setSecureTextEntry:secureTextEntry];

	cell.view = self.textField;
	[txtField release];
	
    return cell;
}

//
// tableView:didSelectRowAtIndexPath:
//
// Handle row selection
//
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (![self.textField isFirstResponder]) {
		[self.textField becomeFirstResponder];
	}
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)updateValue:(id)sender
{
	// update the model with the text change
	[model setObject:[sender text] forKey:key];
}


#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textFieldIn
{
	self.textField = textFieldIn;
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textFieldIn
{	
	self.textField = textFieldIn;
	if (updateTarget && [updateTarget respondsToSelector:updateAction])
	{
		// action is peformed after keyboard has had a chance to resign
		[updateTarget performSelector:updateAction withObject:textFieldIn];
	}

	return YES;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textFieldIn
{
	// hide the keyboard
	self.textField = textFieldIn;
	[self.textField resignFirstResponder];
	if (nil != cellControllerFirstResponderHost) {
		if (returnKeyType == UIReturnKeyNext) {
			[cellControllerFirstResponderHost advanceToNextResponderFromCellController: self];
		} else if (returnKeyType == UIReturnKeyDone) {
			[cellControllerFirstResponderHost lastResponderIsDone: self];
		}
	}
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSLog(@"textFieldDidEndEditing");
}

#pragma mark IFCellControllerFirstResponder
-(void)assignFirstResponderHost: (NSObject<IFCellControllerFirstResponderHost> *)hostIn
{
	[self setCellControllerFirstResponderHost: hostIn];
}

-(void)becomeFirstResponder
{
	@try {
		[self.textField becomeFirstResponder];
	}
	@catch (NSException *ex) {
		NSLog(@"unable to become first responder");
	}
}

-(void)resignFirstResponder
{
	@try {
		[self.textField resignFirstResponder];
	}
	@catch (NSException *ex) {
		NSLog(@"unabe to resign first responder");
	}
}

@end
