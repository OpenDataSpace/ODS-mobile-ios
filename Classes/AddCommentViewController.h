//
//  AddCommentViewController.h
//  FreshDocs
//
//  Created by Gi Hyun Lee on 7/25/11.
//  Copyright 2011 Zia Consulting. All rights reserved.
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
