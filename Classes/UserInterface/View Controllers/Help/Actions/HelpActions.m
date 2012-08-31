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
 *
 * ***** END LICENSE BLOCK ***** */
//
//  HelpActions.m
//

#import "HelpActions.h"
#import "AlfrescoAppDelegate.h"
#import "DocumentViewController.h"
#import "DownloadMetadata.h"
#import "IpadSupport.h"
#import "Utility.h"

@implementation HelpActions

#pragma mark - FDTableViewActionsProtocol methods
/**
 * The user either selected a help guide, or to view the Welcome Screen.
 */
- (void)rowWasSelectedAtIndexPath:(NSIndexPath *)indexPath withDatasource:(NSDictionary *)datasource andController:(FDGenericTableViewController *)controller
{
    if (indexPath.section == 0)
    {
        // Show help guide
        NSArray *helpGuides = [datasource objectForKey:@"helpGuides"];
        if([helpGuides count] > indexPath.row)
        {
            NSDictionary *helpGuide = [helpGuides objectAtIndex:indexPath.row];
            [self showHelpGuide:helpGuide withNavigationController:[controller navigationController]];
        }
        [controller.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    else if (indexPath.section == 1)
    {
        // Show Welcome Screen
        AlfrescoAppDelegate *appDelegate = (AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate];
        if ([appDelegate respondsToSelector:@selector(forcePresentHomeScreenController)])
        {
            [appDelegate performSelector:@selector(forcePresentHomeScreenController)];
        }
    }
}

#pragma mark - Utility

- (void)showHelpGuide:(NSDictionary *)helpGuide withNavigationController:(UINavigationController *)navigationController
{
    NSString *fileName = [helpGuide objectForKey:@"filename"];
    NSString *title = NSLocalizedString([helpGuide objectForKey:@"title"], @"Help guide title");

    DownloadMetadata *downloadMetadata = [[DownloadMetadata alloc] init];
    [downloadMetadata setFilename:title];

	DocumentViewController *viewController = [[DocumentViewController alloc] initWithNibName:kFDDocumentViewController_NibName
                                                                                      bundle:[NSBundle mainBundle]];
    
    [viewController setFileName:fileName];
    [viewController setFilePath:[[NSBundle mainBundle] pathForResource:fileName ofType:nil]];
    [viewController setContentMimeType:mimeTypeForFilename(fileName)];
	[viewController setHidesBottomBarWhenPushed:NO];
    [viewController setIsDownloaded:YES];
    [viewController setShowTrashButton:NO];
    [viewController setFileMetadata:downloadMetadata];
    [viewController setShowReviewButton:NO];
    
    [IpadSupport pushDetailController:viewController withNavigation:navigationController andSender:self dismissPopover:YES];

    [downloadMetadata release];
	[viewController release];
}

@end
