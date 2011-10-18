//
//  UploadFormTableViewController.h
//  FreshDocs
//
//  Created by Gi Hyun Lee on 7/26/11.
//  Copyright 2011 Zia Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IFGenericTableViewController.h"
#import "PostProgressBar.h"
#import "ASIHTTPRequestDelegate.h"
#import "MBProgressHUD.h"


@interface UploadFormTableViewController : IFGenericTableViewController <PostProgressBarDelegate, UIAlertViewDelegate, ASIHTTPRequestDelegate, MBProgressHUDDelegate> 
{
    NSString *upLinkRelation;
    PostProgressBar *postProgressBar;
    UITextField *createTagTextField;
    NSMutableArray *availableTagsArray;
    
	SEL updateAction;
	id updateTarget;
    
    MBProgressHUD *HUD;
    BOOL popViewControllerOnHudHide;
    
    NSArray *existingDocumentNameArray;
}

@property (nonatomic, retain) NSString *upLinkRelation;
@property (nonatomic, retain) PostProgressBar *postProgressBar;
@property (nonatomic, retain) UITextField *createTagTextField;
@property (nonatomic, retain) NSMutableArray *availableTagsArray;

@property (nonatomic, assign) SEL updateAction;
@property (nonatomic, assign) id updateTarget;

@property (nonatomic, retain) NSArray *existingDocumentNameArray;

- (void)cancelButtonPressed;
- (void)saveButtonPressed;
- (void)addNewTagButtonPressed;
- (void)popViewController;
- (void)addAndSelectNewTag:(NSString *)newTag;
@end
