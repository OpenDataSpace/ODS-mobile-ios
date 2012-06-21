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
//  DownloadProgressTableViewCell.m
//

#import "DownloadProgressTableViewCell.h"
#import "CMISDownloadFileHTTPRequest.h"
#import "DownloadInfo.h"
#import "FileUtils.h"
#import "DownloadManager.h"
#import "RepositoryItem.h"
#import "UIColor+Theme.h"
#import "Utility.h"

@implementation DownloadProgressTableViewCell

@synthesize downloadInfo = _downloadInfo;
@synthesize progressView = _progressView;
@synthesize alertView = _alertView;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_downloadInfo.downloadRequest setDownloadProgressDelegate:nil];
    [self.alertView setDelegate:nil];
    
    [_downloadInfo release];
    [_progressView release];
    [_alertView release];
    
    [super dealloc];
}

- (id)initWithIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self)
    {
        [self.textLabel setFont:[UIFont boldSystemFontOfSize:17.0f]];
        
        UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        [progressView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin];
        [progressView setHidden:YES];
        [self addSubview:progressView];
        [self setProgressView:progressView];
        [progressView release];
        
        [self setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadChanged:) name:kNotificationDownloadStarted object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadChanged:) name:kNotificationDownloadFinished object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadChanged:) name:kNotificationDownloadFailed object:nil];
        
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if ([self.progressView isHidden])
    {
        [self.textLabel setFrame:CGRectMake(52, 8, 242, 21)];
        [self.detailTextLabel setFrame:CGRectMake(52, 30, 242, 21)];
    }
    else
    {
        [self.textLabel setFrame:CGRectMake(52, 3, 242, 21)];
        [self.detailTextLabel setFrame:CGRectMake(52, 37, 242, 21)];
        [self.progressView setFrame:CGRectMake(52, 27, 228, 11)];
    }
}

#pragma mark - UI methods

- (void)defaultState
{
    [self.detailTextLabel setText:NSLocalizedString(@"download.progress.waiting", @"Waiting to download...")];
    [self.detailTextLabel setFont:[UIFont italicSystemFontOfSize:12.0f]];
    [self.detailTextLabel setTextColor:[UIColor colorWithHexRed:110 green:110 blue:110 alphaTransparency:1]];
    [self setAccessoryView:[self makeCloseDisclosureButton]];
    [self.progressView setHidden:YES];
}

- (void)downloadedState
{
    // Not much to do - the cell will be removed automatically
    [self.alertView dismissWithClickedButtonIndex:self.alertView.cancelButtonIndex animated:NO];
    [self setAccessoryView:nil];
}

- (void)downloadingState
{
    CMISDownloadFileHTTPRequest *request = _downloadInfo.downloadRequest;
    [request setDownloadProgressDelegate:self];
    
    [self.detailTextLabel setText:NSLocalizedString(@"download.progress.starting", @"Download starting...")];
    [self.detailTextLabel setFont:[UIFont systemFontOfSize:12.0f]];
    [self.detailTextLabel setTextColor:[UIColor blackColor]];
    [self setAccessoryView:[self makeCloseDisclosureButton]];
    
    float progressAmount = (float)(((request.totalBytesRead + request.partialDownloadSize) * 1.0) / ((request.contentLength + request.partialDownloadSize) * 1.0));
    [self setProgress:progressAmount];
    [self.progressView setHidden:NO];
}

- (void)failedState
{
    [self.progressView setHidden:YES];
    [self.detailTextLabel setText:NSLocalizedString(@"download.progress.failed", @"Failed to download")];
    [self.detailTextLabel setTextColor:[UIColor redColor]];
    [self setAccessoryView:nil];

    [self.alertView dismissWithClickedButtonIndex:self.alertView.cancelButtonIndex animated:NO];
}

- (UIButton *)makeCloseDisclosureButton
{
    UIImage *buttonImage = [UIImage imageNamed:@"stop-transfer"];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height)];
    [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [button addTarget:self action:@selector(accessoryButtonTapped:withEvent:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)accessoryButtonTapped:(UIControl *)button withEvent:(UIEvent *)event
{
    UIAlertView *confirmAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"download.cancel.title", @"Downloads")
                                                            message:[NSString stringWithFormat:NSLocalizedString(@"download.cancel.body", @"Would you like to..."), self.downloadInfo.repositoryItem.title]
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"No", @"No")
                                                  otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil] autorelease];
    [self setAlertView:confirmAlert];
    [confirmAlert show];
}

- (void)setDownloadInfo:(DownloadInfo *)downloadInfo
{
    [_downloadInfo.downloadRequest setDownloadProgressDelegate:nil];

    [_downloadInfo autorelease];
    _downloadInfo = [downloadInfo retain];
    
    if (downloadInfo != nil)
    {
        [self.textLabel setText:downloadInfo.repositoryItem.title];
        [self.imageView setImage:imageForFilename(downloadInfo.repositoryItem.title)];
        
        switch (downloadInfo.downloadStatus)
        {
            case DownloadInfoStatusDownloaded:
                [self downloadedState];
                break;
                
            case DownloadInfoStatusDownloading:
                [self downloadingState];
                break;
                
            case DownloadInfoStatusFailed:
                [self failedState];
                break;
                
            default:
                [self defaultState];
                break;
        }

        [self setNeedsLayout];
        [self setNeedsDisplay];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex && (self.downloadInfo.downloadStatus == DownloadInfoStatusActive || self.downloadInfo.downloadStatus == DownloadInfoStatusDownloading))
    {
        [[DownloadManager sharedManager] clearDownload:self.downloadInfo.cmisObjectId];
    }
}

#pragma mark - ASIProgressDelegate

- (void)setProgress:(float)newProgress
{
    [self.progressView setProgress:newProgress];
    
    CMISDownloadFileHTTPRequest *request = self.downloadInfo.downloadRequest;
    float bytesDownloaded = newProgress * request.totalBytesRead;
    bytesDownloaded = MAX(0, bytesDownloaded);
    float totalBytesToDownload = [self.downloadInfo.repositoryItem.contentStreamLength floatValue];
    
    NSString *label = [NSString stringWithFormat:NSLocalizedString(@"download.progress.details", @"%@ of %@"),
                       [FileUtils stringForLongFileSize:bytesDownloaded],
                       [FileUtils stringForLongFileSize:totalBytesToDownload]];
    [self.detailTextLabel setText:label];
}

#pragma mark - Notification methods

- (void)downloadChanged:(NSNotification *)notification
{
    DownloadInfo *downloadInfo = [notification.userInfo objectForKey:@"downloadInfo"];
    if ([downloadInfo.cmisObjectId isEqualToString:self.downloadInfo.cmisObjectId])
    {
        [self setDownloadInfo:downloadInfo];
    }
}

@end

NSString * const kDownloadProgressCellIdentifier = @"DownloadProgressCellIdentifier";
