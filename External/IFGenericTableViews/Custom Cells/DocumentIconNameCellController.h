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
 *
 * ***** END LICENSE BLOCK ***** */

//
//  DocumentIconNameTableViewCell.h
//

#import "IFControlTableViewCell.h"
#import "IFCellController.h"
#import "IFCellModel.h"

@interface DocumentIconNameCellController : NSObject <IFCellController> {
	NSString *label;
	id<IFCellModel> model;
	NSString *key;
    
    UIColor *backgroundColor;
    
    NSString *filename;
	NSInteger indentationLevel;
	
	UITableViewController *tableController;
	NSIndexPath *cellIndexPath;
	
	CGFloat maxWidth;
}

@property (nonatomic, retain) NSString *filename;

@property (nonatomic, retain) UIColor *backgroundColor;
@property (nonatomic, assign) NSInteger indentationLevel;

@property (nonatomic, retain) UITableViewController *tableController;
@property (nonatomic, retain) NSIndexPath *cellIndexPath;
@property (nonatomic, assign) CGFloat maxWidth;

- (id)initWithLabel:(NSString *)newLabel atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel;

@end
