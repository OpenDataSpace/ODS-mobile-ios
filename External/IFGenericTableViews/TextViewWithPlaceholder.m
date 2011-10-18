//
//  TextViewWithPlaceholder.h
//  Fresh Docs
//
//  Created by Gi Hyun Lee on 7/24/11.
//  Copyright 2011 Zia Consulting. All rights reserved.
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
