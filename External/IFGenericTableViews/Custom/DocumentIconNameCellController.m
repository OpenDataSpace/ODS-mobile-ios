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
//  DocumentIconNameTableViewCell.m
//

#import "DocumentIconNameCellController.h"
#import "IFGenericTableViewController.h"
#import "IFControlTableViewCell.h"
#import "Utility.h"

#define kCellHorizontalOffset 8.0f

@implementation DocumentIconNameCellController

@synthesize filename;
@synthesize maxWidth;
@synthesize backgroundColor;
@synthesize indentationLevel;
@synthesize tableController, cellIndexPath;

CGFloat const kDINCCGutter = 10.0f;
#define LABEL_FONT [UIFont boldSystemFontOfSize:17.0f]
#define FILE_FONT [UIFont systemFontOfSize:17.0f]

- (void)dealloc
{
	[label release];
	[key release];
	[model release];
	[filename release];
	[tableController release];
	[cellIndexPath release];
	
	[super dealloc];
}

- (id)initWithLabel:(NSString *)newLabel atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel;
{
	self = [super init];
	if (self != nil)
	{
		label = [newLabel retain];
		key = [newKey retain];
		model = [newModel retain];

        NSString *filePath = [model objectForKey:@"filePath"];
        filename = [[[filePath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] lastPathComponent] retain];
        
		indentationLevel = 0;
	}
	return self;
}

//
// tableView:heightForRowAtIndexPath
//
// Returns the height for a given indexPath
//
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [tableView rowHeight];
}

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.cellIndexPath = indexPath;
	self.tableController = (UITableViewController *)tableView.dataSource;
	
	static NSString *cellIdentifier = @"IconNameDataCell";
	IFControlTableViewCell* cell = (IFControlTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[[IFControlTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
		if (nil != backgroundColor) [cell setBackgroundColor:backgroundColor];
		cell.clipsToBounds = YES;
		cell.textLabel.font = LABEL_FONT;
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
	cell.indentationLevel = indentationLevel;
	cell.textLabel.text = label;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;

    UIImage *icon = imageForFilename(filename);

    UIView *containerView = [cell view];
	UIImageView *iconView = (UIImageView *)[containerView.subviews objectAtIndex:0];
	UILabel *filenameView = (UILabel *)[containerView.subviews objectAtIndex:1];

    if (nil == cell.view ||
        nil == iconView ||
        nil == filenameView ||
        ![icon isEqual:[iconView image]] ||
        ![filename isEqual:[filenameView text]])
    {
        if (nil == iconView)
        {
            // Create the UI controls as we've determined they don't exist or need renewal
            containerView = [[UIView alloc] init];
            iconView = [[UIImageView alloc] init];
            filenameView = [[UILabel alloc] init];
            [filenameView setBackgroundColor:[UIColor clearColor]];
            
            [containerView addSubview:iconView];
            [containerView addSubview:filenameView];
            [cell setView:containerView];
            [filenameView release];
            [iconView release];
            [containerView release];
        }
    
        CGRect  bounds     = [tableView bounds];
        CGSize  labelSize  = [label sizeWithFont:LABEL_FONT];
        CGFloat tableWidth = bounds.size.width;
        CGFloat drawWidth  = (tableWidth * (5.0f/6.0f)) - ((20.0f * indentationLevel) + labelSize.width + (2 * kDINCCGutter));
        CGFloat drawHeight = [tableView rowHeight] - 2 * kDINCCGutter;
        
        CGSize filenameSize = [filename sizeWithFont:FILE_FONT];
        filenameSize.width = fminf(filenameSize.width, drawWidth - 40.0f);

        // Calculate the UI control frames...
        CGRect filenameFrame = CGRectMake(drawWidth - filenameSize.width,
                                          0.0f,
                                          filenameSize.width,
                                          drawHeight);

        CGRect iconFrame = CGRectMake(filenameFrame.origin.x - 36.0f,
                                     0.0f - kDINCCGutter / 2.0f,
                                     32.0f,
                                     32.0f);
        
        CGRect containerFrame = CGRectMake(0.0f, kDINCCGutter / 2.0f, drawWidth, drawHeight);

        [iconView setImage:icon];
        [iconView setFrame:iconFrame];
        [filenameView setText:filename];
        [filenameView setFrame:filenameFrame];
        [containerView setFrame:containerFrame];
    }
	
    return cell;
}

@end
