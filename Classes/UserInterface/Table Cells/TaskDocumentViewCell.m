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
// TaskDocumentViewCell 
//
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import "TaskDocumentViewCell.h"
#import "AsyncLoadingUIImageView.h"

#define THUMBNAIL_SIZE 100.0


@implementation TaskDocumentViewCell

@synthesize thumbnailImageView = _thumbnailImageView;
@synthesize nameLabel = _nameLabel;

- (void)dealloc
{
    [_thumbnailImageView release];
    [_nameLabel release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        // Thumbnail view
        AsyncLoadingUIImageView *thumbnailImageView = [[AsyncLoadingUIImageView alloc] init];
        thumbnailImageView.layer.borderWidth = 1.0;
        thumbnailImageView.layer.borderColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.4].CGColor;
        self.thumbnailImageView = thumbnailImageView;
        [thumbnailImageView release];

        // name label
        UILabel *nameLabel = [[UILabel alloc] init];
        self.nameLabel = nameLabel;
        [nameLabel release];
    }
    return self;
}


- (void)layoutSubviews
{
    [super layoutSubviews];

    // Clear any previous subview
    [[self.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

    // Thumbnail view
    CGFloat margin = 10;
    CGRect thumbnailFrame = CGRectMake(margin, margin, THUMBNAIL_SIZE, THUMBNAIL_SIZE);
    self.thumbnailImageView.frame = thumbnailFrame;
    [self.contentView addSubview:self.thumbnailImageView];

    // Name label
    self.nameLabel.frame = CGRectMake(thumbnailFrame.origin.x + thumbnailFrame.size.width + 2 * margin,
            thumbnailFrame.origin.y,
            self.contentView.frame.size.width - thumbnailFrame.size.width - 2 * margin,
            thumbnailFrame.size.height);
    [self.contentView addSubview:self.nameLabel];
}

@end
