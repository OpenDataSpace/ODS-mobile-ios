//
//  IFPhotoCellController.m
//  XpenserUtility
//
//  Created by Bindu Wavell on 1/3/10.
//  Copyright 2010 Zia Consulting, Inc.. All rights reserved.
//

#import "IFPhotoCellController.h"

#import "IFGenericTableViewController.h"
#import "IFControlTableViewCell.h"
#import "IFNamedImage.h"
#import "UIImageUtils.h"
#import "MobileCoreServices/UTCoreTypes.h"

#define kMaxHeight 300.0f

@implementation IFPhotoCellController

@synthesize backgroundColor;
@synthesize selectionStyle;
@synthesize updateTarget, updateAction;
@synthesize indentationLevel;
@synthesize cellControllerFirstResponderHost, tableController, cellIndexPath;
@synthesize maxWidth;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
@synthesize popover;
#endif

CGFloat const GUTTER = 10.0f;
#define LABEL_FONT [UIFont boldSystemFontOfSize:17.0f]

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
	[backgroundColor release];	
	[tableController release];
	[cellIndexPath release];
	
	maxWidth = 0.0f;
	
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	[popover release];
#endif
	
	[super dealloc];
}

//
// init
//
// Init method for the object.
//
- (id)initWithLabel:(NSString *)newLabel atKey:(NSString *)newKey inModel:(id<IFCellModel>)newModel;
{
	self = [super init];
	if (self != nil)
	{
		label = [newLabel retain];
		key = [newKey retain];
		model = [newModel retain];
		
		backgroundColor = nil;
		selectionStyle = UITableViewCellSelectionStyleBlue;
		indentationLevel = 0;
		
		autoAdvance = NO;
	}
	return self;
}

//
// tableView:heightForRowAtIndexPath
//
// Returns the height for a given indexPath
//
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	UIImage *image     = [model objectForKey:key];
	
	if (nil != image) {
		CGRect  bounds     = [tableView bounds];
		CGFloat ratio      = [self imageHeightToWidthRatio:image];
		CGSize  labelSize  = [label sizeWithFont:LABEL_FONT];
		CGFloat tableWidth = bounds.size.width;
		// NOTE: The documentation states that the indentation width is 10 "points". It's more like 20
		// pixels and changing the property has no effect on the indentation. We'll use 20.0f here
		// and cross our fingers that this doesn't screw things up in the future.		
		CGFloat drawWidth  = (tableWidth * (5.0f/6.0f)) - ((20.0f * indentationLevel) + labelSize.width + (2 * GUTTER));
        
		return fmin(kMaxHeight, fmin(image.size.height, (drawWidth * ratio))) + GUTTER;
	} else {
		CGFloat rowHeight  = [tableView rowHeight];
		return rowHeight;
	}
}
- (CGFloat)imageHeightToWidthRatio:(UIImage *)image
{
	if (nil != image) return image.size.height / image.size.width;
	return 0.0f;
}


- (void)showImagePickerOfSourceType:(UIImagePickerControllerSourceType) type {

	
	if ([UIImagePickerController isSourceTypeAvailable: type]) { 

		
		[[tableController tableView] deselectRowAtIndexPath:cellIndexPath animated:NO];
		
		UIImagePickerController *picker = nil;
		NSArray *mediaTypes = [NSArray arrayWithObject:(NSString *) kUTTypeImage];
		
		@try {
			picker = [[UIImagePickerController alloc] init];
			picker.delegate = self; 
			picker.allowsEditing = NO; 
			picker.sourceType = type;
			picker.mediaTypes = mediaTypes;
			
			
			if (autoAdvance) {
				((IFGenericTableViewController *)tableController).controllerForReturnHandler = self;
				autoAdvance = NO;
			}
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
			if (IS_IPAD) {
				Class classPopoverController = NSClassFromString(@"UIPopoverController");
				if (classPopoverController) {
					self.popover = [[classPopoverController alloc] initWithContentViewController:picker];
					[self.popover release];
					[self.popover presentPopoverFromRect:[[[tableController tableView] cellForRowAtIndexPath:cellIndexPath] frame] inView:[tableController view] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
					NSLog(@"On an iPad so showing the popover");
				} else {
					NSLog(@"Device does not support popover");
				}
			} else 
#endif
				[tableController.navigationController presentModalViewController:picker animated:YES];	
		}
		@catch (NSException * e) {
			NSLog(@"Exception setting up UIImagePickerController%@", [e description]);
		}
		@finally {
			[picker release];
		}
	
	} else {
		NSString *title = NSLocalizedString(@"Photo Error",@"Title for alert about not being able to select photo");
		NSString *msg = NSLocalizedString(@"Device does not support requested photo source",@"Message about not being able to select photo");
		NSString *button = NSLocalizedString(@"OK",@"Button for alert that tells user they can't select a photo");
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
														message:msg delegate:nil
											  cancelButtonTitle:button otherButtonTitles:nil]; 
		[alert show]; 
		[alert release];
		[[tableController tableView] deselectRowAtIndexPath:cellIndexPath animated:YES];
	}	
}

//
// tableView:didSelectRowAtIndexPath:
//
// Handle row selection
//
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.tableController = (UITableViewController *)tableView.dataSource;
	
	//If this is just a cell to display an image do nothing..
	if([self selectionStyle] != UITableViewCellSelectionStyleNone) {
		
		//What to do...Action Sheet or Picker...What are the users options...
		if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] && ![[[UIDevice currentDevice] model ] isEqualToString:@"iPhone Simulator"]) {
			
			//Use an action sheet...the user needs to tell us how they want to select the image
			UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" 
													   destructiveButtonTitle:nil otherButtonTitles:@"Take A Photo", @"Choose From Library", nil];
			[actionSheet showInView:[tableController view]];
			[actionSheet release];
			
		} else {
			
			//Use a SavedPhotos picker....
			[self showImagePickerOfSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
			
		}
	}// selection style check!
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
	
	static NSString *cellIdentifier = @"PhotoDataCell";
	IFControlTableViewCell* cell = (IFControlTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[[IFControlTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellIdentifier] autorelease];
		if (nil != backgroundColor) [cell setBackgroundColor:backgroundColor];
		cell.clipsToBounds = YES;
		cell.textLabel.font = LABEL_FONT;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;		
	}
	
	cell.indentationLevel = indentationLevel;
	cell.textLabel.text = label;
	cell.selectionStyle = selectionStyle;
	
	UIImage *image = [model objectForKey:key];
	UIImageView *imageView = (UIImageView *)[cell view];
	
	// if there is no selection then we don't want to
	// show anything in the selected value area
	if (nil == image) {
		if (nil != cell.view) {
			((UIImageView *)cell.view).image = nil;
		}
	}
	else if (nil == cell.view || 
			 nil == imageView ||
			 ![image isEqual:[imageView image]]) 
	{
		
		if (nil == imageView) {
			imageView = [[UIImageView alloc] init];
			[cell setView:imageView];
			[imageView release];
		}
		
		CGFloat ratio = [self imageHeightToWidthRatio:image];
		CGFloat height = [self tableView:[tableController tableView] heightForRowAtIndexPath:cellIndexPath] - GUTTER;
		CGFloat width  = height / ratio;
		CGRect imageFrame = CGRectMake(0.0f, GUTTER / 2.0f, width, height);
		
		CGRect  bounds     = [tableView bounds];
		CGSize  labelSize  = [label sizeWithFont:LABEL_FONT];
		CGFloat tableWidth = bounds.size.width;
		CGFloat drawWidth  = (tableWidth * (5.0f/6.0f)) - ((20.0f * indentationLevel) + labelSize.width + (2 * GUTTER));
		
        [imageView setImage:[image imageByScalingToWidth:drawWidth]];
		[imageView setFrame:imageFrame];
		CGRect  f = [cell frame];
		f.size.height = height + GUTTER;
		[cell setFrame:f];
		

		if (image)
			NSLog(@"PHOTO RESOLUTION: %@", [NSValue valueWithCGSize:image.size]);
	}
	
    return cell;
}

#pragma mark IFCellControllerFirstResponder
-(void)assignFirstResponderHost: (NSObject<IFCellControllerFirstResponderHost> *)hostIn
{
	[self setCellControllerFirstResponderHost: hostIn];
}

-(void)becomeFirstResponder
{
	@try {
		autoAdvance = YES;
		[self tableView:(UITableView *)tableController.view didSelectRowAtIndexPath: self.cellIndexPath];
	}
	@catch (NSException *ex) {
		NSLog(@"unable to become first responder");
	}
}

-(void)resignFirstResponder
{
	NSLog(@"resign first responder is noop for photo cells");
}

#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
	if (nil != image) {
		[model setObject:nil forKey:key];
		if (0.0f == maxWidth || [image size].width < maxWidth) {
			[model setObject:image forKey:key];
		} else {
			[model setObject:[image imageByScalingToWidth:maxWidth] forKey:key];
		}
	}
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	if (IS_IPAD) {
		if(nil != popover && [popover isPopoverVisible]) {
			[popover dismissPopoverAnimated:YES];
			popover = nil;
		}
	} else
#endif
        
        
    [picker dismissModalViewControllerAnimated:YES];
	[[tableController tableView] reloadRowsAtIndexPaths:[NSArray arrayWithObject:cellIndexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	if (IS_IPAD) {
		if(nil != popover && [popover isPopoverVisible]) {
			[popover dismissPopoverAnimated:YES];
			popover = nil;
		}
	} else
#endif
		[picker dismissModalViewControllerAnimated:YES];
}


#pragma mark UINavigationControllerDelegate
- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
}


#pragma mark -
#pragma mark UIActionSheetDelegate methods
- (void) actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex { 
	

	UIImagePickerControllerSourceType type = 9;
	
	switch (buttonIndex) {
		case 0: // Camera
		{
			type = UIImagePickerControllerSourceTypeCamera;
			break;
		}
		case 1: // Photo Library
		{	
			type = UIImagePickerControllerSourceTypePhotoLibrary;
			break;
		}		
		//case 2: // Camera Roll
		//{	
		//	type = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
		//	break;
		//}		
		default: 
		{
			[[tableController tableView] deselectRowAtIndexPath:cellIndexPath animated:YES];
			return;
		} // End Switch
			
	}
	
	[self showImagePickerOfSourceType:type];
	
}


@end
