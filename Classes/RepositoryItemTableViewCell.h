//
//  RepositoryItemTableViewCell.h
//  Alfresco
//
//  Created by Michael Muller on 10/8/09.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RepositoryItemTableViewCell : UITableViewCell {
	IBOutlet UILabel *filename;
	IBOutlet UILabel *details;
	IBOutlet UIImageView *image;
}

@property (nonatomic, retain) UILabel *filename;
@property (nonatomic, retain) UILabel *details;
@property (nonatomic, retain) UIImageView *image;

@end

extern NSString * const RepositoryItemCellIdentifier;
