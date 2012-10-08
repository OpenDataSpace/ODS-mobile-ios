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
//  DownloadSummaryTableViewCell.m
//

#import "DownloadSummaryTableViewCell.h"
#import "DownloadManager.h"
#import "FileUtils.h"
#import "MKNumberBadgeView.h"

@implementation DownloadSummaryTableViewCell

@synthesize titleLabel = _titleLabel;
@synthesize progressLabel = _progressLabel;
@synthesize progressBar = _progressBar;
@synthesize downloadsBadge = _downloadsBadge;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[DownloadManager sharedManager] setQueueProgressDelegate:nil];
    
    [_titleLabel release];
    [_progressLabel release];
    [_progressBar release];
    [_downloadsBadge release];
    
    [super dealloc];
}

- (id)initWithIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self)
    {
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(52, 3, 242, 21)];
        [title setText:NSLocalizedString(@"download.summary.title", @"In Progress")];
        [title setFont:[UIFont boldSystemFontOfSize:17.0f]];
        [title setHighlightedTextColor:[UIColor whiteColor]];
        [self.contentView addSubview:title];
        [self setTitleLabel:title];
        [title release];

        UILabel *detail = [[UILabel alloc] initWithFrame:CGRectMake(52, 37, 242, 21)];
        [detail setText:@""];
        [detail setFont:[UIFont systemFontOfSize:12.0f]];
        [detail setHighlightedTextColor:[UIColor whiteColor]];
        [self.contentView addSubview:detail];
        [self setProgressLabel:detail];
        [detail release];

        MKNumberBadgeView *badgeView = [[MKNumberBadgeView alloc] initWithFrame:CGRectMake(0, 8, 44, 44)];
        [badgeView setValue:[[[DownloadManager sharedManager] activeDownloads] count]];
        [self.contentView addSubview:badgeView];
        [self setDownloadsBadge:badgeView];
        [badgeView release];

        UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        [progressView setFrame:CGRectMake(52, 27, 228, 11)];
        [self.contentView addSubview:progressView];
        [progressView setHidden:YES];
        [self setProgressBar:progressView];
        [progressView release];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadChanged:) name:kNotificationDownloadStarted object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadChanged:) name:kNotificationDownloadFinished object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadChanged:) name:kNotificationDownloadFailed object:nil];

        [self setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
        [self setSelectionStyle:UITableViewCellSelectionStyleBlue];
        [self setShouldIndentWhileEditing:NO];
        
        [[DownloadManager sharedManager] setQueueProgressDelegate:self];
    }
    return self;    
}

- (BOOL)shouldIndentWhileEditing
{
    return NO;
}

#pragma mark - ASIProgressDelegate

- (void)setProgress:(float)newProgress
{
    DownloadManager *manager = [DownloadManager sharedManager];
    NSInteger operationCount = [[manager activeDownloads] count];
    [self.downloadsBadge setValue:operationCount];

    [self.progressBar setProgress:newProgress];
    [self.progressBar setHidden:NO];

    float bytesLeft = MAX(0, (1 - newProgress) * manager.downloadQueue.totalBytesToDownload);

    NSString *label = [NSString stringWithFormat:NSLocalizedString(@"download.summary.details", @"%@ remaining"),
                       [FileUtils stringForLongFileSize:bytesLeft]];
    [self.progressLabel setText:label];
}

#pragma mark - Download notifications

- (void)downloadChanged:(NSNotification *)notification
{
    NSArray *activeDownloads = [[DownloadManager sharedManager] activeDownloads];
    [self.downloadsBadge setValue:[activeDownloads count]];
}

@end

NSString * const kDownloadSummaryCellIdentifier = @"DownloadSummaryCellIdentifier";
