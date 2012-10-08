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
 * The Initial Developer of the Original Code is Zia Consulting, Inc.
 * Portions created by the Initial Developer are Copyright (C) 2011-2012
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  FailedUploadsViewController.m
//

#import <QuartzCore/QuartzCore.h>
#import "FailedUploadsViewController.h"
#import "UploadInfo.h"
#import "DownloadInfo.h"
#import "Utility.h"
#import "RepositoryItemTableViewCell.h"
#import "UploadsManager.h"
#import "Theme.h"
#import "DownloadMetadata.h"

const CGFloat kFailedUploadsErrorFontSize = 15.0f;
const CGFloat kFailedUploadsPadding = 10.0f;
const CGFloat kFailedUploadsMarginPadding = 15.0f;
const CGFloat kFailedUploadsCellHeight = 50.0f;
const CGFloat kFailedDefaultDescriptionHeight = 60.0f;

@interface FailedUploadsViewController ()

@end

@implementation FailedUploadsViewController
@synthesize tableView = _tableView;
@synthesize failedUploadsAndDownloads = _failedUploadsAndDownloads;
@synthesize clearButton = _clearButton;
@synthesize viewType = _viewType;

- (void)dealloc
{
    [_tableView release];
    [_failedUploadsAndDownloads release];
    [_clearButton release];
    [super dealloc];
}


- (id)initWithFailedUploads:(NSArray *)failedUploadsAndDownloads
{
    self = [super init];
    if(self)
    {
        [self setFailedUploadsAndDownloads:failedUploadsAndDownloads];
    }
    return self;
}

#pragma  mark - View life cycle
- (void)loadView
{
    UIColor *backgroundColor = [UIColor colorWithHexRed:213 green:216 blue:222 alphaTransparency:1.0f];
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    [containerView setBackgroundColor:backgroundColor];
    [containerView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(kFailedUploadsMarginPadding, kFailedUploadsMarginPadding, 290, 391) style:UITableViewStylePlain];

    [tableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [tableView setBackgroundColor:[UIColor whiteColor]];

    [tableView setDelegate:self];
    [tableView setDataSource:self];
    [tableView.layer setMasksToBounds:YES];
    [tableView.layer setCornerRadius:10.0f];
    [tableView.layer setBorderWidth:1.2f];
    [tableView.layer setBorderColor:[[UIColor lightGrayColor] CGColor]];
    
    UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [clearButton setTitle:NSLocalizedString(@"failed-uploads.cell.clear-list", @"Clear List") forState:UIControlStateNormal];
    [clearButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    //Default font size to mimic a cell: [UIFont labelFontSize]+1]
    [clearButton.titleLabel setFont:[UIFont boldSystemFontOfSize:[UIFont labelFontSize]+1]];
    [clearButton setAutoresizingMask:UIViewAutoresizingFlexibleWidth ];
    [clearButton setFrame:CGRectMake(kFailedUploadsMarginPadding, kFailedUploadsMarginPadding, 290, 44)];
    [clearButton addTarget:self action:@selector(clearButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    UIImage *buttonTemplate = [UIImage imageNamed:@"red-button"];
    UIImage *stretchedButtonImage = [buttonTemplate resizableImageWithCapInsets:UIEdgeInsetsMake(7.0f, 5.0f, 7.0f, 5.0f)];
    [clearButton setBackgroundImage:stretchedButtonImage forState:UIControlStateNormal];
    [self setClearButton:clearButton];

    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 406, 320, 74)];
    [footerView setBackgroundColor:backgroundColor];
    [footerView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin];
    [footerView addSubview:clearButton];
    [containerView addSubview:footerView];
    [footerView release];

    
    [containerView addSubview:tableView];
    
    [self setView:containerView];
    [containerView release];
    [tableView release];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[Theme setThemeForUINavigationController:[self navigationController]];
    
    if(self.viewType == FailedUploadsViewTypeSync)
    {
        if([self.failedUploadsAndDownloads count] == 1)
        {
            [self setTitle:NSLocalizedString(@"failed-sync.title", @"1 Failed Sync")];
        }
        else 
        {
            [self setTitle:[NSString stringWithFormat:NSLocalizedString(@"failed-sync.title.plural", @"%d Failed Sync"), [self.failedUploadsAndDownloads count]]];
        }
    }
    else 
    {
        
        if([self.failedUploadsAndDownloads count] == 1)
        {
            [self setTitle:NSLocalizedString(@"failed-uploads.title", @"1 Failed Upload")];
        }
        else 
        {
            [self setTitle:[NSString stringWithFormat:NSLocalizedString(@"failed-uploads.title.plural", @"%d Failed Uploads"), [self.failedUploadsAndDownloads count]]];
        }
    }
    
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"") style:UIBarButtonItemStyleBordered target:self action:@selector(closeButtonAction:)];
    [self.navigationItem setLeftBarButtonItem:closeButton];
    [closeButton release];
    
    UIBarButtonItem *retryButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Retry All", @"Retry all failed uploads") style:UIBarButtonItemStyleBordered target:self action:@selector(retryButtonAction:)];
    [self.navigationItem setRightBarButtonItem:retryButton];
    [retryButton release];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma  mark - TableView Delegate & Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.failedUploadsAndDownloads count];

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RepositoryItemTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:RepositoryItemCellIdentifier];
    if(!cell)
    {
        NSArray *nibItems = [[NSBundle mainBundle] loadNibNamed:@"RepositoryItemTableViewCell" owner:self options:nil];
		cell = [nibItems objectAtIndex:0];
        
        // Adding the error badge at the left of the description view
        UIImage *errorBadge = [UIImage imageNamed:kImageUIButtonBarBadgeError];
        UIImageView *badgeView = [[UIImageView alloc] initWithImage:errorBadge];
        CGRect badgeRect = [badgeView frame];
        badgeRect.origin.x = kTableCellTextLeftPadding;
        badgeRect.origin.y = kDefaultTableCellHeight;
        [badgeView setFrame:badgeRect];
        [badgeView setAutoresizingMask:UIViewAutoresizingNone];
        [cell.contentView addSubview:badgeView];
        [badgeView release];
        
        //Adding the error description label
        CGFloat errorPadding = kFailedUploadsPadding / 2;
        UILabel *errorLabel = [[UILabel alloc] initWithFrame:CGRectMake(kTableCellTextLeftPadding + badgeRect.size.width + errorPadding, kDefaultTableCellHeight, cell.contentView.frame.size.width - kTableCellTextLeftPadding - badgeRect.size.width - errorPadding - kFailedUploadsPadding, kFailedDefaultDescriptionHeight)];
        [errorLabel setNumberOfLines:0];
        [errorLabel setLineBreakMode:UILineBreakModeWordWrap];
        [errorLabel setTextColor:[UIColor blackColor]];
        [errorLabel setFont:[UIFont systemFontOfSize:kFailedUploadsErrorFontSize]];
        [errorLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight];
        [errorLabel setTag:100];
        [cell.contentView addSubview:errorLabel];
        [errorLabel release];
        
        [cell setAccessoryType:UITableViewCellAccessoryNone];
        [cell setSelectionStyle:UITableViewCellAccessoryNone];
    }
    //Error label text setting
    UILabel *errorLabel = (UILabel *)[cell.contentView viewWithTag:100];
    
    //Setting up the cell for the current upload
    id item = [self.failedUploadsAndDownloads objectAtIndex:indexPath.row];
    if([item isKindOfClass:[UploadInfo class]])
    {
        UploadInfo *uploadInfo = (UploadInfo *) item;
        [cell.filename setText:[uploadInfo completeFileName]];
        [cell.details setText:[NSString stringWithFormat:NSLocalizedString(@"failed-uploads.detailSubtitle", @"Uploading to: %@"), uploadInfo.folderName]];
        [cell.image setImage:imageForFilename([uploadInfo.uploadFileURL lastPathComponent])];
        
        [errorLabel setText:[uploadInfo.error localizedDescription]];
    }
    else if ([item isKindOfClass:[DownloadInfo class]])
    {
        DownloadInfo *downloadInfo = (DownloadInfo *) item;
        [cell.filename setText:[[downloadInfo downloadMetadata] filename]];
        [cell.details setText:[NSString stringWithFormat:NSLocalizedString(@"failed-sync.detailSubtitle", @"Downloading to: %@"), [UIDevice currentDevice].model]];
        [cell.image setImage:imageForFilename([downloadInfo.downloadFileURL lastPathComponent])];
        
        [errorLabel setText:[downloadInfo.error localizedDescription]];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Error label resizing
    UILabel *errorLabel = (UILabel *)[cell.contentView viewWithTag:100];
    CGRect errorFrame = errorLabel.frame;
    CGSize fitSize = [errorLabel sizeThatFits:errorFrame.size];
    errorFrame.size.height = fitSize.height;
    [errorLabel setFrame:errorFrame];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize errorLabelSize = CGSizeZero;
    
    id item = [self.failedUploadsAndDownloads objectAtIndex:indexPath.row];
    
    if([item isKindOfClass:[UploadInfo class]])
    {
        UploadInfo *uploadInfo = (UploadInfo *) item;
        CGSize cellSize = CGSizeMake(tableView.frame.size.width - kTableCellTextLeftPadding - (kFailedUploadsPadding * 4), CGFLOAT_MAX);
        errorLabelSize = [[uploadInfo.error localizedDescription] sizeWithFont:[UIFont systemFontOfSize:kFailedUploadsErrorFontSize] constrainedToSize:cellSize];
    }
    else if ([item isKindOfClass:[DownloadInfo class]])
    {
        DownloadInfo *downloadInfo = (DownloadInfo *) item;
        CGSize cellSize = CGSizeMake(tableView.frame.size.width - kTableCellTextLeftPadding - (kFailedUploadsPadding * 4), CGFLOAT_MAX);
        errorLabelSize = [[downloadInfo.error localizedDescription] sizeWithFont:[UIFont systemFontOfSize:kFailedUploadsErrorFontSize] constrainedToSize:cellSize];
    }
    
    // The height of the error description label, the default title and subtitle and a bottom padding
    return errorLabelSize.height + kDefaultTableCellHeight + kFailedUploadsPadding;

}

#pragma mark - Button actions
- (void)retryButtonAction:(id)sender
{
    for(id item in self.failedUploadsAndDownloads)
    {
        //Changing the CreateDocument Type to Document to avoid trying to
        //present a document created.
        //This can happen rarely (a create document upload must fail and then the app is terminated
        //without cancelling the document creation)
        
        if([item isKindOfClass:[UploadInfo class]])
        {
            UploadInfo *uploadInfo = (UploadInfo *) item;
            if([uploadInfo uploadType] == UploadFormTypeCreateDocument)
            {
                [uploadInfo setUploadType:UploadFormTypeDocument];
            }
            [[UploadsManager sharedManager] retryUpload:uploadInfo.uuid];
        }
        else if([item isKindOfClass:[DownloadInfo class]])
        {
           // DownloadInfo *downloadInfo = (DownloadInfo *) item;
            
            //[[DownloadManager sharedManager] retryUpload:uploadInfo.uuid];
            
        }
    }
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void)closeButtonAction:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)clearButtonAction:(id)sender
{
    NSMutableArray *uploadUuids = [[NSMutableArray alloc] init];
    for(id item in self.failedUploadsAndDownloads)
    {
        if([item isKindOfClass:[UploadInfo class]])
        {
            UploadInfo * uploadInfo = (UploadInfo *) item;
            [uploadUuids addObject:[uploadInfo uuid]];
        }
    }
    [[UploadsManager sharedManager] clearUploads:uploadUuids];
    
    [uploadUuids release];
    
    [self dismissModalViewControllerAnimated:YES];
}

@end
