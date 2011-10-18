//
//  TextViewWithPlaceholder.h
//  Fresh Docs
//
//  Created by Gi Hyun Lee on 7/24/11.
//  Copyright 2011 Zia Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TextViewWithPlaceholder : UITextView {
	NSString *placeholder;
	UIColor *placeholderTextColor;
	
@private
	BOOL placeholderIsShowing;
}
@property (nonatomic, retain) NSString *placeholder;
@property (nonatomic, retain) UIColor *placeholderTextColor;

- (void)textChanged:(NSNotification *)notification;
@end
