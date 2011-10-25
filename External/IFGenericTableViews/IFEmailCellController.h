//
//  ***** BEGIN LICENSE BLOCK *****
//  Version: MPL 1.1
//
//  The contents of this file are subject to the Mozilla Public License Version
//  1.1 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS" basis,
//  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
//  for the specific language governing rights and limitations under the
//  License.
//
//  The Original Code is the Alfresco Mobile App.
//  The Initial Developer of the Original Code is Zia Consulting, Inc.
//  Portions created by the Initial Developer are Copyright (C) 2011
//  the Initial Developer. All Rights Reserved.
//
//
//  ***** END LICENSE BLOCK *****
//
//
//  IFEmailCellController.h
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
