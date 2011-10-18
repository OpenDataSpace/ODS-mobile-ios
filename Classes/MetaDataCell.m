//
//  MetaDataCellView.m
//  FreshDocs
//
//  Created by Gi Hyun Lee on 7/18/11.
//  Copyright 2011 Zia Consulting. All rights reserved.
//

#import "MetaDataCell.h"


@implementation MetaDataCell
@synthesize metadataLabel;
@synthesize metaDataValueText;

- (void)dealloc
{
    [metadataLabel release];
    [metaDataValueText release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/



@end
