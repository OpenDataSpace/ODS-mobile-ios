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
//  UICustomSwitch.h
//
//  Created by Hardy Macia on 10/28/09.
//  Copyright 2009 Catamount Software. All rights reserved.
//
//  Code can be freely redistruted and modified as long as the above copyright remains.
//
//	http://www.catamount.com/blog/?p=1063
//

#import <Foundation/Foundation.h>


@interface CSCustomSwitch : UISlider {
	BOOL on;
	UIColor *tintColor;
	UIView *clippingView;
	UILabel *rightLabel;
	UILabel *leftLabel;
	
	// private member
	BOOL m_touchedSelf;
}

@property(nonatomic,getter=isOn) BOOL on;
@property (nonatomic,retain) UIColor *tintColor;
@property (nonatomic,retain) UIView *clippingView;
@property (nonatomic,retain) UILabel *rightLabel;
@property (nonatomic,retain) UILabel *leftLabel;

+ (CSCustomSwitch *)switchWithLeftText:(NSString *)tag1 andRight:(NSString *)tag2;

- (void)setOn:(BOOL)on animated:(BOOL)animated;
- (void)scaleSwitch:(CGSize)newSize;

@end
