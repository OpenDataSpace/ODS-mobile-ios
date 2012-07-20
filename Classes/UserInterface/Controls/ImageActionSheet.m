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
//  ImageActionSheet.m
//

#import "ImageActionSheet.h"

CGFloat const kMaxImageWidth = 30.0f;
CGFloat const kButtonLeftPadding = 10.0f;
CGFloat const kButtonRightPadding = 10.0f;

@implementation ImageActionSheet
@synthesize images = _images;

- (void)dealloc
{
    [_images release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        _images = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)addImage:(UIImage *)image toButtonIndex:(NSInteger)buttonIndex
{
    [self addImage:image toButtonWithTitle:[self buttonTitleAtIndex:buttonIndex]];
}

- (void)addImage:(UIImage *)image toButtonWithTitle:(NSString *)buttonTitle
{
    for(id subview in [self subviews])
    {
        //It means that it is a button
        if([subview isKindOfClass:[UIButton class]])
        {
            NSString *currentButtonTitle = [subview titleForState:UIControlStateNormal];
            if([currentButtonTitle isEqualToString:buttonTitle])
            {
                //Right-align the button image
                UIButton *actionButton = (UIButton *)subview;
                //[actionButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
                
                CGSize size = [[actionButton titleForState:UIControlStateNormal] sizeWithFont:actionButton.titleLabel.font];
                UIImageView *imageView = [[[UIImageView alloc] initWithImage:image] autorelease];
                CGRect imageFrame = [imageView frame];
                CGRect buttonFrame = [actionButton frame];
                imageFrame.origin.y = 22 - (image.size.height / 2);
                imageFrame.origin.x = 10;
                [imageView setFrame:imageFrame];
                //[actionButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, -size.width)];
                //actionButton.imageEdgeInsets = UIEdgeInsetsMake(0.0, size.width + 10.0, 0.0, 0.0);
                //[actionButton setImageEdgeInsets:UIEdgeInsetsMake(0, CGRectGetWidth(actionButton.frame)-15, 0, 0)];
                [actionButton setTitleEdgeInsets:UIEdgeInsetsMake(0, image.size.width + 25, 0, 0)];
                [actionButton addSubview:imageView];
                //[actionButton setImage:image forState:UIControlStateNormal];
            }
        }
    }
    
    [self.images setObject:image forKey:buttonTitle];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    for(id subview in [self subviews])
    {
        if([subview isKindOfClass:[UIButton class]])
        {
            UIButton *actionButton = (UIButton *)subview;
            [subview setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
            [actionButton setTitleEdgeInsets:UIEdgeInsetsMake(0, kMaxImageWidth + kButtonLeftPadding + kButtonRightPadding, 0, 0)];
            
            UIView *currentView = [actionButton viewWithTag:777];
            if(!currentView)
            {
                UIImage *image = [self.images objectForKey:[actionButton titleForState:UIControlStateNormal]];
                UIImageView *imageView = [[[UIImageView alloc] initWithImage:image] autorelease];
                [imageView setTag:777];
                CGRect imageFrame = [imageView frame];
                CGRect buttonFrame = [actionButton frame];
                imageFrame.origin.y = (buttonFrame.size.height / 2) - (image.size.height / 2);
                imageFrame.origin.x = kButtonLeftPadding;
                [imageView setFrame:imageFrame];
            }
        }
    }
}

- (void)logSubviews:(UIView *)subviews level:(NSInteger)level
{
    for(id subSubview in [subviews subviews])
    {
        NSLog(@"%d: Subsubview class: %@", level, [[subSubview class] description]);
        [self logSubviews:subSubview level:(level+1)];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    for(id subview in [cell subviews])
    {
        if([subview isKindOfClass:[UILabel class]])
        {
            UIImage *image = [self.images objectForKey:[subview text]];
            if(image)
            {
                [cell.imageView setImage:image];
                break;
            }
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    for(id subSubview in [cell subviews])
    {
        if([subSubview isKindOfClass:[UILabel class]])
        {
            UILabel *label = (UILabel *)subSubview;
            [label setTextAlignment:UITextAlignmentLeft];
            CGRect labelRect = [label frame];
            labelRect.origin.x += kMaxImageWidth + kButtonLeftPadding + kButtonRightPadding;
            [label setFrame:labelRect];
        }
    }
}

@end
