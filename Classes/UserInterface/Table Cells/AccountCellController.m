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
//  AccountCellController.m
//

#import "AccountCellController.h"
#import "AccountTableViewCell.h"

@implementation AccountCellController
@synthesize warningImage = _warningImage;

- (void)dealloc
{
    [_warningImage release];
    [super dealloc];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AccountTableViewCell *cell = (AccountTableViewCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    [cell.warningView setImage:self.warningImage];
    
    return cell;
}

- (UITableViewCell *)createTableViewCell
{
    return [[[AccountTableViewCell alloc] initWithStyle:self.cellStyle reuseIdentifier:[self cellIdentifier]] autorelease];
}

- (NSString *)cellIdentifier
{
    return @"AccountCellController";
}

@end
