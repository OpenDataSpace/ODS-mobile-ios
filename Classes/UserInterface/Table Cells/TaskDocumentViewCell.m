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

#import <QuartzCore/QuartzCore.h>
#import "TaskDocumentViewCell.h"
#import "AsyncLoadingUIImageView.h"

#define THUMBNAIL_WIDTH 160.0
#define THUMBNAIL_HEIGHT 120.0

NSInteger const kRestrictedIconWidth = 30;
NSInteger const kRestrictedIconHeight = 30;

@interface TaskDocumentViewCell()

@property (nonatomic, retain) UIImageView *attachmentIcon;
@property (nonatomic, retain) UIView *divider1;
@property (nonatomic, retain) UIView *divider2;

@end

@implementation TaskDocumentViewCell

@synthesize thumbnailImageView = _thumbnailImageView;
@synthesize nameLabel = _nameLabel;
@synthesize attachmentIcon = _attachmentIcon;
@synthesize attachmentLabel = _attachmentLabel;
@synthesize divider1 = _divider1;
@synthesize divider2 = _divider2;
@synthesize infoButton = _infoButton;


- (void)dealloc
{
    [_thumbnailImageView release];
    [_nameLabel release];
    [_attachmentIcon release];
    [_attachmentLabel release];
    [_divider1 release];
    [_divider2 release];
    [_infoButton release];
    [_restrictedImage release];
    
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        // Thumbnail view
        AsyncLoadingUIImageView *thumbnailImageView = [[AsyncLoadingUIImageView alloc] init];
        thumbnailImageView.layer.shadowColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.7].CGColor;
        thumbnailImageView.layer.shadowOffset = CGSizeMake(1, 1);
        thumbnailImageView.layer.shadowOpacity = 1.0;
        thumbnailImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.thumbnailImageView = thumbnailImageView;
        [thumbnailImageView release];

        // Attachment icon
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

        // Grey-ish line at the bottom
        UIView *divider1 = [[UIView alloc] init];
        divider1.backgroundColor = [UIColor colorWithRed:0.921 green:0.921 blue:0.921 alpha:1.0];
        self.divider1 = divider1;
        [divider1 release];

        UIView *divider2 = [[UIView alloc] init];
        divider2.backgroundColor = [UIColor colorWithRed:0.953 green:0.953 blue:0.953 alpha:1.0];
        self.divider2 = divider2;
        [divider2 release];
        
        UIImageView *restrictedImage = [[UIImageView alloc] init];
        self.restrictedImage = restrictedImage;
        [restrictedImage release];

        // Info button
        self.infoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
    }
    return self;
}


- (void)layoutSubviews
{
    [super layoutSubviews];

    // Clear any previous subviews
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

    // Divider lines
    CGRect divider1Frame = CGRectMake(self.attachmentIcon.frame.origin.x,
            self.thumbnailImageView.frame.origin.y + self.thumbnailImageView.frame.size.height - 2,
            self.contentView.frame.size.width - self.attachmentIcon.frame.origin.x - 30, 1);
    self.divider1.frame = divider1Frame;
    [self.contentView addSubview:self.divider1];

    CGRect divider2Frame = CGRectMake(divider1Frame.origin.x, divider1Frame.origin.y + 1,
            divider1Frame.size.width, divider1Frame.size.height);
    self.divider2.frame = divider2Frame;
    [self.contentView addSubview:self.divider2];

    // Info button
    CGSize infoButtonImageSize = [self.infoButton imageForState:UIControlStateNormal].size;
    CGRect infoButtonFrame = CGRectMake(divider1Frame.origin.x + divider1Frame.size.width - infoButtonImageSize.width,
            thumbnailFrame.origin.y + (thumbnailFrame.size.height - infoButtonImageSize.width)/2,
            infoButtonImageSize.width, infoButtonImageSize.height);
    self.infoButton.frame = infoButtonFrame;
    [self.contentView addSubview:self.infoButton];
    
    // Document Restriction icon
    CGSize size = CGSizeMake(kRestrictedIconWidth, kRestrictedIconHeight);
    CGRect frame = CGRectMake(self.frame.size.width - size.width, self.frame.origin.y, size.width, size.height);
    self.restrictedImage.frame = frame;
    [self.contentView addSubview:self.restrictedImage];

    // Name label
    self.nameLabel.frame = CGRectMake(textX, attachmentLabelFrame.origin.y + attachmentLabelFrame.size.height,
            self.contentView.frame.size.width - textX - (self.contentView.frame.size.width - infoButtonFrame.origin.x) - 10.0, 18);
    [self.contentView addSubview:self.nameLabel];
}

@end
