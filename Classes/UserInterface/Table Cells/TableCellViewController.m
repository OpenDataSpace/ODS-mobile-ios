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
//  TableCellViewController.m
//

#import "TableCellViewController.h"

const CGFloat maxtFontSize = 18.0f;
const CGFloat minFontSize = 8.0f;
const CGFloat kDefaultTextLabelSize = 20.0f;
const CGFloat kDefaultDetailTextLabelSize = 14.0f;

@implementation TableCellViewController
@synthesize target = _target;
@synthesize action = _action;
@synthesize shouldResizeTextToFit = _shouldResizeTextToFit;
@synthesize indexPath = _indexPath;
@synthesize model = _model;
@synthesize cellHeight = _cellHeight;
@synthesize tag = _tag;
@synthesize cellStyle = _cellStyle;
@synthesize accessoryType = _accessoryType;
@synthesize selectionStyle = _selectionStyle;
@synthesize backgroundColor = _backgroundColor;
@synthesize backgroundView = _backgroundView;
@synthesize imageView = _imageView;
@synthesize textLabel = _textLabel;
@synthesize detailTextLabel = _detailTextLabel;

-(void)dealloc 
{
    [_indexPath release];
    [_model release];
    [_backgroundColor release];
    [_backgroundView release];
    [_imageView release];
    [_textLabel release];
    [_detailTextLabel release];
    
    [super dealloc];
}

- (id)init
{
	self = [super init];
	if (self != nil)
	{
        [self setCellStyle:UITableViewCellStyleSubtitle];
        [self setCellHeight:kDefaultTableCellHeight];
        _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _detailTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [self.textLabel setFont:[UIFont boldSystemFontOfSize:kDefaultTextLabelSize]];
        [self.detailTextLabel setFont:[UIFont systemFontOfSize:kDefaultDetailTextLabelSize]];
	}
	return self;
}

- (id)initWithAction:(SEL)newAction onTarget:(id)newTarget withModel:(IFTemporaryModel *)tmpModel
{
	self = [super init];
	if (self != nil)
	{
        [self setCellStyle:UITableViewCellStyleSubtitle];
		[self setAction:newAction];
		[self setTarget:newTarget];
        [self setModel:tmpModel];
        [self setCellHeight:kDefaultTableCellHeight];
        _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _detailTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [self.textLabel setFont:[UIFont boldSystemFontOfSize:kDefaultTextLabelSize]];
        [self.detailTextLabel setFont:[UIFont boldSystemFontOfSize:kDefaultDetailTextLabelSize]];
	}
	return self;
}

- (id)initWithAction:(SEL)newAction onTarget:(id)newTarget
{
	self = [super init];
	if (self != nil)
	{
        [self setCellStyle:UITableViewCellStyleSubtitle];
		[self setAction:newAction];
		[self setTarget:newTarget];
        [self setCellHeight:kDefaultTableCellHeight];
        _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _detailTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [self.textLabel setFont:[UIFont boldSystemFontOfSize:kDefaultTextLabelSize]];
        [self.detailTextLabel setFont:[UIFont systemFontOfSize:kDefaultDetailTextLabelSize]];
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
		if (_target && [_target respondsToSelector:_action])
		{
			[_target performSelector:_action withObject:self];
		}
        if ([self accessoryType] == UITableViewCellAccessoryNone)
        {
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
	NSString *cellIdentifier = [self cellIdentifier];
    
    if ([tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    [self setIndexPath:newIndexPath];
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
        cell = [self createTableViewCell];
    }
    
    [cell setAccessoryType:self.accessoryType];
    [cell setSelectionStyle:self.selectionStyle];
    [cell.imageView setImage:self.imageView.image];

    [cell.textLabel setText:self.textLabel.text];
    AlfrescoLogTrace(@"Default font size: %f", cell.textLabel.font.pointSize);
    [cell.textLabel setFont:self.textLabel.font];
    [cell.textLabel setTextColor:self.textLabel.textColor];
    [cell.detailTextLabel setFont:self.detailTextLabel.font];
    
    [cell.detailTextLabel setText:self.detailTextLabel.text];
    [cell.detailTextLabel setTextColor:self.detailTextLabel.textColor];
    [cell.textLabel setAdjustsFontSizeToFitWidth:[self.textLabel adjustsFontSizeToFitWidth]];
    
    if(self.backgroundColor) {
        [cell setBackgroundColor:self.backgroundColor];  
    }
    
    if(self.backgroundView) {
        [cell setBackgroundView:self.backgroundView];
    }
	
    return cell;
}

- (UITableViewCell *)createTableViewCell
{
    return [[[UITableViewCell alloc] initWithStyle:self.cellStyle reuseIdentifier:[self cellIdentifier]] autorelease];
}

//
// tableView:accessoryButtonTappedForRowWithIndexPath
//
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	if (_target && [_target respondsToSelector:_action])
	{
		[_target performSelector:_action];
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return self.cellHeight;
}

- (NSString *)cellIdentifier
{
    return @"TableCellViewController";
}

@end
