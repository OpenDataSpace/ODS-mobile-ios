//
//  AGImagePickerController+Constants.h
//  AGImagePickerController
//
//  Created by Artur Grigor on 28.02.2012.
//  Copyright (c) 2012 Artur Grigor. All rights reserved.
//  
//  For the full copyright and license information, please view the LICENSE
//  file that was distributed with this source code.
//  

#import "AGImagePickerController.h"

#define IS_IPAD()               ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] && \
[[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

#define SHOULD_CHANGE_STATUS_BAR_STYLE                      1
#define SHOULD_DISPLAY_SELECTION_INFO                       1

// Size in points
#define AGIPC_CHECKMARK_WIDTH                               28.f
#define AGIPC_CHECKMARK_HEIGHT                              28.f
#define AGIPC_CHECKMARK_RIGHT_MARGIN                        4.f
#define AGIPC_CHECKMARK_BOTTOM_MARGIN                       2.f

#define AGIPC_MOVIE_WIDTH                               26.f
#define AGIPC_MOVIE_HEIGHT                              15.f
#define AGIPC_MOVIE_LEFT_MARGIN							4.f
#define AGIPC_MOVIE_BOTTOM_MARGIN                       2.f

#define AGIPC_ITEMS_PER_ROW_IPHONE_PORTRAIT                 4
#define AGIPC_ITEMS_PER_ROW_IPHONE_LANDSCAPE                6
#define AGIPC_ITEMS_PER_ROW_IPAD_PORTRAIT                   8
#define AGIPC_ITEMS_PER_ROW_IPAD_LANDSCAPE                  12

#define AGIPC_ITEM_WIDTH                                    75.f
#define AGIPC_ITEM_HEIGHT                                   75.f

@interface AGImagePickerController (Constants)

+ (NSUInteger)numberOfItemsPerRow;
+ (CGPoint)itemTopLeftPoint;
+ (CGSize)itemSize;
+ (CGRect)itemRect;
+ (CGPoint)checkmarkBottomRightPoint;
+ (CGPoint)movieBottomLeftPoint;
+ (CGSize)checkmarkSize;
+ (CGSize)movieSize;
+ (CGRect)checkmarkRect;
+ (CGRect)movieRect;
+ (CGRect)checkmarkFrameUsingItemFrame:(CGRect)frame;
+ (CGRect)movieFrameUsingItemFrame:(CGRect)frame;

@end
