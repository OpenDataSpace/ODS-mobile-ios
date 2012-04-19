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
//  HelpRowRender.m
//

#import "HelpRowRender.h"
#import "TableCellViewController.h"
#import "IFButtonCellController.h"

@implementation HelpRowRender

@synthesize allowsSelection = _allowsSelection;

- (NSArray *)tableGroupsWithDatasource:(NSDictionary *)datasource
{
    NSArray *helpGuides = [datasource objectForKey:@"helpGuides"];
    NSMutableArray *groups =  [NSMutableArray array];
    NSMutableArray *helpGuidesGroup = [NSMutableArray array];
    NSInteger index = 0;
    
    /**
     * First group: A list of help guides
     */
    for (NSDictionary *guide in helpGuides) 
    {
        TableCellViewController *guideCell = [[TableCellViewController alloc] initWithAction:nil
                                                                                    onTarget:nil];
        [guideCell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        [guideCell setTag:index];
        [guideCell.textLabel setText:[guide objectForKey:@"title"]];
        [guideCell.imageView setImage:[UIImage imageNamed:kHelpGuideIcon_ImageName]];
		[guideCell setSelectionStyle:UITableViewCellSelectionStyleBlue];
        
        [helpGuidesGroup addObject:guideCell];
        [guideCell release];
        index++;
        
        [self setAllowsSelection:YES];
    }
    [groups addObject:helpGuidesGroup];
    
    /**
     * Second group: Button to return to Welcome Screen
     */
    NSMutableArray *buttonCellGroup = [NSMutableArray array];

    IFButtonCellController *welcomeScreenCell = [[IFButtonCellController alloc] initWithLabel:NSLocalizedString(@"help.view.button.welcomeScreen", @"Show Welcome Screen")
                                                                                   withAction:nil
                                                                                     onTarget:nil];
    [buttonCellGroup addObject:welcomeScreenCell];
    [welcomeScreenCell release];
    
    [groups addObject:buttonCellGroup];
    
    return groups;
}

- (NSArray *)tableHeadersWithDatasource:(NSDictionary *)datasource
{
    return [NSArray arrayWithObjects:NSLocalizedString(@"help.view.header.guides", @"Guides"), @"", nil];
}

- (NSArray *)tableFootersWithDatasource:(NSDictionary *)datasource
{
    return nil;
}

@end
