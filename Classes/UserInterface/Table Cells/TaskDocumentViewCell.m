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

#define THUMBNAIL_WIDTH 160.0
#define THUMBNAIL_HEIGHT 120.0

@interface TaskDocumentViewCell()

@property (nonatomic, retain) UIImageView *attachmentIcon;

@end

@implementation TaskDocumentViewCell

@synthesize thumbnailImageView = _thumbnailImageView;
@synthesize nameLabel = _nameLabel;
@synthesize attachmentIcon = _attachmentIcon;
@synthesize attachmentLabel = _attachmentLabel;


- (void)dealloc
{
    [_thumbnailImageView release];
    [_nameLabel release];
    [_attachmentIcon release];
    [_attachmentLabel release];
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

        // Atachment icon
        UIImageView *attachmentIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"paperclip.png"]];
        self.attachmentIcon = attachmentIcon;
        [attachmentIcon release];

        // Attachment label
        UILabel *attachmentLabel = [[UILabel alloc] init];
        attachmentLabel.font = [UIFont systemFontOfSize:11];
        attachmentLabel.textColor = [UIColor darkGrayColor];
        self.attachmentLabel = attachmentLabel;
        [attachmentLabel release];

        // name label
        UILabel *nameLabel = [[UILabel alloc] init];
        nameLabel.textColor = [UIColor darkGrayColor];
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
    CGFloat margin = 20;
    CGRect thumbnailFrame = CGRectMake(margin, margin, THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT);
    self.thumbnailImageView.frame = thumbnailFrame;
    [self.contentView addSubview:self.thumbnailImageView];

    // Attachment icon
    CGRect attachmentIconFrame = CGRectMake(thumbnailFrame.origin.x + thumbnailFrame.size.width + margin,
            thumbnailFrame.origin.y + (thumbnailFrame.size.height - self.attachmentIcon.image.size.height)/2,
            self.attachmentIcon.image.size.width, self.attachmentIcon.image.size.height);
    self.attachmentIcon.frame = attachmentIconFrame;
    [self.contentView addSubview:self.attachmentIcon];

    // Attachment label
    CGFloat textX = attachmentIconFrame.origin.x + attachmentIconFrame.size.width + 3;
    CGRect attachmentLabelFrame = CGRectMake(textX,
            attachmentIconFrame.origin.y, self.contentView.frame.size.width - textX - margin, 12);
    self.attachmentLabel.frame = attachmentLabelFrame;
    [self.contentView addSubview:self.attachmentLabel];

    // Name label
    self.nameLabel.frame = CGRectMake(textX, attachmentLabelFrame.origin.y + attachmentLabelFrame.size.height,
            self.contentView.frame.size.width - textX - margin, 18);
    [self.contentView addSubview:self.nameLabel];
}

@end
