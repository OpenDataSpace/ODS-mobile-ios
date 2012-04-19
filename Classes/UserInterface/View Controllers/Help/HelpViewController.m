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
//  HelpViewController.m
//

#import "HelpViewController.h"
#import "FDGenericTableViewPlistReader.h"
#import "TableCellViewController.h"

@implementation HelpViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self setSettingsReader:[[[FDGenericTableViewPlistReader alloc] initWithPlistPath:[[NSBundle mainBundle] pathForResource:@"HelpConfiguration" ofType:@"plist"]] autorelease]];
        [self setTableStyle:UITableViewStyleGrouped];
    }
    return self;
}

+ (HelpViewController *)genericTableViewWithPlistPath:(NSString *)plistPath andTableViewStyle:(UITableViewStyle)tableStyle
{
    FDGenericTableViewPlistReader *settingsReader = [[[FDGenericTableViewPlistReader alloc] initWithPlistPath:plistPath] autorelease];
    HelpViewController *controller = [[HelpViewController alloc] init];
    [controller setTableStyle:tableStyle];
    [controller setSettingsReader:settingsReader];
    return [controller autorelease];
}

@end
