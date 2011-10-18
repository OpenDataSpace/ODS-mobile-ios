//
//  RepositoryNodeViewController.h
//  Alfresco
//
//  Created by Michael Muller on 9/1/09.
//  Copyright 2009 Zia Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DownloadProgressBar.h"
#import "PostProgressBar.h"
#import "FolderItemsDownload.h"

@interface RepositoryNodeViewController : UITableViewController <DownloadProgressBarDelegate, PostProgressBarDelegate, AsynchronousDownloadDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> 
{
	NSString *guid;
	FolderItemsDownload *folderItems;
	DownloadProgressBar *downloadProgressBar;
	PostProgressBar     *postProgressBar;
	FolderItemsDownload *itemDownloader;
	NSData              *contentStream;
	UIPopoverController *popover;

	UITextField *alertField;
	BOOL replaceData;
}

@property (nonatomic, retain) NSString *guid;
@property (nonatomic, retain) FolderItemsDownload *folderItems;
@property (nonatomic, retain) DownloadProgressBar *downloadProgressBar;
@property (nonatomic, retain) PostProgressBar     *postProgressBar;
@property (nonatomic, retain) FolderItemsDownload *itemDownloader;
@property (nonatomic, retain) NSData              *contentStream;
@property (nonatomic, retain) UIPopoverController *popover;
@property (nonatomic, retain) UITextField *alertField;

- (void)metaDataChanged;
@end
