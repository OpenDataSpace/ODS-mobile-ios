//
//  TextViewCellController.m
//  FreshDocs
//
//  Created by bdt on 5/6/14.
//
//

#import "TextViewCellController.h"

#import "TextTableCellView.h"

@implementation TextViewCellController
@synthesize backgroundColor;
@synthesize textViewColor;
@synthesize textViewTextColor;
@synthesize updateTarget, updateAction, editChangedAction;
@synthesize keyboardType, autocapitalizationType, autocorrectionType, returnKeyType, secureTextEntry, indentationLevel;
@synthesize textView, cellControllerFirstResponderHost;

//
// dealloc
//
// Releases instance memory.
//
- (void)dealloc
{
    label = nil;
	placeholder = nil;
	key = nil;
	model = nil;
	backgroundColor = nil;
    textViewColor = nil;
    textViewTextColor = nil;
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
		label = newLabel;
		placeholder = newPlaceholder;
		key = newKey;
		model = newModel;
        
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
        cell = [[TextTableCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    if (nil != backgroundColor) [cell setBackgroundColor:backgroundColor];
    
    cell.textLabel.font = [UIFont boldSystemFontOfSize:17.0f];
	cell.textLabel.text = label;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.indentationLevel = indentationLevel;
    
    // add a text field to the cell
    // the width is calculated in each layoutSubviews call by the TextTableCellView we set 0 here
	CGRect frame = CGRectMake(0.0f, 0.0f, 0, 80.0f);
    UITextView *txtView = [[UITextView alloc] initWithFrame:frame];
    [self setTextView:txtView];
	//[self.textView addTarget:self action:@selector(updateValue:) forControlEvents:UIControlEventEditingChanged];
	[self.textView setDelegate:self];
	NSString *value = [model objectForKey:key];
	[self.textView setText:value];
	[self.textView setFont:[UIFont systemFontOfSize:17.0f]];
	[self.textView setReturnKeyType: returnKeyType];
	[self.textView setKeyboardType:keyboardType];
	[self.textView setAutocapitalizationType:autocapitalizationType];
	[self.textView setAutocorrectionType:autocorrectionType];
    
    if(textViewColor)
        [self.textView setBackgroundColor:textViewColor];
    else
        [self.textView setBackgroundColor:[cell backgroundColor]];
    
    if(textViewTextColor)
        [self.textView setTextColor:textViewTextColor];
    else
        [self.textView setTextColor:[UIColor colorWithRed:0.20f green:0.31f blue:0.52f alpha:1.0f]];
	[self.textView setSecureTextEntry:secureTextEntry];
    //[self.textView setTextAlignment:UITextAlignmentRight];
    
    [cell setView:[self textView]];
	
    return cell;
}

- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80.0f;
}
//
// tableView:didSelectRowAtIndexPath:
//
// Handle row selection
//
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (![self.textView isFirstResponder]) {
		[self.textView becomeFirstResponder];
	}
	//[tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.textView isFirstResponder]) {
		[self.textView resignFirstResponder];
	}
}
#pragma mark UITextViewDelegate

- (BOOL) textViewShouldBeginEditing:(UITextView *)textViewIn {
    self.textView = textViewIn;
    return YES;
}

/*- (BOOL) textViewShouldEndEditing:(UITextView *)textViewIn {
    self.textView = textViewIn;
	if (updateTarget && [updateTarget respondsToSelector:updateAction])
	{
		// action is peformed after keyboard has had a chance to resign
		[updateTarget performSelector:updateAction withObject:textViewIn];
	}
    
	return YES;
}*/

- (void)textViewDidChange:(UITextView *)textViewIn {
    self.textView = textViewIn;
    [model setObject:[textViewIn text] forKey:key];
	if (updateTarget && [updateTarget respondsToSelector:editChangedAction])
	{
		// action is peformed after keyboard has had a chance to resign
		[updateTarget performSelector:editChangedAction withObject:textViewIn];
	}
}

@end
