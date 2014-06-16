//
//  LinkManagementViewController.h
//  FreshDocs
//
//  Created by bdt on 6/9/14.
//
//

#import <UIKit/UIKit.h>
#import "RepositoryItem.h"
#import "IFGenericTableViewController.h"
#import "UITableView+LongPress.h"

@interface LinkManagementViewController : IFGenericTableViewController <UIActionSheetDelegate, UITableViewDelegateLongPress>

@property (nonatomic, strong) NSURL* parentURL;
@property (nonatomic, strong) RepositoryItem*   repositoryItem;
@property (nonatomic, copy) NSString *accountUUID;

@property (nonatomic, strong) NSMutableArray*   fileLinks;
@end
