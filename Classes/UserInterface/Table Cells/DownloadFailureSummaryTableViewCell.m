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
//  DownloadFailureSummaryTableViewCell.m
//

#import "DownloadFailureSummaryTableViewCell.h"
#import "DownloadManager.h"
#import "MKNumberBadgeView.h"

@implementation DownloadFailureSummaryTableViewCell

@synthesize titleLabel = _titleLabel;
@synthesize badge = _badge;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_titleLabel release];
    [_badge release];
    
    [super dealloc];
}


- (id)initWithIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self)
    {
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(52, 20, 242, 21)];
        [title setText:NSLocalizedString(@"download.failures.title", @"Failures")];
        [title setFont:[UIFont boldSystemFontOfSize:17.0f]];
        [title setTextColor:[UIColor redColor]];
        [title setHighlightedTextColor:[UIColor whiteColor]];
        [self.contentView addSubview:title];
        [self setTitleLabel:title];
        [title release];

        MKNumberBadgeView *badgeView = [[MKNumberBadgeView alloc] initWithFrame:CGRectMake(0, 8, 44, 44)];
        [badgeView setValue:[[[DownloadManager sharedManager] failedDownloads] count]];
        [self.contentView addSubview:badgeView];
        [self setBadge:badgeView];
        [badgeView release];
        
        [self setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        [self setSelectionStyle:UITableViewCellSelectionStyleBlue];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadQueueChanged:) name:kNotificationDownloadQueueChanged object:nil];
    }
    return self;
}

- (BOOL)shouldIndentWhileEditing
{
    return NO;
}


#pragma mark - Download notifications

- (void)downloadQueueChanged:(NSNotification *)notification
{
    [self.badge setValue:[[[DownloadManager sharedManager] failedDownloads] count]];
}

@end

NSString * const kDownloadFailureSummaryCellIdentifier = @"DownloadFailureSummaryCellIdentifier";
