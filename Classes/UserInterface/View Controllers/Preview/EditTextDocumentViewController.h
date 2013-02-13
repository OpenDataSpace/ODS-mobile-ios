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
//  EditTextDocumentViewController.h
//

#import <UIKit/UIKit.h>
#import "PostProgressBar.h"
@class DownloadMetadata;


@protocol EditTextDocumentViewControllerDelegate <NSObject>
@optional
- (void)editTextDocumentViewControllerDismissed;
@end

@interface EditTextDocumentViewController : UIViewController <PostProgressBarDelegate, UIAlertViewDelegate, UITextViewDelegate>
{
    BOOL _documentIsEmpty;
}

@property (nonatomic, retain) IBOutlet UITextView *editView;
@property (nonatomic, copy) NSString *documentPath;
@property (nonatomic, copy) NSString *documentTempPath;
@property (nonatomic, copy) NSString *objectId;
@property (nonatomic, retain) PostProgressBar *postProgressBar;
@property (nonatomic, copy) NSString *documentName;
@property (nonatomic, retain) DownloadMetadata *fileMetadata;
@property (nonatomic, copy) NSString *selectedAccountUUID;
@property (nonatomic, copy) NSString *tenantID;
@property (nonatomic, assign) BOOL isRestrictedDocument;
@property (nonatomic, assign) id<EditTextDocumentViewControllerDelegate> delegate;

- (id)initWithObjectId:(NSString *)objectId andDocumentPath:(NSString *)documentPath;

@end
