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
//  AboutViewController.h
//

#import <UIKit/UIKit.h>
#import "GradientView.h"


@interface AboutViewController : UIViewController

@property (nonatomic, retain) IBOutlet UILabel *buildTimeLabel;
@property (nonatomic, retain) IBOutlet GradientView *gradientView;
@property (nonatomic, retain) IBOutlet GradientView *aboutBorderedInfoView;
@property (nonatomic, retain) IBOutlet GradientView *aboutClientBorderedInfoView;
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UITextView *aboutText;
@property (nonatomic, retain) IBOutlet UILabel *librariesLabel;
@property (nonatomic, retain) IBOutlet UIButton *additionalLogoButton;
@property (nonatomic, retain) IBOutlet UIImageView *ziaLogoButtonImageView;
@property (nonatomic, retain) IBOutlet UIImageView *smallZiaButtonImageView;

- (IBAction)buttonPressed:(id)sender;
- (IBAction)clientButtonPressed:(id)sender;

@end
