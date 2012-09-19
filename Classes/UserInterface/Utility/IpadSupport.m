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
//  IpadSupport.m
//

#import "IpadSupport.h"
#import "AlfrescoAppDelegate.h"
#import "DetailNavigationController.h"
#import "Utility.h"
#import "ModalViewControllerProtocol.h"
#import "PlaceholderViewController.h"
#import "DownloadMetadata.h"
#import "CustomNavigationController.h"
#import "NSNotificationCenter+CustomNotification.h"
#import "DocumentViewController.h"
#import "MetaDataTableViewController.h"

@implementation IpadSupport

DetailNavigationController * detailController;

+ (void)clearDetailController 
{
    if(detailController!= nil ) 
    {
        PlaceholderViewController *viewController = [[PlaceholderViewController alloc] init];
        [IpadSupport pushDetailController:viewController withNavigation:nil andSender:nil dismissPopover:NO];
        [viewController release];
    }
}

+ (void)registerGlobalDetail:(DetailNavigationController *)newDetailController 
{
    [detailController release];
    detailController = [newDetailController retain];
}

+ (void)pushDetailController:(UIViewController *)newController withNavigation:(UINavigationController *)navController andSender:(id)sender
{    
    [self pushDetailController:newController withNavigation:navController andSender:sender dismissPopover:YES];
}

+ (void)pushDetailController:(UIViewController *)newController withNavigation:(UINavigationController *)navController andSender:(id)sender dismissPopover:(BOOL)dismiss
{    
    [self pushDetailController:newController withNavigation:navController andSender:sender dismissPopover:YES showFullScreen:NO];
}

+ (void)pushDetailController:(UIViewController *)newController withNavigation:(UINavigationController *)navController andSender:(id)sender 
              dismissPopover:(BOOL)dismiss showFullScreen:(BOOL) fullScreen
{
    // In the case the navigation bar was hidden by a viewController
    [detailController setNavigationBarHidden:NO animated:YES];
    
    if (IS_IPAD && detailController != nil && newController != nil) 
    {
        [detailController.detailViewController didReceiveMemoryWarning];
        
        [detailController resetViewControllerStackWithNewTopViewController:newController dismissPopover:dismiss];
        
        [detailController.detailViewController viewDidUnload];
        
        if (fullScreen == YES)
        {
            [detailController showFullScreen];
        }
        
        // Extract the current document's metadata (fileMetadata) if the controller supports that property and it's non-nil
        DownloadMetadata *fileMetadata = nil;
        if ([newController respondsToSelector:@selector(fileMetadata)])
        {
            fileMetadata = [newController performSelector:@selector(fileMetadata)];
        }
        
        NSDictionary *userInfo = [NSMutableDictionary dictionary];
        if(sender != nil)
        {
            [userInfo setValue:sender forKey:@"newDetailController"];
        }
        
        if (fileMetadata != nil)
        {
            // Non-nil metadata, so use the optional userInfo dictionary with the notification
            [userInfo setValue:fileMetadata forKey:@"fileMetadata"];
        }
        
        [[NSNotificationCenter defaultCenter] postDetailViewControllerChangedNotificationWithSender:sender userInfo:userInfo];
    } 
    else 
    {
        [navController pushViewController:newController animated:YES];
    }
}

+ (void)addFullScreenDetailController:(UIViewController *)newController withNavigation:(UINavigationController *)navController andSender:(id)sender backButtonTitle:(NSString *)backButtonTitle
{
    // In the case the navigation bar was hidden by a viewController
    [detailController setNavigationBarHidden:NO animated:YES];
    
    if (IS_IPAD && detailController != nil && newController != nil) 
    {
        [detailController addViewControllerToStack:newController];
        
        [detailController showFullScreenOnTopWithCloseButtonTitle:backButtonTitle];
        
        // Extract the current document's metadata (fileMetadata) if the controller supports that property and it's non-nil
        DownloadMetadata *fileMetadata = nil;
        if ([newController respondsToSelector:@selector(fileMetadata)])
        {
            fileMetadata = [newController performSelector:@selector(fileMetadata)];
        }
        
        NSDictionary *userInfo = [NSMutableDictionary dictionary];
        if(sender != nil)
        {
            [userInfo setValue:sender forKey:@"newDetailController"];
        }
        
        if (fileMetadata != nil)
        {
            // Non-nil metadata, so use the optional userInfo dictionary with the notification
            [userInfo setValue:fileMetadata forKey:@"fileMetadata"];
        }
        
        [[NSNotificationCenter defaultCenter] postDetailViewControllerChangedNotificationWithSender:sender userInfo:userInfo];
    } 
    else 
    {
        [navController pushViewController:newController animated:YES];
    }
}

+ (void)presentModalViewController:(UIViewController *)newController withNavigation:(UINavigationController *)navController
{
    
    if(IS_IPAD || navController == nil) 
    {
        AlfrescoAppDelegate *appDelegate = (AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate];
        CustomNavigationController *newNavigation = [[[CustomNavigationController alloc] initWithRootViewController:newController] autorelease];
        newNavigation.modalPresentationStyle = newController.modalPresentationStyle;
        newNavigation.modalTransitionStyle = newController.modalTransitionStyle;
        newNavigation.navigationBar.barStyle = UIBarStyleBlackOpaque;
        [appDelegate presentModalViewController:newNavigation animated:YES];
    } else {
        AlfrescoAppDelegate *appDelegate = (AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate];
        UINavigationController *newNavigation = [[[UINavigationController alloc] initWithRootViewController:newController] autorelease];
        newNavigation.modalPresentationStyle = newController.modalPresentationStyle;
        newNavigation.modalTransitionStyle = newController.modalTransitionStyle;
        newNavigation.navigationBar.barStyle = UIBarStyleBlackOpaque;
        [appDelegate presentModalViewController:newNavigation animated:YES];
    }
    
    if([newController conformsToProtocol:@protocol(ModalViewControllerProtocol)]) {
        UIViewController<ModalViewControllerProtocol> *modalController = (UIViewController<ModalViewControllerProtocol> *) newController;
        modalController.presentedAsModal = YES;
    }
}

+ (void)presentFullScreenModalViewController:(UIViewController *)modalController
{
    AlfrescoAppDelegate *appDelegate = (AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [modalController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
    [modalController setModalPresentationStyle:UIModalPresentationFullScreen];
    [appDelegate presentModalViewController:modalController animated:YES];
    [detailController dismissPopover];
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController 
{
    if([viewController isKindOfClass:[MGSplitViewController class]]) 
    {
        MGSplitViewController *splitController = (MGSplitViewController *) viewController;
        UINavigationController *detailController = [[splitController viewControllers] objectAtIndex:1];
        //UIViewController *detailController = [detailNavController visibleViewController];
        
        if([detailController isKindOfClass:[DetailNavigationController class]]) 
        {
            [IpadSupport registerGlobalDetail:(DetailNavigationController*)detailController];
        } 
        else 
        {
            //We probably didn't initialize correctly the splitview
            NSLog(@"Detail Controller is not a DetailNavigationController");
        }
    }
}

+ (NSString *)getCurrentDetailViewControllerObjectID
{
    NSString *objectID = nil;

    if ([detailController.detailViewController isKindOfClass:[DocumentViewController class]]) 
    {
        objectID = [((DocumentViewController *)detailController.detailViewController) cmisObjectId];
    }
    else if ([detailController.detailViewController isKindOfClass:[MetaDataTableViewController class]])
    {
        objectID = [((MetaDataTableViewController *)detailController.detailViewController) cmisObjectId];
    }

    return objectID;
}

@end
