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
//  FavoritesErrorTableViewCell.m
//

#import "FavoritesErrorTableViewCell.h"

@implementation FavoritesErrorTableViewCell

@synthesize fileNameTextLabel = _fileNameTextLabel;
@synthesize syncButton = _syncButton;
@synthesize saveButton = _saveButton;
@synthesize delegate = _delegate;
@synthesize imageView = _myImageView; // _imageView used by superclass

- (void)dealloc
{
    _delegate = nil;
    [_fileNameTextLabel release];
    [_syncButton release];
    [_saveButton release];
    [_myImageView release];
    [super dealloc];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (!IS_IPAD)
    {
        // Manually override to get better button layout on iPhone, which autosizing doesn't get quite right
        CGFloat midpointX = (self.contentView.frame.size.width / 2);
        CGRect buttonFrame = self.syncButton.frame;
        buttonFrame.origin.x = midpointX - buttonFrame.size.width - 10.0f;
        [self.syncButton setFrame:buttonFrame];
        
        buttonFrame = self.saveButton.frame;
        buttonFrame.origin.x = midpointX + 10.0f;
        [self.saveButton setFrame:buttonFrame];
    }
}

#pragma mark - Button event handlers

- (IBAction)pressedSyncButton:(id)sender;
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didPressSyncButton:)])
    {
        [self.delegate didPressSyncButton:(UIButton *)sender];
    }
}

- (IBAction)pressedSaveToDownloads:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didPressSaveToDownloadsButton:)])
    {
        [self.delegate didPressSaveToDownloadsButton:(UIButton *)sender];
    }
}

@end
