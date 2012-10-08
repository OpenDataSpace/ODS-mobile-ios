/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Alfresco Mobile App.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  AccountAutocreateRowRender.m
//

#import "AccountAutocreateRowRender.h"
#import "TableCellViewController.h"

@interface AccountAutocreateRowRender ()
@property (nonatomic, retain) NSMutableArray *headerGroups;
@property (nonatomic, retain) NSMutableArray *footerGroups;
@end

@implementation AccountAutocreateRowRender

@synthesize headerGroups = _headerGroups;
@synthesize footerGroups = _footerGroups;

- (void)dealloc
{
    [_headerGroups release];
    [_footerGroups release];
    [super dealloc];
}

- (BOOL)allowsSelection
{
    return YES;
}

- (BOOL)allowsEditing
{
    return NO;
}

- (NSMutableArray *)headerGroups
{
    if (_headerGroups == nil)
    {
        _headerGroups = [[NSMutableArray alloc] init];
    }
    return _headerGroups;
}

- (NSMutableArray *)footerGroups
{
    if (_footerGroups == nil)
    {
        _footerGroups = [[NSMutableArray alloc] init];
    }
    return _footerGroups;
}

- (NSArray *)tableGroupsWithDatasource:(NSDictionary *)datasource
{
    NSMutableArray *groups =  [NSMutableArray array];
    NSMutableArray *items = [NSMutableArray array];

    NSURL *repositoryUrl = [datasource valueForKey:@"repositoryUrl"];
    BOOL isCloud = [[datasource valueForKey:@"isCloud"] boolValue];

    if (isCloud)
    {
        /**
         * Cloud - add cloud account plus sign-up footer link
         */
        [self.headerGroups addObject:NSLocalizedString(@"accountCreate.message.cloud", @"To preview this document, you'll need to configure an Alfresco Cloud account")];

        TableCellViewController *choiceCell = [[TableCellViewController alloc] init];
        [choiceCell.textLabel setText:NSLocalizedString(@"accountCreate.title.create", @"Yes, create an account")];
        [choiceCell setSelectionStyle:UITableViewCellSelectionStyleBlue];
        [choiceCell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        [choiceCell setBackgroundColor:[UIColor whiteColor]];
        [choiceCell.imageView setImage:[UIImage imageNamed:@"cloud.png"]];
        [items addObject:choiceCell];
        [choiceCell release];

        [self.footerGroups addObject:NSLocalizedString(@"accountCreate.footer.cloud", @"...")];
    }
    else
    {
        /**
         * On-premise
         */
        [self.headerGroups addObject:[NSString stringWithFormat:NSLocalizedString(@"accountCreate.message.onPremise", @"To preview this document, an account must be configured for %@"), repositoryUrl.host]];

        TableCellViewController *choiceCell = [[TableCellViewController alloc] init];
        [choiceCell.textLabel setText:NSLocalizedString(@"accountCreate.title.create", @"Yes, create an account")];
        [choiceCell setSelectionStyle:UITableViewCellSelectionStyleBlue];
        [choiceCell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        [choiceCell setBackgroundColor:[UIColor whiteColor]];
        [choiceCell.imageView setImage:[UIImage imageNamed:@"server.png"]];
        [items addObject:choiceCell];
        [choiceCell release];

        [self.footerGroups addObject:NSLocalizedString(@"accountCreate.footer.onPremise", @"...")];
    }

    [groups addObject:[NSArray arrayWithArray:items]];
    [items removeAllObjects];

    /**
     * Group - Cancel
     */
    [self.headerGroups addObject:@""];

    TableCellViewController *choiceCell = [[TableCellViewController alloc] init];
    [choiceCell.textLabel setText:NSLocalizedString(@"accountCreate.title.cancel", @"Not at this time")];
    [choiceCell setSelectionStyle:UITableViewCellSelectionStyleBlue];
    [choiceCell setBackgroundColor:[UIColor whiteColor]];
    [items addObject:choiceCell];
    [choiceCell release];

    [self.footerGroups addObject:NSLocalizedString(@"accountCreate.footer.cancel", @"You'll be returned to the document details page in Safari")];

    [groups addObject:[NSArray arrayWithArray:items]];

    return groups;
}

- (NSArray *)tableHeadersWithDatasource:(NSDictionary *)datasource
{
    return [NSArray arrayWithArray:self.headerGroups];
}

- (NSArray *)tableFootersWithDatasource:(NSDictionary *)datasource
{
    return [NSArray arrayWithArray:self.footerGroups];
}

@end
