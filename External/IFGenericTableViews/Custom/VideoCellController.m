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
//  VideoCellController.m
//

#import "VideoCellController.h"
#import "MobileCoreServices/UTCoreTypes.h"
#import "IFControlTableViewCell.h"
#import "MediaPlayer/MPMoviePlayerController.h"

@implementation VideoCellController
@synthesize backgroundColor;
@synthesize selectionStyle;
@synthesize accessoryType;
@synthesize updateTarget, updateAction;
@synthesize indentationLevel;
@synthesize cellControllerFirstResponderHost, tableController, cellIndexPath;
@synthesize maxWidth;

CGFloat const kVGutter = 10.0f;
CGFloat const kVideoWidth = 200.0f;
#define LABEL_FONT [UIFont boldSystemFontOfSize:17.0f]

- (void)dealloc
{
	[label release];
	[key release];
	[model release];
	[backgroundColor release];	
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
		
		backgroundColor = nil;
		selectionStyle = UITableViewCellSelectionStyleNone;
        accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		indentationLevel = 0;
		
		autoAdvance = NO;
        
        player = [[MPMoviePlayerController alloc] init];
        player.controlStyle = MPMovieControlStyleEmbedded;
	}
	return self;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSURL *videoUrl     = [model objectForKey:key];
	
	if (nil != videoUrl) {
		return kVideoWidth;
	} else {
		CGFloat rowHeight  = [tableView rowHeight];
		return rowHeight;
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [player play];
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.cellIndexPath = indexPath;
	self.tableController = (UITableViewController *)tableView.dataSource;
	
	static NSString *cellIdentifier = @"VideoDataCell";
	IFControlTableViewCell* cell = (IFControlTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[[IFControlTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellIdentifier] autorelease];
		if (nil != backgroundColor) [cell setBackgroundColor:backgroundColor];
		cell.clipsToBounds = YES;
		cell.textLabel.font = LABEL_FONT;
		cell.accessoryType = accessoryType;
        cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
	cell.indentationLevel = indentationLevel;
	cell.textLabel.text = label;
	cell.selectionStyle = selectionStyle;
	
	NSURL *videoUrl     = [model objectForKey:key];
    player.contentURL = videoUrl;
	cell.view = player.view;
    
    CGFloat height = [self tableView:[tableController tableView] heightForRowAtIndexPath:cellIndexPath] - kVGutter;
    CGFloat width  = height;
    CGRect playerFrame = CGRectMake(0.0f, kVGutter / 2.0f, width, height);
    cell.view.frame = playerFrame;
    
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

@end
