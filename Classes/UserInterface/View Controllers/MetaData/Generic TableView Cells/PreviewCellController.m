//
//  PreviewCellController.m
//  FreshDocs
//
//  Created by bdt on 3/10/14.
//
//
#import "UIImageView+WebCache.h"
#import "PreviewCellController.h"
#import "IFControlTableViewCell.h"

#define PREVIEW_CELL_HEIGHT_IPHONE 160.0
#define PREVIEW_CELL_HEIGHT_IPAD   320.0

@implementation PreviewCellController

//
// init
//
// Init method for the object.
- (id) initWithThumbnailURL:(NSURL*) url {
    self = [super init];
	if (self != nil)
	{
		thumbnailURL_ = [url copy];
	}
	return self;
}

//
// tableView:cellForRowAtIndexPath:
//
// Returns the cell for a given indexPath.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"PreviewDataCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, cell.frame.size.width,IS_IPAD?PREVIEW_CELL_HEIGHT_IPAD:PREVIEW_CELL_HEIGHT_IPHONE)];//IS_IPAD?CGRectZero:
        imageView.tag = 1001;
        if (IS_IPAD) {
            imageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleWidth;
        }else {
            imageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
        }
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [cell addSubview:imageView];
    }
	
	cell.accessoryType = UITableViewCellSelectionStyleNone;
	cell.selectionStyle = UITableViewCellAccessoryNone;
	
    UIImageView *thumbnailImageView = (UIImageView*)[cell viewWithTag:1001];
    [thumbnailImageView setImageWithURL:thumbnailURL_ placeholderImage:nil];
	
    return cell;
}


- (float) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return IS_IPAD?PREVIEW_CELL_HEIGHT_IPAD:PREVIEW_CELL_HEIGHT_IPHONE;
}

@end
