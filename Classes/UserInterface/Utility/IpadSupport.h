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
//  IpadSupport.h
//

#import <Foundation/Foundation.h>
@class DetailNavigationController;

@interface IpadSupport : NSObject <UITabBarControllerDelegate>

+ (void)clearDetailController;

+ (void)registerGlobalDetail:(DetailNavigationController *)newDetailController;

+ (void)pushDetailController:(UIViewController *)newController withNavigation:(UINavigationController *)navController andSender:(id)sender;

+ (void)pushDetailController:(UIViewController *)newController withNavigation:(UINavigationController *)navController andSender:(id)sender dismissPopover:(BOOL)dismiss;

+ (void)pushDetailController:(UIViewController *)newController withNavigation:(UINavigationController *)navController andSender:(id)sender 
              dismissPopover:(BOOL)dismiss showFullScreen:(BOOL) fullScreen;

+ (void)addFullScreenDetailController:(UIViewController *)newController withNavigation:(UINavigationController *)navController andSender:(id)sender backButtonTitle:(NSString *)backButtonTitle;

// Handles the presentation as a modal controller in the ipad and a normal push
// to a nav controller in the iphone
+ (void)presentModalViewController:(UIViewController *)newController withNavigation:(UINavigationController *)navController;

+ (void)presentFullScreenModalViewController:(UIViewController *)modalController;

+ (NSString *) getCurrentDetailViewControllerObjectID;
+ (BOOL)isShowingUserContent;

+ (void)showMasterPopover;

@end
