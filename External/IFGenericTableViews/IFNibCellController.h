//
//  IFNibCellController.h
//  Denver311
//
//  Created by Gi Hyun Lee on 9/1/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IFCellController.h";

@interface IFNibCellController : NSObject <IFCellController> {
	NSString *nibName;
	UITableViewCell *nibCell;
	NSIndexPath *cellIndexPath;
	UITableViewController *tableController;
}

@property (nonatomic, retain) NSString *nibName;
@property (nonatomic, retain) IBOutlet UITableViewCell *nibCell;
@property (nonatomic, assign) NSIndexPath *cellIndexPath;
@property (nonatomic, assign) UITableViewController *tableController;

- (id)initWithCellNibName:(NSString *)name;
- (void)reloadCell;
@end
