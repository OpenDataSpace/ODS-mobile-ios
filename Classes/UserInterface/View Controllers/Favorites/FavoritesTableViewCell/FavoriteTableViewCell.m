//
//  FavoriteTableViewCell.m
//  FreshDocs
//
//  Created by Mohamad Saeedi on 13/08/2012.
//  Copyright (c) 2012 . All rights reserved.
//

#import "FavoriteTableViewCell.h"

@implementation FavoriteTableViewCell


@synthesize filename;
@synthesize details;
@synthesize image;
@synthesize progressBar;

- (void)dealloc {
	[filename release];
	[details release];
	[image release];
    [progressBar release];
    [super dealloc];
}


NSString * const FavoriteTableCellIdentifier = @"FavoriteCellIdentifier";
/*
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
 */

@end
