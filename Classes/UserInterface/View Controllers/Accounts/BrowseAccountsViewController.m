//
//  BrowseAccountsViewController.m
//  FreshDocs
//
//  Created by Ricardo Villarreal on 3/13/12.
//  Copyright (c) 2012 . All rights reserved.
//

#import "BrowseAccountsViewController.h"
#import "IFTextViewTableView.h"
#import "FDGenericTableViewPlistReader.h"

@implementation BrowseAccountsViewController
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        [self setSettingsReader:[[[FDGenericTableViewPlistReader alloc] initWithPlistPath:[[NSBundle mainBundle] pathForResource:@"BrowseAccountConfiguration" ofType:@"plist"]] autorelease]];
    }
    return self;
}
@end
