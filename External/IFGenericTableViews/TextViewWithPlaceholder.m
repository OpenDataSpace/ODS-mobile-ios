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
//  TextViewWithPlaceholder.h
//

#import "TextViewWithPlaceholder.h"


@implementation TextViewWithPlaceholder
@synthesize placeholder;
@synthesize placeholderTextColor;


-(void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:self];
	
	[placeholder release];
	[placeholderTextColor release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark UIView Overrides

-(id) initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextViewTextDidChangeNotification object:self];

		placeholderIsShowing = NO;
		[self setPlaceholder:[NSString string]];
		[self setPlaceholderTextColor:[UIColor lightGrayColor]]; 
		[self setFont:[UIFont systemFontOfSize:17.0f]];
	}
	return self;
}

-(void) drawRect:(CGRect)rect
{
	[super drawRect:rect];
	
	if (([placeholder length] > 0) && (NO == [self hasText])) {
		[placeholderTextColor set];
		[placeholder drawInRect:CGRectMake(8.0, 8.0, self.frame.size.width - 16.0, self.frame.size.height - 16.0) withFont:self.font];
		placeholderIsShowing = YES;
	}
	else {
		placeholderIsShowing = NO;
	}
}

#pragma mark -
#pragma mark UITextView Delegate methods
- (void)textChanged:(NSNotification *)notification
{
	if (([self hasText] && placeholderIsShowing) || (![self hasText] && !placeholderIsShowing)) {
		[self setNeedsDisplay];
	}
}

@end
