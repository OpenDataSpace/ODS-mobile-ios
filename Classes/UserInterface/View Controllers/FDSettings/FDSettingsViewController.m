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
//  FDSettingsViewController.m
//

#import "FDSettingsViewController.h"
#import "Theme.h"
#import "FDRowRenderer.h"
#import "FDSettingsPlistReader.h"
#import "IFSettingsCellController.h"
#import "PreviewCacheManager.h"
#import "MBProgressHUD.h"
#import "Utility.h"

#define kAlertTagCleanCache 10010

@interface FDSettingsViewController() {
    IFSettingsCellController *cacheCell;
}

@end

@implementation FDSettingsViewController
@synthesize settingsReader = _settingsReader;

- (void)dealloc
{
    [_settingsReader release];
    [super dealloc];
}

- (FDSettingsPlistReader *)settingsReader
{
    if(!_settingsReader)
    {
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Root" ofType:@"plist"];
        [self setSettingsReader:[[[FDSettingsPlistReader alloc] initWithPlistPath:plistPath] autorelease]]; 
    }
    return _settingsReader;
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    cacheCell = nil;
    [Theme setThemeForUINavigationBar:self.navigationController.navigationBar];

    [self setTitle:NSLocalizedString([self.settingsReader title],@"Settings View Title")];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

#pragma mark -
#pragma mark GenericViewController

- (void)constructTableGroups
{
    FDRowRenderer *rowRenderer = [[FDRowRenderer alloc] initWithSettings:self.settingsReader];
    rowRenderer.updateTarget = self;
    rowRenderer.updateAction = @selector(updateAction:);
    tableGroups = [[rowRenderer groups] retain];
	tableHeaders = [[rowRenderer headers] retain];
    [rowRenderer release];
}

-(void) updateAction:(id) sender
{
    if ([sender isKindOfClass:[IFSettingsCellController class]]) {
        cacheCell = (IFSettingsCellController*)sender;
        if ([cacheCell.userInfo isEqualToString:@"CleanCache"]) {
            [self alertCleanPreviewCache];
        }
    }
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 3) {  //force to update size.
        cell.detailTextLabel.text = [[PreviewCacheManager sharedManager] previewCahceSize];
    }
}

#pragma mark -
#pragma mark operations

- (void) alertCleanPreviewCache {
    if (IS_IPAD) {
        UIAlertView *alerView = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"confirm.cleanPreviewCache.prompt.message", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"confirm.cleanPreviewCache.prompt.cancel", @"") otherButtonTitles:NSLocalizedString(@"confirm.cleanPreviewCache.prompt.ok", @""), nil];
        alerView.tag = kAlertTagCleanCache;
        [alerView show];
    }else {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"confirm.cleanPreviewCache.prompt.message", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"confirm.cleanPreviewCache.prompt.cancel", @"") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"confirm.cleanPreviewCache.prompt.ok", @""), nil];
        actionSheet.tag = kAlertTagCleanCache;
        [actionSheet showFromToolbar:self.navigationController.toolbar];
    }
}

- (void) cleanPreviewCache {
    __block MBProgressHUD *hud = createAndShowProgressHUDForView(self.navigationController.view);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[PreviewCacheManager sharedManager] removeAllCacheFiles];
        dispatch_async(dispatch_get_main_queue(), ^{
            cacheCell.subLabel = [[PreviewCacheManager sharedManager] previewCahceSize];
            stopProgressHUD(hud);
            hud = nil;
            [self.tableView reloadData];
        });
    });
}

#pragma mark -
#pragma mark UIAlertView delegate && UIActionSheet delegate

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == kAlertTagCleanCache && buttonIndex == 1) {  //clean cache
        [self cleanPreviewCache];
    }
}

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == kAlertTagCleanCache && buttonIndex == 0) { //clean cache
        [self cleanPreviewCache];
    }
}

@end
