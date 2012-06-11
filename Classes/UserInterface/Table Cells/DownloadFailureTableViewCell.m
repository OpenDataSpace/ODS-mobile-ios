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
//  DownloadFailureTableViewCell.m
//

#import "DownloadFailureTableViewCell.h"
#import "DownloadInfo.h"
#import "RepositoryItem.h"
#import "Utility.h"

@implementation DownloadFailureTableViewCell

@synthesize downloadInfo = _downloadInfo;

- (void)dealloc
{
    [_downloadInfo release];
    
    [super dealloc];
}

- (id)initWithIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self)
    {
        [self.textLabel setFont:[UIFont boldSystemFontOfSize:17.0f]];
        [self.textLabel setTextColor:[UIColor redColor]];
        
        [self.detailTextLabel setFont:[UIFont systemFontOfSize:13.0f]];
        [self.detailTextLabel setTextColor:[UIColor redColor]];
        
        [self setSelectionStyle:UITableViewCellEditingStyleNone];
        [self setAccessoryView:[self makeFailureDisclosureButton]];
    }
    return self;
}

- (void)setDownloadInfo:(DownloadInfo *)downloadInfo
{
    [_downloadInfo autorelease];
    _downloadInfo = [downloadInfo retain];
    
    if (downloadInfo != nil)
    {
        [self.textLabel setText:downloadInfo.repositoryItem.title];
        [self.imageView setImage:imageForFilename(downloadInfo.repositoryItem.title)];
    }
}

- (UIButton *)makeFailureDisclosureButton
{
    UIImage *errorBadgeImage = [UIImage imageNamed:@"ui-button-bar-badge-error.png"];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:CGRectMake(0, 0, errorBadgeImage.size.width, errorBadgeImage.size.height)];
    [button setBackgroundImage:errorBadgeImage forState:UIControlStateNormal];
    [button addTarget:self action:@selector(accessoryButtonTapped:withEvent:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)accessoryButtonTapped:(UIControl *)button withEvent:(UIEvent *)event
{
    UITableView *tableView = (UITableView *) self.superview;
    NSIndexPath * indexPath = [tableView indexPathForRowAtPoint:[[[event touchesForView:button] anyObject] locationInView:tableView]];

    if (indexPath != nil)
    {
        [tableView.delegate tableView:tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
    }
}

@end

NSString * const kDownloadFailureCellIdentifier = @"DownloadFailureCellIdentifier";
