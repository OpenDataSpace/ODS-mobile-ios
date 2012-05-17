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
#import "AppProperties.h"
#import "IFButtonCellController.h"
#import "TableCellViewController.h"

@interface HelpRowRender ()
@property (nonatomic, retain) NSMutableArray *headerGroups;
@end

@implementation HelpRowRender

@synthesize allowsSelection = _allowsSelection;
@synthesize headerGroups = _headerGroups;

- (void)dealloc
{
    [_headerGroups release];
    [super dealloc];
}

- (BOOL)allowsSelection
{
    return YES;
}

- (NSMutableArray *)headerGroups
{
    if (_headerGroups == nil)
    {
        _headerGroups = [[NSMutableArray alloc] init];
    }
    return _headerGroups;
}

- (NSArray *)tableGroupsWithDatasource:(NSDictionary *)datasource
{
    NSArray *helpGuides = [datasource objectForKey:@"helpGuides"];
    NSMutableArray *groups =  [NSMutableArray array];
    NSMutableArray *helpGuidesGroup = [NSMutableArray array];
    NSInteger index = 0;
    
    /**
     * (Mandatory) First group: A list of help guides.
     */
    [self.headerGroups addObject:NSLocalizedString(@"help.guides.header", @"Guides")];

    if (helpGuides.count > 0)
    {
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
        }
    }
    else
    {
        TableCellViewController *guideCell = [[TableCellViewController alloc] initWithAction:nil
                                                                                    onTarget:nil];
        [guideCell setAccessoryType:UITableViewCellAccessoryNone];
        [guideCell setSelectionStyle:UITableViewCellEditingStyleNone];
        [guideCell.textLabel setText:NSLocalizedString(@"help.guides.message.empty", @"No guides")];
        
        [helpGuidesGroup addObject:guideCell];
        [guideCell release];
        index++;
    }
    [groups addObject:helpGuidesGroup];
    
    /**
     * (Optional) Second group: Button to return to Welcome Screen
     */
    BOOL showHomescreenAppProperty = [[AppProperties propertyForKey:kHomescreenShow] boolValue];
    if (showHomescreenAppProperty)
    {
        [self.headerGroups addObject:@""];
        NSMutableArray *buttonCellGroup = [NSMutableArray array];
        
        IFButtonCellController *welcomeScreenCell = [[IFButtonCellController alloc] initWithLabel:NSLocalizedString(@"help.buttons.welcomeScreen", @"Show Welcome Screen")
                                                                                       withAction:nil
                                                                                         onTarget:nil];
        [buttonCellGroup addObject:welcomeScreenCell];
        [welcomeScreenCell release];
        
        [groups addObject:buttonCellGroup];
    }

    return groups;
}

- (NSArray *)tableHeadersWithDatasource:(NSDictionary *)datasource
{
    return [NSArray arrayWithArray:self.headerGroups];
}

- (NSArray *)tableFootersWithDatasource:(NSDictionary *)datasource
{
    return nil;
}

@end
