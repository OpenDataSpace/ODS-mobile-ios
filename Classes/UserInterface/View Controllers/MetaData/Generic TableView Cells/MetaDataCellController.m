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
//  MetaDataCellController.m
//

#import "MetaDataCellController.h"

#import "IFControlTableViewCell.h"
#import "MetaDataCell.h"
#import "Utility.h"

@implementation MetaDataCellController
@synthesize indentationLevel;
@synthesize propertyType;

//
// dealloc
//
// Releases instance memory.
//
- (void)dealloc
{
	[label release];
	[key release];
	[model release];
    [propertyType release];
	
	[super dealloc];
}

//
// init
//
// Init methods for the object.
//
- (id)initWithLabel:(NSString *)newLabel atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel
{
	return [self initWithLabel:newLabel atKey:newKey withURL:nil inModel:newModel];
}

- (id)initWithLabel:(NSString *)newLabel atKey:(NSString *)newKey withURL:(NSURL *)newURL inModel:(id<IFCellModel>)newModel
{
	self = [super init];
	if (self != nil)
	{
		label = [newLabel retain];
		key = [newKey retain];
		model = [newModel retain];
		
		indentationLevel = 0;
	}
	return self;
}

//
// tableView:didSelectRowAtIndexPath:
//
// Handle row selection
//
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"DataDataCell";

    IFControlTableViewCell *cell = (IFControlTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
		cell = [[[IFControlTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }
	
	[cell setAccessoryType:UITableViewCellAccessoryNone];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [cell setIndentationLevel:indentationLevel];
    
	// NOTE: The documentation states that the indentation width is 10 "points". It's more like 20
	// pixels and changing the property has no effect on the indentation. We'll use 20.0f here
	// and cross our fingers that this doesn't screw things up in the future.	
    
    MetaDataCell *cellView;
    // TODO: MetaDataCell needs to handle indentation levels

	if (nil == cell.view) {
        CGFloat viewWidth = 280.0f - (20.0f * indentationLevel);
        CGRect frame = CGRectMake(0.0f, 0.0f, viewWidth, 22.0f);
        NSArray* nibViews =  [[NSBundle mainBundle] loadNibNamed:@"MetaDataCell" owner:self options:nil];
        cellView = (MetaDataCell *)[nibViews objectAtIndex:0];
        [cellView setFrame:frame];
        [cell setView:cellView];
	} else {
        cellView = (MetaDataCell *)cell.view;
	}
	
    id value = [model objectForKey:key];
	NSString *valueText = @"";
	if (nil == value) {
		valueText = @"";
	}
	else if ([value isKindOfClass:[NSString class]])
	{
		valueText = value;
	}
	else if ([value isKindOfClass:[NSNumber class]])
	{
		valueText = [value stringValue];
	} 
    
    if ([self.propertyType isEqualToString:@"datetime"]) {
        valueText = formatDateTime(valueText);
    }
	
    [cellView.metadataLabel setText:label];
	[cellView.metaDataValueText setText:valueText];
	
    return cell;
}

@end
