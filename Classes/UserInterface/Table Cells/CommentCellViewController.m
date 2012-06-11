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
//  CommentCellViewController.m
//

#import "CommentCellViewController.h"
#import "CommentTableViewCell.h"
#import "UIColor+Theme.h"

@implementation CommentCellViewController

@synthesize createDate;
@synthesize createDateFont;

#define CONST_Cell_height 44.0f
#define CONST_textLabelFontSize 11
#define CONST_detailLabelFontSize 15

CGSize createDateSize = {0.0f, 0.0f};

- (void) dealloc {
    [createDate release];
    [createDateFont release];
    [super dealloc];
}

- (id)initWithTitle:(NSString *)newTitle 
      withSubtitle:(NSString *)newSubtitle
      andCreateDate:(NSString *)newCreateDate
            inModel:(id<IFCellModel>)newModel
{
    self = [super initWithTitle:newTitle andSubtitle:newSubtitle inModel:newModel];
	if (self != nil) {
        createDate = [newCreateDate retain];
	}
	return self;
}

- (UIFont *) titleFont {
	
	if (titleFont == nil) self.titleFont = [UIFont boldSystemFontOfSize:CONST_textLabelFontSize];
	return titleFont;
	
}

- (UIFont *) createDateFont {
	if (createDateFont == nil) self.createDateFont = [UIFont systemFontOfSize:CONST_textLabelFontSize];
	return createDateFont;
	
}

- (UIColor *) titleTextColor {
	if(titleTextColor == nil) self.titleTextColor = [UIColor colorWithHexRed:108.0f green:108.0f blue:108.0f alphaTransparency:108.0f];
	return titleTextColor;
	
}

- (NSString *) cellIdentifier {
	return kCommentCellIdentifier;
}

- (UITableViewCell *) createCell {
    CommentTableViewCell *cell = [[[CommentTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:[self cellIdentifier]] autorelease];
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.font = [self titleFont];
    
    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.font = [self subTitleFont];
    
    cell.createdDateLabel.numberOfLines = 0;
    cell.createdDateLabel.font = [self createDateFont];
    
    return cell;
}

- (CGSize) titleSize:(CGFloat)maxWidth andMaxHeight:(CGFloat)maxHeight {
    CGSize finalSize = {0.0f, 0.0f};
    
    if ([title length] > 0 && !([createDate length] > 0)) {
        finalSize = [super titleSize:maxWidth andMaxHeight:maxHeight];
    } else if([title length] > 0 && [createDate length] > 0) {
        CGSize titleSize = {0.0f, 0.0f};
        
        createDateSize = [createDate sizeWithFont:[self createDateFont] 
                           constrainedToSize:CGSizeMake(maxWidth, maxHeight) 
                               lineBreakMode:UILineBreakModeWordWrap];
        
		titleSize = [title sizeWithFont:[self titleFont] 
					  constrainedToSize:CGSizeMake(maxWidth, maxHeight) 
						  lineBreakMode:UILineBreakModeWordWrap];
        
        CGFloat width = createDateSize.width + titleSize.width; 
        CGFloat height = MAX(createDateSize.height, titleSize.height); 
        finalSize = CGSizeMake(width, height);
    }
    
    return finalSize;
}

- (void) populateCell: (UITableViewCell *) cell{
    CommentTableViewCell * typedCell = (CommentTableViewCell *) cell;
    typedCell.textLabel.text = title;
	typedCell.textLabel.textColor = self.titleTextColor;
	typedCell.detailTextLabel.text = subtitle;
	typedCell.detailTextLabel.textColor = self.subtitleTextColor;
    
    if([createDate length] > 0) {
        typedCell.createdDateLabel.text = createDate;
        typedCell.createdDateLabel.textColor = self.titleTextColor;
    }
}

@end
