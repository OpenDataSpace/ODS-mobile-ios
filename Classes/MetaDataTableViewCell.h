//
//  MetaDataTableViewCell.h
//  FreshDocs
//
//  Created by Michael Muller on 5/4/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MetaDataTableViewCell : UITableViewCell {
	IBOutlet UILabel *name;
	IBOutlet UILabel *value;
}

@property (nonatomic, retain) UILabel *name;
@property (nonatomic, retain) UILabel *value;

@end

extern NSString * const MetaDataCellIdentifier;
