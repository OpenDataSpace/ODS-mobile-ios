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
 * Portions created by the Initial Developer are Copyright (C) 2011
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  IFPhotoCellController.h
//

#import <UIKit/UIKit.h>

#import "IFControlTableViewCell.h"
#import "IFCellController.h"
#import "IFCellFirstResponder.h"
#import "IFCellModel.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
#define IS_IPAD ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
#endif

@interface IFPhotoCellController : NSObject <IFCellController, IFCellControllerFirstResponder, UIImagePickerControllerDelegate, UINavigationControllerDelegate,UIActionSheetDelegate> {
	NSString *label;
	id<IFCellModel> model;
	NSString *key;
	
	UIColor *backgroundColor;
	UITableViewCellSelectionStyle selectionStyle;
    UITableViewCellAccessoryType accessoryType;
	
	SEL updateAction;
	id updateTarget;
	
	NSInteger indentationLevel;
	
	UITableViewController *tableController;
	NSIndexPath *cellIndexPath;
	id<IFCellControllerFirstResponderHost>cellControllerFirstResponderHost;
	
	BOOL autoAdvance;
	CGFloat maxWidth;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	// UIPopoverController *
	id popover;
#endif
}

@property (nonatomic, retain) UIColor *backgroundColor;
@property (nonatomic, assign) UITableViewCellSelectionStyle selectionStyle;
@property (nonatomic, assign) UITableViewCellAccessoryType accessoryType;

@property (nonatomic, assign) SEL updateAction;
@property (nonatomic, assign) id updateTarget;

@property (nonatomic, assign) NSInteger indentationLevel;

@property (nonatomic, retain) UITableViewController *tableController;
@property (nonatomic, retain) NSIndexPath *cellIndexPath;
@property (nonatomic, assign) id<IFCellControllerFirstResponderHost>cellControllerFirstResponderHost;
@property (nonatomic, assign) CGFloat maxWidth;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
@property (nonatomic, retain) id popover;
#endif

- (id)initWithLabel:(NSString *)newLabel atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel;
- (CGFloat)imageHeightToWidthRatio:(UIImage *)image;

@end
