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
#import "Utility.h"
#import "RepositoryItemTableViewCell.h"
#import "UploadsManager.h"
#import "Theme.h"

const CGFloat kFailedUploadsErrorFontSize = 16.0f;
const CGFloat kFailedUploadsPadding = 15.0f;
const CGFloat kFailedUploadsCellHeight = 50.0f;

@interface FailedUploadsViewController ()

@end

@implementation FailedUploadsViewController
@synthesize tableView = _tableView;
@synthesize failedUploads = _failedUploads;
@synthesize clearButton = _clearButton;

- (void)dealloc
{
    [_tableView release];
    [_failedUploads release];
    [_clearButton release];
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
    UIColor *backgroundColor = [UIColor colorWIthHexRed:213 green:216 blue:222 alphaTransparency:1.0f];
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    [containerView setBackgroundColor:backgroundColor];
    [containerView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(kFailedUploadsPadding, kFailedUploadsPadding, 290, 391) style:UITableViewStylePlain];

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
    [clearButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    //Default font size to mimic a cell: [UIFont labelFontSize]+1]
    [clearButton.titleLabel setFont:[UIFont boldSystemFontOfSize:[UIFont labelFontSize]+1]];
    [clearButton setAutoresizingMask:UIViewAutoresizingFlexibleWidth ];
    [clearButton setFrame:CGRectMake(kFailedUploadsPadding, kFailedUploadsPadding, 290, 44)];
    [clearButton addTarget:self action:@selector(clearButtonAction:) forControlEvents:UIControlEventTouchUpInside];
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
    if([self.failedUploads count] == 1)
    {
        [self setTitle:NSLocalizedString(@"failed-uploads.title", @"1 Failed Upload")];
    }
    else 
    {
        [self setTitle:[NSString stringWithFormat:NSLocalizedString(@"failed-uploads.title.plural", @"%d Failed Uploads"), [self.failedUploads count]]];
    }
    
    UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"") style:UIBarButtonItemStyleBordered target:self action:@selector(closeButtonAction:)];
    [self.navigationItem setLeftBarButtonItem:closeButton];
    [closeButton release];
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
- (void)closeButtonAction:(id)sender
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
