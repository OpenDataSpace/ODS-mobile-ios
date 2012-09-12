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
//  UploadProgressTableViewCell.m
//

#import "UploadProgressTableViewCell.h"
#import "UploadInfo.h"
#import "Utility.h"
#import "RepositoryItem.h"
#import "FileUtils.h"
#import "UIColor+Theme.h"
#import "AppProperties.h"
#import "CMISUploadFileHTTPRequest.h"
#import "CustomBadge.h"

const CGFloat kTitleFontSize = 17.0f;
const CGFloat kDetailFontSize = 14.0f;

@interface UploadProgressTableViewCell()
/*
 Set ups the cell in the waiting for upload state
 */
- (void)waitingForUploadState;
/*
 Set ups the cell in the uploading state and shows an upload progress
 */
- (void)enableProgressView;
/*
 For a failed upload, Shows text in red
 */
- (void)failedUploadState;
@end

@implementation UploadProgressTableViewCell
@synthesize uploadInfo = _uploadInfo;
@synthesize progressView = _progressView;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_uploadInfo.uploadRequest setUploadProgressDelegate:nil];

    [_uploadInfo release];
    [_progressView release];
    [super dealloc];
}

- (id)initWithIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if(self)
    {
        [self.textLabel setFont:[UIFont boldSystemFontOfSize:kTitleFontSize]];
        [self.textLabel setMinimumFontSize:10.0f];
         
        [self.detailTextLabel setText:NSLocalizedString(@"Waiting to upload...", @"")];
        [self.detailTextLabel setFont:[UIFont italicSystemFontOfSize:kDetailFontSize]];
        [self.detailTextLabel setTextColor:[UIColor colorWithHexRed:110 green:110 blue:110 alphaTransparency:1]];
        
        UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        [progressView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin];
        [progressView setFrame:CGRectMake(kTableCellTextLeftPadding, 22, 280 - kTableCellTextLeftPadding, 25)];
        [self addSubview:progressView];
        [progressView setHidden:YES];
        [self setProgressView:progressView];
        [progressView release];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadChanged:) name:kNotificationUploadWaiting object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadChanged:) name:kNotificationUploadStarted object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadChanged:) name:kNotificationUploadFinished object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadChanged:) name:kNotificationUploadFailed object:nil];
    }
    return self;
}

#pragma mark - Utility methods
- (void)waitingForUploadState
{
    [self transparentViews];
    [self.detailTextLabel setTextColor:[UIColor colorWithHexRed:110 green:110 blue:110 alphaTransparency:1]];
    [self.textLabel setTextColor:[UIColor blackColor]];
    [self.detailTextLabel setHidden:NO];
    [self.progressView setHidden:YES];
    
    [self.detailTextLabel setText:NSLocalizedString(@"Waiting to upload...", @"")];
    [self setAccessoryView:[self makeCloseDisclosureButton]];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

- (void)enableProgressView
{
    [self.uploadInfo.uploadRequest setUploadProgressDelegate:self.progressView];
    [self transparentViews];
    [self.detailTextLabel setTextColor:[UIColor colorWithHexRed:110 green:110 blue:110 alphaTransparency:1]];
    [self.textLabel setTextColor:[UIColor blackColor]];
    [self.detailTextLabel setHidden:YES];
    [self.progressView setHidden:NO];
    [self.progressView setProgress:0];
    
    [self setAccessoryView:[self makeCloseDisclosureButton]];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

- (void)failedUploadState
{
    [self solidViews];
    [self.detailTextLabel setHidden:NO];
    [self.progressView setHidden:YES];
    
    [self.detailTextLabel setTextColor:[UIColor redColor]];
    [self.textLabel setTextColor:[UIColor lightGrayColor]];
    
    [self setAccessoryView:[self makeFailureDisclosureButton]];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    [self.detailTextLabel setText:NSLocalizedString(@"Failed to Upload", @"")];
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

- (void)transparentViews
{
    [self.textLabel setAlpha:0.5f];
    [self.textLabel setOpaque:NO];
    [self.detailTextLabel setAlpha:0.5f];
    [self.detailTextLabel setOpaque:NO];
    [self.imageView setAlpha:0.5f];
    [self.imageView setOpaque:NO];
}

- (void)solidViews
{
    [self.textLabel setAlpha:1.0f];
    [self.textLabel setOpaque:YES];
    [self.detailTextLabel setAlpha:1.0f];
    [self.detailTextLabel setOpaque:YES];
    [self.imageView setAlpha:1.0f];
    [self.imageView setOpaque:YES];
}

- (void)setUploadInfo:(UploadInfo *)uploadInfo
{
    [_uploadInfo.uploadRequest setUploadProgressDelegate:nil];
    [uploadInfo retain];
    [_uploadInfo release];
    _uploadInfo = uploadInfo;
    
    [self.textLabel setText:[uploadInfo completeFileName]];
    [self.imageView setImage:imageForFilename(self.textLabel.text)];
    
    switch (_uploadInfo.uploadStatus) 
    {
        case UploadInfoStatusActive:
            [self waitingForUploadState];
            break;
        case UploadInfoStatusUploading:    
            [self enableProgressView];
            break;
        case UploadInfoStatusFailed:    
            [self failedUploadState];
            break;
        default:
            [self waitingForUploadState];
            break;
    }
}

#pragma mark - Handling the Accessory View
- (UIButton *)makeFailureDisclosureButton
{
    UIImage *errorBadgeImage = [UIImage imageNamed:@"ui-button-bar-badge-error.png"];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:CGRectMake(0, 0, errorBadgeImage.size.width, errorBadgeImage.size.height)];
    [button setBackgroundImage:errorBadgeImage forState:UIControlStateNormal];
    [button addTarget:self action:@selector(accessoryButtonTapped:withEvent:) forControlEvents:UIControlEventTouchUpInside];
    return button;
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

- (UIButton *)makeDetailDisclosureButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeInfoDark];
    [button addTarget:self action:@selector(accessoryButtonTapped:withEvent:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)accessoryButtonTapped:(UIControl *)button withEvent:(UIEvent *)event
{
    UITableView *tableView = (UITableView *) self.superview;
    NSIndexPath * indexPath = [tableView indexPathForRowAtPoint:[[[event touchesForView:button] anyObject] locationInView:tableView]];
    if ( indexPath == nil )
        return;
    
    [tableView.delegate tableView:tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
}

#pragma mark - Adjust to state transitions
/*
 Since the cells are not set to the "Editing" style
 the willTransitionToState: method will not be called
 this is the only method that WILL be called but we need to make
 sure the tableView is editing before making any chage in the view
 */
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    BOOL tableViewEditing = ((UITableView *)self.superview).editing;
    [UIView beginAnimations:@"progressbar" context:nil];
    [self.progressView setAlpha:(tableViewEditing ? 0.5f : 1.0f)];
    [UIView commitAnimations];
}

#pragma mark - Notification methods
- (void)uploadChanged:(NSNotification *)notification
{
    UploadInfo *uploadInfo = [notification.userInfo objectForKey:@"uploadInfo"];
    if (uploadInfo.uuid == self.uploadInfo.uuid)
    {
        [self setUploadInfo:uploadInfo];
    }
}
@end
