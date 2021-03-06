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
//  FavoriteTableViewCell.m
//

#import "FavoriteTableViewCell.h"

@implementation FavoriteTableViewCell

@synthesize overlayView = _cellOverlayView;
@synthesize filename = _filename;
@synthesize details = _details;
@synthesize serverName = _serverName;
@synthesize image = _image;
@synthesize progressBar = _progressBar;
@synthesize status = _status;
@synthesize favoriteIcon = _favoriteIcon;
@synthesize restrictedImage = _restrictedImage;

- (void)dealloc
{
    [_cellOverlayView release];
	[_filename release];
	[_details release];
    [_serverName release];
	[_image release];
    [_progressBar release];
    [_status release];
    [_favoriteIcon release];
    [_restrictedImage release];
    [super dealloc];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.details.font = [UIFont italicSystemFontOfSize:14.0];
}

NSString * const FavoriteTableCellIdentifier = @"FavoriteCellIdentifier";

@end
