//
//  CreateLinkViewController.h
//  FreshDocs
//
//  Created by bdt on 6/11/14.
//
//

#import <UIKit/UIKit.h>
#import "RepositoryItem.h"
#import "IFGenericTableViewController.h"
#import "BaseHTTPRequest.h"
#import "MBProgressHUD.h"

@class CreateLinkViewController;

@protocol CreateLinkRequestDelegate <NSObject>
@optional
- (void)createLink:(CreateLinkViewController *)createLink succeededForName:(NSString *)linkName;
- (void)createLink:(CreateLinkViewController *)createLink failedForName:(NSString *)linkName;
- (void)createLinkCancelled:(CreateLinkViewController *)createLink;
@end

@interface CreateLinkViewController : IFGenericTableViewController <ASIHTTPRequestDelegate>
@property (nonatomic, assign) id<CreateLinkRequestDelegate> delegate;
@property (nonatomic, strong) UIBarButtonItem *createButton;
@property (nonatomic, strong) MBProgressHUD *progressHUD;
@property (nonatomic, retain) RepositoryItem *repositoryItem;
@property (nonatomic, retain) NSString *accountUUID;
@property (nonatomic, copy) NSURL *linkCreateURL;

- (id)initWithRepositoryItem:(RepositoryItem *)repoItem accountUUID:(NSString *)accountUUID;
@end
