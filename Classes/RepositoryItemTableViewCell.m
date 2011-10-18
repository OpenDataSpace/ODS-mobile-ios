//
//  RepositoryItemTableViewCell.m
//  Alfresco
//
//  Created by Michael Muller on 10/8/09.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

#import "RepositoryItemTableViewCell.h"


@implementation RepositoryItemTableViewCell

@synthesize filename;
@synthesize details;
@synthesize image;

- (void)dealloc {
	[filename release];
	[details release];
	[image release];
    [super dealloc];
}

@end

NSString * const RepositoryItemCellIdentifier = @"RepositoryItemCellIdentifier";
