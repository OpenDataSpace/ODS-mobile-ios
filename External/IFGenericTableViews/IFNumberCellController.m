//
//  IFNumberCellController.m
//  XpenserUtility
//
//  Created by Bindu Wavell on 12/22/09.
//  Copyright 2009 Zia Consulting, Inc.. All rights reserved.
//

#import "IFNumberCellController.h"
#import "RegexKitLite.h"


@implementation IFNumberCellController

- (void)dealloc {
	[self destroyButton];
    [super dealloc];
}

- (id)initWithLabel:(NSString *)newLabel andPlaceholder:(NSString *)newPlaceholder atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel
{
	id retv = [super initWithLabel:newLabel andPlaceholder:newPlaceholder atKey:newKey inModel:newModel];
	[self setKeyboardType: UIKeyboardTypeNumberPad];
	return retv;
}

- (BOOL)textField:(UITextField *)textFieldIn shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	self.textField = textFieldIn;
	NSString *fieldText = self.textField.text;
	NSString *numberRegex = @"([0-9]+).?([0-9]*)";
	NSString *currentNumberDec = [fieldText stringByMatching:numberRegex capture:1];
	if (nil == currentNumberDec) currentNumberDec = @"";
	NSString *currentNumberFrac = [fieldText stringByMatching:numberRegex capture:2];
	if (nil == currentNumberFrac) currentNumberFrac = @"";
	NSString *newNumber = [NSString stringWithFormat: @"%@%@%@", currentNumberDec, currentNumberFrac, string];
	if (0 == [string length]) {
		int len = [newNumber length];
		newNumber = [newNumber substringToIndex: (len-1)];
	}
	double newDouble = [newNumber doubleValue];
	newDouble = newDouble / 100.0f;
	NSString *newString = [NSString stringWithFormat: @"%0.2f", newDouble];
	self.textField.text = newString;
	return NO;
}

- (UIView *)getKeyboardView
{
    // locate keyboard view
    UIWindow* tempWindow;
    UIView* keyboard;
	// Check each window in our application
	for(int c = 0; c < [[[UIApplication sharedApplication] windows] count]; c++)
	{
		tempWindow = [[[UIApplication sharedApplication] windows] objectAtIndex:c];
		for(int i=0; i<[tempWindow.subviews count]; i++) {
			keyboard = [tempWindow.subviews objectAtIndex:i];
			// keyboard view found; add the custom button to it
			if([[keyboard description] hasPrefix:@"<UIKeyboard"] == YES)
				return keyboard;
		}
	}
	return nil;
}

- (void)destroyButton
{
	if (nil != returnKeyButton) {
		[returnKeyButton removeTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
		[returnKeyButton removeFromSuperview];
		returnKeyButton = nil;
	}
}

- (UIButton *)makeButton
{
	if (returnKeyType == UIReturnKeyDone || returnKeyType == UIReturnKeyNext) {
		[self destroyButton];
		returnKeyButton = [UIButton buttonWithType:UIButtonTypeCustom];
		returnKeyButton.frame = CGRectMake(0, 163, 106, 53);
		returnKeyButton.adjustsImageWhenHighlighted = NO;
		if (returnKeyType == UIReturnKeyDone) {
			[returnKeyButton setImage:[UIImage imageNamed:@"DoneUp3.png"] forState:UIControlStateNormal];
			[returnKeyButton setImage:[UIImage imageNamed:@"DoneDown3.png"] forState:UIControlStateHighlighted];
		} else {
			[returnKeyButton setImage:[UIImage imageNamed:@"NextUp3.png"] forState:UIControlStateNormal];
			[returnKeyButton setImage:[UIImage imageNamed:@"NextDown3.png"] forState:UIControlStateHighlighted];
		}

		[returnKeyButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];

		return returnKeyButton;
	}
	return nil;
}

- (void)injectButton
{
	UIView* keyboard = [self getKeyboardView];
	if (nil != keyboard) {
		UIButton *button = [self makeButton];
		if (nil != button) {
			[keyboard addSubview:button];
		}
	}
}

- (void)buttonPressed:(id)sender
{
    NSLog(@"Input: %@", self.textField.text);
    [self textFieldShouldReturn: self.textField];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textFieldIn
{
	BOOL retv = [super textFieldShouldBeginEditing: textFieldIn];
	
	// need to give keyboard a little time to display before we attempt to 
	// inject the appropriate additional button.
	if (retv) {
		[self performSelector:@selector(injectButton) withObject:nil afterDelay:0.1];
	}
	return retv;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textFieldIn
{
	BOOL retv = [super textFieldShouldEndEditing:textFieldIn];
	if (retv) {
		[self destroyButton];
	}
	return retv;
}

@end
