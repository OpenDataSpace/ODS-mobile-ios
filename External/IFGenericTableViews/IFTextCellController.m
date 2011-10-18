//
//  IFTextCellController.m
//  Thunderbird
//
//	Created by Craig Hockenberry on 1/29/09.
//	Copyright 2009 The Iconfactory. All rights reserved.
//

#import "IFTextCellController.h"

#import	"IFControlTableViewCell.h"

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
	
    IFControlTableViewCell *cell = (IFControlTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
		cell = [[[IFControlTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellIdentifier] autorelease];
    }

	if (nil != backgroundColor) [cell setBackgroundColor:backgroundColor];
	
	cell.textLabel.font = [UIFont boldSystemFontOfSize:17.0f];
	cell.textLabel.text = label;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.indentationLevel = indentationLevel;
    
	// NOTE: The documentation states that the indentation width is 10 "points". It's more like 20
	// pixels and changing the property has no effect on the indentation. We'll use 20.0f here
	// and cross our fingers that this doesn't screw things up in the future.
	
	CGFloat viewWidth;
	if (! label || [label length] == 0)
	{
		// there is no label, so use the entire width of the cell
		viewWidth = 280.0f - (20.0f * indentationLevel);
	}
	else
	{
        
        CGRect labelRect = [[cell textLabel] textRectForBounds:[tableView frame] limitedToNumberOfLines:1];
        
		// use about half of the cell (this matches the metrics in the Settings app)
		CGFloat w = [tableView frame].size.width;
		if (w <	700.0f) {
			viewWidth = w - labelRect.size.width - 50.0f;
		} else {
			viewWidth = w - labelRect.size.width - 120.0f;
		}
	}
		
	// add a text field to the cell
	CGRect frame = CGRectMake(0.0f, 0.0f, viewWidth, 21.0f);
	self.textField = [[UITextField alloc] initWithFrame:frame];
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
	[self.textField release];
	
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
