//
//  IFTextAreaViewController.h
//  FreshDocs
//
//  Created by Gi Hyun Lee on 7/23/11.
//  Copyright 2011 Zia Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IFTemporaryModel.h"
#import "TextViewWithPlaceholder.h"


@interface IFTextAreaViewController : UIViewController <UITextViewDelegate> {
	TextViewWithPlaceholder *textArea;
	
	NSString *key;
	IFTemporaryModel *model;
	NSString *placeholder;
	BOOL isRequired;
}

@property (nonatomic, retain) IBOutlet UITextView *textArea;
@property (nonatomic, retain) NSString *key;
@property (nonatomic, retain) IFTemporaryModel *model;
@property (nonatomic, retain) NSString *placeholder;
@property (nonatomic, assign) BOOL isRequired;

- (void)registerForKeyboardNotifications;
- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;

- (void)cancelButtonPressed;
- (void)saveAndExit;
@end
