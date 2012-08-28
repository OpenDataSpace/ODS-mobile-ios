//
//  PeoplePickerViewController.h
//  FreshDocs
//
//  Created by Tijs Rademakers on 24/08/2012.
//  Copyright (c) 2012 U001b. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Person.h"
#import "AccountInfo.h"

@protocol PeoplePickerDelegate <NSObject>

@required
-(void) personPicked:(Person *)person;

@end

@interface PeoplePickerViewController : UITableViewController <UISearchBarDelegate>

@property (nonatomic, assign) id<PeoplePickerDelegate> delegate;

- (id)initWithStyle:(UITableViewStyle)style account:(NSString *)uuid tenantID:(NSString *)tenantID;

@end
