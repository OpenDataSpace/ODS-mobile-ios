/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Alfresco Mobile App.
 *
 * The Initial Developer of the Original Code is Zia Consulting, Inc.
 * Portions created by the Initial Developer are Copyright (C) 2011-2012
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  IFTextAreaViewController.h
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
