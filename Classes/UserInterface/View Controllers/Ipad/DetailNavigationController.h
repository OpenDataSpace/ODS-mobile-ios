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
//  DetailsPlaceholderViewController.h
//

#import <UIKit/UIKit.h>

@interface DetailNavigationController : UINavigationController <UISplitViewControllerDelegate>
{
    BOOL hideMasterAlways;
    BOOL previousExpandedState;
}

@property (nonatomic, retain, readonly) UIViewController *detailViewController;
@property (nonatomic, retain) UIBarButtonItem *masterPopoverBarButton;
@property (nonatomic, retain) UIPopoverController *masterPopoverController;
@property (nonatomic, retain) NSString *popoverButtonTitle;
@property (nonatomic, retain) UIBarButtonItem *expandButton;
@property (nonatomic, retain) UIBarButtonItem *closeButton;
@property (nonatomic, retain) UISplitViewController *splitViewController;
@property (nonatomic, assign) BOOL isExpanded;


- (void)resetViewControllerStackWithNewTopViewController:(UIViewController *)newTopViewController dismissPopover:(BOOL)dismissPopover;
- (void)addViewControllerToStack:(UIViewController *)newTopViewController;
- (void)dismissPopover;
- (void)showFullScreen;
- (void)showFullScreenOnTopWithCloseButtonTitle:(NSString *)closeButtonTitle;
- (void)showMasterPopoverController;
@end
