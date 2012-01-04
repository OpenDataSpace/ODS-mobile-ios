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
//  TableCellViewController.m
//

#import "TableCellViewController.h"

@interface TableCellViewController (private)
- (void) resizeTextToFit;
@end

const CGFloat maxtFontSize = 18.0f;
const CGFloat minFontSize = 8.0f;

@implementation TableCellViewController
@synthesize target;
@synthesize action;
@synthesize shouldResizeTextToFit;
@synthesize indexPath;
@synthesize model;
@synthesize cellHeight;
@synthesize attributedLabel;

-(void)dealloc 
{
    [indexPath release];
    [model release];
    
    [super dealloc];
}

- (id)initWithAction:(SEL)newAction onTarget:(id)newTarget withModel:(IFTemporaryModel *)tmpModel
{
	self = [super init];
	if (self != nil)
	{
		action = newAction;
		target = newTarget;
        model = [tmpModel retain];
        cellHeight = kDefaultTableCellHeight;
	}
	return self;
}

- (id)initWithAction:(SEL)newAction onTarget:(id)newTarget
{
	self = [super init];
	if (self != nil)
	{
		action = newAction;
		target = newTarget;
        cellHeight = kDefaultTableCellHeight;
	}
	return self;
}

//
// tableView:didSelectRowAtIndexPath:
//
// Handle row selection
//
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath
{
	if ([self accessoryType] != UITableViewCellAccessoryDetailDisclosureButton)
	{
		if (target && [target respondsToSelector:action])
		{
			[target performSelector:action withObject:self];
		} else {
            [tableView deselectRowAtIndexPath:newIndexPath animated:YES];
        }
	} else {
        [tableView deselectRowAtIndexPath:newIndexPath animated:YES];
    }
}

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)newIndexPath
{
	static NSString *cellIdentifier = @"TableCellViewController";
    
    [self setIndexPath:newIndexPath];
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }
    
    cell.accessoryType = self.accessoryType;
    cell.selectionStyle = self.selectionStyle;
    cell.imageView.image = self.imageView.image;
    
    if(!attributedLabel) {
        cell.textLabel.font = self.textLabel.font;
        cell.textLabel.text = self.textLabel.text;
        cell.textLabel.textColor = self.textLabel.textColor;
        cell.detailTextLabel.font = self.detailTextLabel.font;
        cell.detailTextLabel.text = self.detailTextLabel.text;
        cell.detailTextLabel.textColor = self.detailTextLabel.textColor;
        [cell.textLabel setAdjustsFontSizeToFitWidth:[self.textLabel adjustsFontSizeToFitWidth]];
    } else {
        CGRect labelFrame = CGRectMake(0, 0, 320, cellHeight);
        [attributedLabel setFrame:labelFrame];
        [attributedLabel setAutoresizingMask:cell.textLabel.autoresizingMask];
        [cell addSubview:attributedLabel];
    }
    
    if(self.backgroundColor) {
        cell.backgroundColor = self.backgroundColor;  
    }
    
    if(self.backgroundView) {
        cell.backgroundView = self.backgroundView;
    }
	
    return cell;
}

//
// tableView:accessoryButtonTappedForRowWithIndexPath
//
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	if (target && [target respondsToSelector:action])
	{
		[target performSelector:action];
	}
}

- (void)resizeTextToFit {
    if(self.textLabel.font.pointSize == 0) {
        userFontSize = maxtFontSize;
    } else if(userFontSize == 0) {
        userFontSize = self.textLabel.font.pointSize;
    }
    
    // Changing the font size for the case the cell is going to be reused between
    // a resizable text and a normal text for the label
    self.textLabel.font = [UIFont boldSystemFontOfSize:userFontSize];
    
    if(shouldResizeTextToFit) {
        CGSize labelSize = [self.textLabel.text sizeWithFont:self.textLabel.font];
        CGFloat indent = ((self.indentationLevel + 1) * self.indentationWidth) * 2;
        
        while(labelSize.width + indent > self.contentView.frame.size.width && self.textLabel.font.pointSize >= minFontSize) {
            self.textLabel.font = [self.textLabel.font fontWithSize:(self.textLabel.font.pointSize - 1)];
            
            labelSize = [self.textLabel.text sizeWithFont:self.textLabel.font];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return cellHeight;
}

@end
