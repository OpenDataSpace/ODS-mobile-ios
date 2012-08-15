//
//  FavoriteTableViewCell.h
//  FreshDocs
//
//  Created by Mohamad Saeedi on 13/08/2012.
//  Copyright (c) 2012 . All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FavoriteTableViewCell : UITableViewCell

{
IBOutlet UILabel *filename;
IBOutlet UILabel *details;
    IBOutlet UILabel * serverName;
IBOutlet UIImageView *image;
IBOutlet UIProgressView *progressBar;
    IBOutlet UIImageView * status;
    IBOutlet UIButton * favoriteButton;
}

@property (nonatomic, retain) UILabel *filename;
@property (nonatomic, retain) UILabel *details;
@property (nonatomic, retain) UILabel * serverName;
@property (nonatomic, retain) UIImageView *image;
@property (nonatomic, retain) UIProgressView *progressBar;
@property (nonatomic, retain) UIImageView * status;
@property (nonatomic, retain) UIButton * favoriteButton;

@end

extern NSString * const FavoriteTableCellIdentifier;
