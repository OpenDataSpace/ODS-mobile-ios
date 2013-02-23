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
 *
 * ***** END LICENSE BLOCK ***** */
//
//  CreateFolderViewController.h
//

#import <Foundation/Foundation.h>
#import "IFGenericTableViewController.h"
#import "BaseHTTPRequest.h"
#import "MBProgressHUD.h"
@class RepositoryItem;
@class CreateFolderViewController;

@protocol CreateFolderRequestDelegate <NSObject>
@optional
- (void)createFolder:(CreateFolderViewController *)createFolder succeededForName:(NSString *)folderName;
- (void)createFolder:(CreateFolderViewController *)createFolder failedForName:(NSString *)folderName;
- (void)createFolderCancelled:(CreateFolderViewController *)createFolder;
@end


@interface CreateFolderViewController : IFGenericTableViewController <ASIHTTPRequestDelegate>

@property (nonatomic, assign) id<CreateFolderRequestDelegate> delegate;
@property (nonatomic, retain) UIBarButtonItem *createButton;
@property (nonatomic, retain) MBProgressHUD *progressHUD;
@property (nonatomic, retain) NSRegularExpression *regexNameValidation;

@property (nonatomic, retain) RepositoryItem *parentItem;
@property (nonatomic, retain) NSString *accountUUID;

- (id)initWithParentItem:(RepositoryItem *)parentItem accountUUID:(NSString *)accountUUID;

@end
