//
//  LinkTableViewCell.m
//  FreshDocs
//
//  Created by bdt on 6/9/14.
//
//

#import "LinkTableViewCell.h"

@implementation LinkTableViewCell
@synthesize lblLinkName = _lblLinkName;
@synthesize lblLinkExpirationDate = _lblLinkExpirationDate;
@synthesize lblLinkURL = _lblLinkURL;

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
