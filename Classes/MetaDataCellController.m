//
//  MetaDataCellController.m
//  FreshDocs
//
//  Created by Gi Hyun Lee on 7/18/11.
//  Copyright 2011 Zia Consulting. All rights reserved.
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
		cell = [[[IFControlTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellIdentifier] autorelease];
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
