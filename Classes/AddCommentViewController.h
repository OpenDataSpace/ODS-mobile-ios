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
//  AddCommentViewController.h
//

#import <UIKit/UIKit.h>
#import "TextViewWithPlaceholder.h"
#import "CommentsHttpRequest.h"
#import "NodeRef.h"

@protocol AddCommentViewDelegate;

@interface AddCommentViewController  : UIViewController <UITextViewDelegate, ASIHTTPRequestDelegate> {
	TextViewWithPlaceholder *textArea;
    NSString *commentText;
	NSString *placeholder;
    id <AddCommentViewDelegate> delegate;
    
    NodeRef *nodeRef;
}

@property (nonatomic, retain) IBOutlet UITextView *textArea;
@property (nonatomic, retain) NSString *commentText;
@property (nonatomic, retain) NSString *placeholder;
@property (nonatomic, assign) id <AddCommentViewDelegate> delegate;
@property (nonatomic, retain) NodeRef *nodeRef;

- (id)initWithNodeRef:(NodeRef *)aNodeRef;

- (void)registerForKeyboardNotifications;
- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;

- (void)cancelButtonPressed;
- (void)saveCommentButtonPressed;
- (void)saveAndExit;
@end

@protocol AddCommentViewDelegate <NSObject>
@optional
- (void)didSubmitComment:(NSString *)comment;
- (void)didCancelComment;
@end
