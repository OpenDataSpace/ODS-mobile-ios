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
//  AccountAutocreateActions.m
//

#import "AccountAutocreateActions.h"
#import "AccountInfo.h"
#import "AlfrescoAppDelegate.h"

@implementation AccountAutocreateActions

#pragma mark - FDTableViewActionsProtocol methods

- (void)rowWasSelectedAtIndexPath:(NSIndexPath *)indexPath withDatasource:(NSDictionary *)datasource andController:(AccountAutocreateViewController *)controller
{
    if (indexPath.section == 0)
    {
        // Yes option
        AccountInfo *account = [[[AccountInfo alloc] init] autorelease];
        [account setProtocol:kFDHTTP_Protocol];
        [account setPort:kFDHTTP_DefaultPort];
        [account setUsername:[datasource objectForKey:@"userName"]];

        AccountViewController *newAccountController = [[[AccountViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
        [newAccountController setIsEdit:YES];
        [newAccountController setIsNew:YES];
        [newAccountController setDelegate:controller];

        BOOL isCloud = [[datasource valueForKey:@"isCloud"] boolValue];
        if (isCloud)
        {
            //Set the default values for alfresco cloud
            NSString *path = [[NSBundle mainBundle] pathForResource:kDefaultAccountsPlist_FileName ofType:@"plist"];
            NSDictionary *defaultAccountsPlist = [[[NSDictionary alloc] initWithContentsOfFile:path] autorelease];
            NSDictionary *defaultCloudValues = [defaultAccountsPlist objectForKey:@"kDefaultCloudAccountValues"];
            
            [account setVendor:[defaultCloudValues objectForKey:@"Vendor"]];
            [account setDescription:[defaultCloudValues objectForKey:@"Description"]];
            [account setProtocol:[defaultCloudValues objectForKey:@"Protocol"]];
            [account setHostname:[defaultCloudValues objectForKey:@"Hostname"]];
            [account setPort:[defaultCloudValues objectForKey:@"Port"]];
            [account setServiceDocumentRequestPath:[defaultCloudValues objectForKey:@"ServiceDocumentRequestPath"]];
            [account setMultitenant:[defaultCloudValues objectForKey:@"Multitenant"]];
        }
        else
        {
            NSURL *repositoryUrl = [datasource objectForKey:@"repositoryUrl"];
            // Populate the account with what we've been passed from the inbound URL parameters
            [account setHostname:repositoryUrl.host];
            [account setProtocol:[repositoryUrl.scheme uppercaseString]];
            NSString *defaultPort = [repositoryUrl.port stringValue];
            if (defaultPort == nil)
            {
                defaultPort = ([repositoryUrl.scheme isEqualToCaseInsensitiveString:kFDHTTP_Protocol] ? kFDHTTP_DefaultPort : kFDHTTPS_DefaultPort);
            }
            [account setPort:defaultPort];
        }

        [newAccountController setAccountInfo:account];

        if (IS_IPAD)
        {
            // Grow the view back
            CGRect bounds = [(NSValue *)[datasource objectForKey:@"originalBounds"] CGRectValue];
            
            [UIView animateWithDuration:.3f
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 [controller.navigationController.view.superview setBounds:bounds];
                             }
                             completion:^(BOOL finished){
                                 [controller.navigationController pushViewController:newAccountController animated:YES];
                             }];
        }
        else
        {
            [controller.navigationController pushViewController:newAccountController animated:YES];
        }
    }
    else if (indexPath.section == 1)
    {
        // Ensure the HomeScreen can be shown again if required. Not the best place for this, but we don't have
        // scope to access a delegate with the current FDGenericTableView framework.
        AlfrescoAppDelegate *appDelegate = (AlfrescoAppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate setSuppressHomeScreen:NO];

        // Cancelled the account creation
        [controller dismissViewControllerAnimated:YES completion:^{
            NSURL *browserUrl = [datasource objectForKey:@"browserUrl"];
            if (browserUrl)
            {
                [[UIApplication sharedApplication] openURL:browserUrl];
            }
        }];
    }
}

@end
