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
//  UploadFormTableViewController.h
//

#import <UIKit/UIKit.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "IFGenericTableViewController.h"
#import "PostProgressBar.h"
#import "ASIHTTPRequestDelegate.h"
#import "MBProgressHUD.h"
#import "ModalViewControllerProtocol.h"
#import "UploadItem.h"

@class UploadFormTableViewController;
@class IFTextCellController;

@protocol UploadFormDelegate <NSObject>
- (void)dismissUploadViewController:(UploadFormTableViewController *)recipeAddViewController
                      didUploadFile:(BOOL)success;
@end

@interface UploadFormTableViewController : IFGenericTableViewController <PostProgressBarDelegate, UIAlertViewDelegate, ASIHTTPRequestDelegate, MBProgressHUDDelegate, ModalViewControllerProtocol> 
{
    NSString *upLinkRelation;
    PostProgressBar *postProgressBar;
    UITextField *createTagTextField;
    NSMutableArray *availableTagsArray;
    
	SEL updateAction;
	id updateTarget;
    
    MBProgressHUD *HUD;
    BOOL popViewControllerOnHudHide;
    
    NSArray *existingDocumentNameArray;
    id<UploadFormDelegate> delegate;
    BOOL presentedAsModal;
    UploadItem *uploadItem;
    NSString *selectedAccountUUID;
    NSString *tenantID;
    IFTextCellController *textCellController;
    BOOL shouldSetResponder;
}

@property (nonatomic, retain) NSString *upLinkRelation;
@property (nonatomic, retain) PostProgressBar *postProgressBar;
@property (nonatomic, retain) UITextField *createTagTextField;
@property (nonatomic, retain) NSMutableArray *availableTagsArray;

@property (nonatomic, assign) SEL updateAction;
@property (nonatomic, assign) id updateTarget;

@property (nonatomic, retain) NSArray *existingDocumentNameArray;
@property (nonatomic, assign) id<UploadFormDelegate> delegate;
@property (nonatomic, retain) UploadItem *uploadItem;
@property (nonatomic, retain) NSString *selectedAccountUUID;
@property (nonatomic, retain) NSString *tenantID;
@property (nonatomic, retain) IFTextCellController *textCellController;

@property (nonatomic, retain) NSMutableArray *asyncRequests;

- (void)cancelButtonPressed;
- (void)saveButtonPressed;
- (void)addNewTagButtonPressed;
- (void)popViewController;
- (void)addAndSelectNewTag:(NSString *)newTag;
@end
