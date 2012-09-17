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
//  SystemNotice.h
//

#import <Foundation/Foundation.h>

@interface SystemNotice : NSObject

typedef enum
{
    SystemNoticeTypeInformation = 0,
    SystemNoticeTypeError
} SystemNoticeType;

/**
 * Public API
 */
@property (nonatomic, retain) NSString *message;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, assign) CGFloat duration;
@property (nonatomic, assign) CGFloat delay;
@property (nonatomic, assign) CGFloat alpha;
@property (nonatomic, assign) CGFloat offsetY;

- (id)initWithView:(UIView *)view;
- (void)show;

/**
 * Preferred API entrypoints
 */
// Note: Title label is used for a simple information message type
+ (SystemNotice *)showInformationNoticeInView:(UIView *)view message:(NSString *)message;
+ (SystemNotice *)showInformationNoticeInView:(UIView *)view message:(NSString *)message title:(NSString *)title;
// Note: An error notice without given title will be given a generic "An Error Occurred" title
+ (SystemNotice *)showErrorNoticeInView:(UIView *)view message:(NSString *)message;
+ (SystemNotice *)showErrorNoticeInView:(UIView *)view message:(NSString *)message title:(NSString *)title;
+ (SystemNotice *)systemNoticeOfType:(SystemNoticeType)type inView:(UIView *)view message:(NSString *)message title:(NSString *)title;

@end
