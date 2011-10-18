    //
//  MetaDataTableViewCell.m
//  FreshDocs
//
//  Created by Michael Muller on 5/4/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

#import "MetaDataTableViewCell.h"


@implementation MetaDataTableViewCell

@synthesize name;
@synthesize value;

- (void)dealloc {
	[name release];
	[value release];
    [super dealloc];
}

@end

NSString * const MetaDataCellIdentifier = @"MetaDataCellIdentifier";
