//
//  ChooserFolderViewController.h
//  FreshDocs
//
//  Created by bdt on 11/13/13.
//
//

#import <UIKit/UIKit.h>
#import "IFGenericTableViewController.h"
#import "CMISServiceManager.h"
#import "MBProgressHUD.h"
#import "EGORefreshTableHeaderView.h"

extern NSString * const  kMoveTargetTypeRepo;
extern NSString * const  kMoveTargetTypeFolder;

@class RepositoryItem;

@protocol ChooserFolderDelegate <NSObject>
@optional
- (void) selectedItem:(RepositoryItem*) selectedItem repositoryID:(NSString*) repoID;
@end

@interface ChooserFolderViewController : UITableViewController <EGORefreshTableHeaderDelegate, UITableViewDelegate, CMISServiceManagerListener, MBProgressHUDDelegate>
@property (nonatomic, copy) NSString *viewTitle;
@property (nonatomic, copy) NSString *selectedAccountUUID;
@property (nonatomic, strong) NSArray *repositoriesForAccount;
@property (nonatomic, strong) NSArray *folderItems;
@property (nonatomic, strong) MBProgressHUD *HUD;
@property (nonatomic, strong) EGORefreshTableHeaderView *refreshHeaderView;
@property (nonatomic, strong) NSDate *lastUpdated;

@property (nonatomic, copy) NSString    *itemType;  //repo or folder

@property (nonatomic, copy) NSString *tenantID;
@property (nonatomic, copy) NSString *repositoryID;
@property (nonatomic, strong) id parentItem;

@property (nonatomic, assign) id <ChooserFolderDelegate> selectedDelegate;


- (id)initWithAccountUUID:(NSString *)uuid;
@end
