//
//  TextViewCellController.h
//  FreshDocs
//
//  Created by bdt on 5/6/14.
//
//

#import <Foundation/Foundation.h>

#import "IFCellFirstResponder.h"
#import "IFCellController.h"
#import "IFCellModel.h"

@interface TextViewCellController : NSObject <IFCellController, IFCellControllerFirstResponder, UITextViewDelegate> {
    NSString *label;
	NSString *placeholder;
	id<IFCellModel> model;
	NSString *key;
    
    UIColor *backgroundColor;
    UIColor *textViewColor;
    UIColor *textViewTextColor;
	
	SEL updateAction;
    SEL editChangedAction;
    
	UIKeyboardType keyboardType;
	UITextAutocapitalizationType autocapitalizationType;
	UITextAutocorrectionType autocorrectionType;
	UIReturnKeyType returnKeyType;
	BOOL secureTextEntry;
	NSInteger indentationLevel;
}

@property (nonatomic, retain) UIColor *backgroundColor;
@property (nonatomic, retain) UIColor *textViewColor;
@property (nonatomic, retain) UIColor *textViewTextColor;

@property (nonatomic, assign) SEL updateAction;
@property (nonatomic, assign) SEL editChangedAction;
@property (nonatomic, assign) id updateTarget;

@property (nonatomic, assign) UIKeyboardType keyboardType;
@property (nonatomic, assign) UITextAutocapitalizationType autocapitalizationType;
@property (nonatomic, assign) UITextAutocorrectionType autocorrectionType;
@property (nonatomic, assign) UIReturnKeyType returnKeyType;
@property (nonatomic, assign) BOOL secureTextEntry;
@property (nonatomic, assign) NSInteger indentationLevel;

@property (nonatomic, assign) UITextView *textView;
@property (nonatomic, assign) id<IFCellControllerFirstResponderHost>cellControllerFirstResponderHost;

- (id)initWithLabel:(NSString *)newLabel andPlaceholder:(NSString *)newPlaceholder atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel;
@end
