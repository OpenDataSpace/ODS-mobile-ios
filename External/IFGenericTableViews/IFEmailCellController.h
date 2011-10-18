//
//  IFEmailCellController.h
//  XpenserUtility
//
//  Created by Bindu Wavell on 2/7/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MFMailComposeViewController.h>

#import "IFCellController.h"
#import "IFCellFirstResponder.h"
#import "IFCellModel.h"

@interface IFEmailCellController : NSObject<IFCellController, IFCellControllerFirstResponder, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate> {
	NSString *label;

	NSString *subject;
	NSArray *toRecipients;
	
	UIColor *backgroundColor;
	UITableViewCellSelectionStyle selectionStyle;
	
	SEL updateAction;
	id updateTarget;
	
	NSInteger indentationLevel;
	
	UITableViewController *tableController;
	NSIndexPath *cellIndexPath;
	id<IFCellControllerFirstResponderHost>cellControllerFirstResponderHost;
	
	BOOL autoAdvance;	
}

@property (nonatomic, retain) NSString *subject;
@property (nonatomic, retain) NSArray *toRecipients;

@property (nonatomic, retain) UIColor *backgroundColor;
@property (nonatomic, assign) UITableViewCellSelectionStyle selectionStyle;

@property (nonatomic, assign) SEL updateAction;
@property (nonatomic, assign) id updateTarget;

@property (nonatomic, assign) NSInteger indentationLevel;

@property (nonatomic, retain) UITableViewController *tableController;
@property (nonatomic, retain) NSIndexPath *cellIndexPath;
@property (nonatomic, assign) id<IFCellControllerFirstResponderHost>cellControllerFirstResponderHost;

- (id)initWithLabel:(NSString *)newLabel;

@end
