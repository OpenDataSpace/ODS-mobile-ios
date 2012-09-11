//
//  AbstractDocumentsNavigationController.h
//  FreshDocs
//
//  Created by Mohamad Saeedi on 07/09/2012.
//  Copyright (c) 2012 U001b. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ASIProgressDelegate.h"
#import "ProgressPanelView.h"
#import "UploadsManager.h"
#import "FileUtils.h"
#import "FailurePanelView.h"
#import "CustomBadge.h"
#import "UploadInfo.h"
#import "FailedUploadsViewController.h"
#import "DetailNavigationController.h"
#import "AlfrescoAppDelegate.h"

@interface AbstractDocumentsNavigationController : UINavigationController <UINavigationControllerDelegate, ASIProgressDelegate, UIAlertViewDelegate>
{
    BOOL _isProgressPanelHidden;
    BOOL _isFailurePanelHidden;
    /*
     Flag to track the show/hide state of the panels
     */
    BOOL _externalHidden;
}

/*
 Allows to show or hide panels by external objects
 */
- (void)showPanels;
- (void)hidePanels;



@property (nonatomic, retain) ProgressPanelView *progressPanel;
@property (nonatomic, retain) FailurePanelView *failurePanel;

- (void)positionProgressPanel;
- (void)showProgressPanel;
- (void)hideProgressPanel;

- (void)positionFailurePanel;
- (void)showFailurePanel;
- (void)hideFailurePanel;

- (void)updateFailedUploads;
- (void)updateTabItemBadge;

- (NSString *)itemText:(NSInteger)itemsCount;


@end
