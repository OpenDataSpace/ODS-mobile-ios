//
//  AGImagePickerController+Constants.m
//  AGImagePickerController
//
//  Created by Artur Grigor on 28.02.2012.
//  Copyright (c) 2012 Artur Grigor. All rights reserved.
//  
//  For the full copyright and license information, please view the LICENSE
//  file that was distributed with this source code.
//  

#import "AGImagePickerController+Constants.h"

@implementation AGImagePickerController (Constants)

+ (NSUInteger)numberOfItemsPerRow:(CGSize)tableSize
{
    return tableSize.width / 80;
}

#pragma mark - Item

+ (CGSize)itemSize
{
    return CGSizeMake(AGIPC_ITEM_WIDTH, AGIPC_ITEM_HEIGHT);
}

+ (CGRect)itemRect:(CGSize)tableSize
{
    CGPoint topLeftPoint = [AGImagePickerController itemTopLeftPoint:tableSize];
    CGSize size = [AGImagePickerController itemSize];
    
    return CGRectMake(topLeftPoint.x, topLeftPoint.y, size.width, size.height);
}

+ (CGPoint)itemTopLeftPoint:(CGSize)tableSize
{
    NSUInteger numberOfItems = [AGImagePickerController numberOfItemsPerRow:tableSize];

    CGFloat itemWidth = [AGImagePickerController itemSize].width;
    CGFloat allPadding = tableSize.width - (itemWidth * numberOfItems);
    CGFloat itemPadding = allPadding / (numberOfItems + 1);
    
    return CGPointMake(itemPadding, MIN(10, itemPadding));
}

#pragma mark - Checkmark

+ (CGPoint)checkmarkBottomRightPoint
{
    return CGPointMake(AGIPC_CHECKMARK_RIGHT_MARGIN, AGIPC_CHECKMARK_BOTTOM_MARGIN);
}

+ (CGSize)checkmarkSize
{
    return CGSizeMake(AGIPC_CHECKMARK_WIDTH, AGIPC_CHECKMARK_HEIGHT);
}

+ (CGRect)checkmarkRect
{
    CGPoint bottomRightPoint = [AGImagePickerController checkmarkBottomRightPoint];
    CGSize size = [AGImagePickerController checkmarkSize];
    
    return CGRectMake(bottomRightPoint.x, bottomRightPoint.y, size.width, size.height);
}

+ (CGRect)checkmarkFrameUsingItemFrame:(CGRect)frame
{
    CGRect checkmarkRect = [AGImagePickerController checkmarkRect];
    
    return CGRectMake(
                          frame.size.width - checkmarkRect.size.width - checkmarkRect.origin.x, 
                          frame.size.height - checkmarkRect.size.height - checkmarkRect.origin.y, 
                          checkmarkRect.size.width, 
                          checkmarkRect.size.height
                      );
}


#pragma mark - Movie icon

+ (CGPoint)movieBottomLeftPoint
{
    return CGPointMake(AGIPC_MOVIE_LEFT_MARGIN, AGIPC_MOVIE_BOTTOM_MARGIN);
}

+ (CGSize)movieSize
{
    return CGSizeMake(AGIPC_MOVIE_WIDTH, AGIPC_MOVIE_HEIGHT);
}

+ (CGRect)movieRect
{
    CGPoint bottomLeftPoint = [AGImagePickerController movieBottomLeftPoint];
    CGSize size = [AGImagePickerController movieSize];
    
    return CGRectMake(bottomLeftPoint.x, bottomLeftPoint.y, size.width, size.height);
}

+ (CGRect)movieFrameUsingItemFrame:(CGRect)frame
{
    CGRect movieRect = [AGImagePickerController movieRect];
    
	CGRect test = CGRectMake(
					  movieRect.origin.x, 
					  frame.size.height - movieRect.size.height - movieRect.origin.y, 
					  movieRect.size.width, 
					  movieRect.size.height
                      );
	
    return test;
}

@end
