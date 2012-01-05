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
//  TableCellViewController.h
//
//  It extends the functionality of IFButtonCellController
//  But the implementation is an actual UITableCellView so, we have direct access
//  to its properties but it also acts a GenericTableCellViewController
//

#import <Foundation/Foundation.h>
#import "IFCellController.h"
#import "IFTemporaryModel.h"
#import "TTTAttributedLabel.h"

@interface TableCellViewController : NSObject <IFCellController>

@property (nonatomic, assign) SEL action;
@property (nonatomic, assign) id target;
@property (nonatomic, assign) BOOL shouldResizeTextToFit;
@property (nonatomic, retain) NSIndexPath *indexPath;
@property (nonatomic, retain) IFTemporaryModel *model;
@property (nonatomic, assign) CGFloat cellHeight;
@property (nonatomic, assign) NSInteger tag;
//UITableViewCell 
@property (nonatomic, assign) UITableViewCellAccessoryType accessoryType;
@property (nonatomic, assign) UITableViewCellSelectionStyle selectionStyle;
@property (nonatomic, retain) UIColor *backgroundColor;
@property (nonatomic, retain) UIView *backgroundView;
@property (nonatomic, readonly) UIImageView *imageView;
@property (nonatomic, readonly) UILabel *textLabel;
@property (nonatomic, readonly) UILabel *detailTextLabel;

- (id)initWithAction:(SEL)newAction onTarget:(id)newTarget;
- (id)initWithAction:(SEL)newAction onTarget:(id)newTarget withModel:(IFTemporaryModel *)tmpModel;

@end
