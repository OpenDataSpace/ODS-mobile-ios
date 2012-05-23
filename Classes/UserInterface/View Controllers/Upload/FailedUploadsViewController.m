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

#import "FailedUploadsViewController.h"
#import "UploadInfo.h"
#import "Utility.h"
#import "RepositoryItemTableViewCell.h"
#import "UploadsManager.h"

const CGFloat kFailedUploadsErrorFontSize = 16.0f;
const CGFloat kFailedUploadsPadding = 10.0f;
const CGFloat kFailedUploadsCellHeight = 50.0f;

@interface FailedUploadsViewController ()

@end

@implementation FailedUploadsViewController
@synthesize tableView = _tableView;
@synthesize failedUploads = _failedUploads;
@synthesize titleLabel = _titleLabel;
@synthesize clearButton = _clearButton;
@synthesize dismissButton = _dismissButton;

- (void)dealloc
{
    [_tableView release];
    [_failedUploads release];
    [_titleLabel release];
    [_clearButton release];
    [_dismissButton release];
    [super dealloc];
}


- (id)initWithFailedUploads:(NSArray *)failedUploads
{
    self = [super init];
    if(self)
    {
        [self setFailedUploads:failedUploads];
    }
    return self;
}

#pragma  mark - View life cycle
- (void)loadView
{
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    [containerView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [containerView setBackgroundColor:[UIColor whiteColor]];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 40, 320, 390) style:UITableViewStyleGrouped];
    UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 40, 320, 390)];
    [backgroundView setBackgroundColor:[UIColor whiteColor]];
    [tableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [tableView setBackgroundColor:[UIColor whiteColor]];
    [tableView setBackgroundView:backgroundView];
    [tableView setDelegate:self];
    [tableView setDataSource:self];
    [backgroundView release];
    
    //Title Header section
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    [title setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [title setFont:[UIFont boldSystemFontOfSize:20.0f]];
    [title setTextAlignment:UITextAlignmentCenter];
    [title setBackgroundColor:[UIColor whiteColor]];
    if([self.failedUploads count] == 1)
    {
        [title setText:NSLocalizedString(@"failed-uploads.title", @"1 Failed Upload")];
    }
    else 
    {
        [title setText:[NSString stringWithFormat:NSLocalizedString(@"failed-uploads.title.plural", @"%d Failed Uploads"), [self.failedUploads count]]];
    }
    
    [containerView addSubview:title];
    [self setTitleLabel:title];
    [title release];
    
    // Clear and dismiss footer section
    UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [clearButton setTitle:NSLocalizedString(@"Clear", @"Clear") forState:UIControlStateNormal];
    [clearButton setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin ];
    [clearButton setFrame:CGRectMake(kFailedUploadsPadding, kFailedUploadsPadding, 145, 30)];
    [clearButton addTarget:self action:@selector(clearButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self setClearButton:clearButton];
    
    UIButton *dismissButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [dismissButton setTitle:NSLocalizedString(@"Dismiss", @"Dismiss") forState:UIControlStateNormal];
    [dismissButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth];
    [dismissButton setFrame:CGRectMake((kFailedUploadsPadding * 2) + clearButton.frame.size.width, kFailedUploadsPadding, 145, 30)];
    [dismissButton addTarget:self action:@selector(dismissButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self setDismissButton:dismissButton];
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 430, 320, 50)];
    [footerView setBackgroundColor:[UIColor whiteColor]];
    [footerView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin];
    [footerView addSubview:clearButton];
    [footerView addSubview:dismissButton];
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
	// Do any additional setup after loading the view.
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.failedUploads count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RepositoryItemTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:RepositoryItemCellIdentifier];
    if(!cell)
    {
        NSArray *nibItems = [[NSBundle mainBundle] loadNibNamed:@"RepositoryItemTableViewCell" owner:self options:nil];
		cell = [nibItems objectAtIndex:0];
        
        //Adding the error description label
        UILabel *errorLabel = [[UILabel alloc] initWithFrame:CGRectMake(kFailedUploadsPadding, kDefaultTableCellHeight, cell.contentView.frame.size.width - (kFailedUploadsPadding * 2), 60)];
        [errorLabel setNumberOfLines:0];
        [errorLabel setLineBreakMode:UILineBreakModeWordWrap];
        [errorLabel setBackgroundColor:[UIColor clearColor]];
        [errorLabel setTextColor:[UIColor blackColor]];
        [errorLabel setFont:[UIFont systemFontOfSize:kFailedUploadsErrorFontSize]];
        [errorLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight];
        [errorLabel setTag:100];
        [cell.contentView addSubview:errorLabel];
        [errorLabel release];
        
        [cell setAccessoryType:UITableViewCellAccessoryNone];
        [cell setSelectionStyle:UITableViewCellAccessoryNone];
    }
    
    //Setting up the cell for the current upload
    UploadInfo *uploadInfo = [self.failedUploads objectAtIndex:indexPath.row];
    [cell.filename setText:[uploadInfo completeFileName]];
    [cell.details setText:[NSString stringWithFormat:NSLocalizedString(@"failed-uploads.detailSubtitle", @"Uploading to: %@"), [uploadInfo folderName]]];
    [cell.image setImage:imageForFilename([uploadInfo.uploadFileURL lastPathComponent])];
    
    //Error label resizing and text setting
    UILabel *errorLabel = (UILabel *)[cell.contentView viewWithTag:100];
    [errorLabel setText:[uploadInfo.error localizedDescription]];
    CGSize cellSize = CGSizeMake(cell.contentView.frame.size.width - (kFailedUploadsPadding * 2), CGFLOAT_MAX);
    CGSize errorLabelSize = [[uploadInfo.error localizedDescription] sizeWithFont:[UIFont systemFontOfSize:kFailedUploadsErrorFontSize] constrainedToSize:cellSize];
    CGRect errorFrame = errorLabel.frame;
    errorFrame.size.height = errorLabelSize.height;
    [errorLabel setFrame:errorFrame];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UploadInfo *uploadInfo = [self.failedUploads objectAtIndex:indexPath.row];
    CGSize cellSize = CGSizeMake(tableView.frame.size.width - (kFailedUploadsPadding * 4), CGFLOAT_MAX);
    CGSize errorLabelSize = [[uploadInfo.error localizedDescription] sizeWithFont:[UIFont systemFontOfSize:kFailedUploadsErrorFontSize] constrainedToSize:cellSize];
    
    // The height of the error description label, the default title and subtitle and a bottom padding
    return errorLabelSize.height + kDefaultTableCellHeight + kFailedUploadsPadding;
}

#pragma mark - Button actions
- (void)dismissButtonAction:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)clearButtonAction:(id)sender
{
    NSMutableArray *uploadUuids = [NSMutableArray arrayWithCapacity:[self.failedUploads count]];
    for(UploadInfo *uploadInfo in self.failedUploads)
    {
        [uploadUuids addObject:[uploadInfo uuid]]; 
    }
    [[UploadsManager sharedManager] clearUploads:uploadUuids];
    
    [self dismissModalViewControllerAnimated:YES];
}

@end
