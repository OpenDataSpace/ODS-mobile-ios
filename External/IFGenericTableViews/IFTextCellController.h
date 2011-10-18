//
//  IFTextCellController.h
//  Thunderbird
//
//	Created by Craig Hockenberry on 1/29/09.
//	Copyright 2009 The Iconfactory. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IFCellFirstResponder.h"
#import "IFCellController.h"
#import "IFCellModel.h"

@interface IFTextCellController : NSObject <IFCellController, IFCellControllerFirstResponder, UITextFieldDelegate>
{
	NSString *label;
	NSString *placeholder;
	id<IFCellModel> model;
	NSString *key;
	
	UIColor *backgroundColor;
	
	SEL updateAction;
	id updateTarget;

	UIKeyboardType keyboardType;
	UITextAutocapitalizationType autocapitalizationType;
	UITextAutocorrectionType autocorrectionType;
	UIReturnKeyType returnKeyType;
	BOOL secureTextEntry;
	NSInteger indentationLevel;

	UITextField *textField;
	id<IFCellControllerFirstResponderHost>cellControllerFirstResponderHost;
}

@property (nonatomic, retain) UIColor *backgroundColor;

@property (nonatomic, assign) SEL updateAction;
@property (nonatomic, assign) id updateTarget;

@property (nonatomic, assign) UIKeyboardType keyboardType;
@property (nonatomic, assign) UITextAutocapitalizationType autocapitalizationType;
@property (nonatomic, assign) UITextAutocorrectionType autocorrectionType;
@property (nonatomic, assign) UIReturnKeyType returnKeyType;
@property (nonatomic, assign) BOOL secureTextEntry;
@property (nonatomic, assign) NSInteger indentationLevel;

@property (nonatomic, assign) UITextField *textField;
@property (nonatomic, assign) id<IFCellControllerFirstResponderHost>cellControllerFirstResponderHost;

- (id)initWithLabel:(NSString *)newLabel andPlaceholder:(NSString *)newPlaceholder atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel;

@end
