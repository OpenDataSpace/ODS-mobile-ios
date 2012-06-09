//
//  FailedDownloadDetailViewController.h
//  FreshDocs
//
//  Created by Mike Hatfield on 07/06/2012.
//  Copyright (c) 2012 . All rights reserved.
//

#import <UIKit/UIKit.h>
@class DownloadInfo;

@interface FailedDownloadDetailViewController : UIViewController

@property (nonatomic, retain) DownloadInfo *downloadInfo;
@property (nonatomic, assign) SEL closeAction;
@property (nonatomic, assign) id closeTarget;

- (id)initWithDownloadInfo:(DownloadInfo *)downloadInfo;

@end
