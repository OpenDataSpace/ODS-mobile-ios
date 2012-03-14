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
//  FDGenericTableViewPlistReader.m
//

#import "FDGenericTableViewPlistReader.h"

@interface FDGenericTableViewPlistReader (private)
- (id)objectWithClassName:(NSString *)className;
@end

@implementation FDGenericTableViewPlistReader
@synthesize plistDictionary = _plistDictionary;

static NSDictionary *kBarButtonSystemItems;
static NSDictionary *kTableViewEditingStyles;

- (void)dealloc
{
    [_plistDictionary release];
    [super dealloc];
}

- (id)initWithPlistPath:(NSString *)plistPath
{
    self = [super init];
    if(self)
    {
        [self setPlistDictionary:[NSDictionary dictionaryWithContentsOfFile:plistPath]];
    }
    return self;
}

+ (void)initialize
{
    //TODO: Add all bar button system from the UIBarButtonSystemItem enumeration
    kBarButtonSystemItems = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:UIBarButtonSystemItemAdd], @"Add", nil];
    kTableViewEditingStyles = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:UITableViewCellEditingStyleNone], @"None",
                               [NSNumber numberWithInt:UITableViewCellEditingStyleInsert], @"Insert",
                               [NSNumber numberWithInt:UITableViewCellEditingStyleDelete], @"Delete", nil];
}

- (NSString *)title
{
    return NSLocalizedString([self.plistDictionary objectForKey:@"FDControllerTitle"], @"Controller title");
}

- (UIBarButtonItem *)rightBarButton
{
    NSDictionary *barButtonMeta =  [self.plistDictionary objectForKey:@"FDRightBarButton"];
    //TODO: Support the initWithTitle:style:target:action: constructor only the initWithBarButtonSystemItem:target:action: is supported
    if([[barButtonMeta objectForKey:@"FDBarButtonType"] isEqualToString:@"System"])
    {
        //We assume that there's a button system
        NSString *systemItemMeta = [barButtonMeta objectForKey:@"FDBarButtonSystemItem"];
        NSInteger systemItem = [[kBarButtonSystemItems objectForKey:systemItemMeta] intValue];
        UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:systemItem target:nil action:nil];
        return [barButton autorelease];
    }
    
    return nil;
}

- (UITableViewCellEditingStyle)editingStyle
{
    NSString *editingStyleMeta = [self.plistDictionary objectForKey:@"FDTableViewEditingStyle"];
    NSNumber *editingStyle = [kTableViewEditingStyles objectForKey:editingStyleMeta];
    if(!editingStyle)
    {
        return UITableViewCellEditingStyleNone;
    } 
    else 
    {
        return [editingStyle intValue];
    }
}

- (id<FDDatasourceProtocol>)datasourceDelegate
{
    NSString *className = [self.plistDictionary objectForKey:@"FDDatasourceDelegate"];
    return [self objectWithClassName:className];
}

- (id<FDRowRenderProtocol>)rowRenderDelegate
{
    NSString *className = [self.plistDictionary objectForKey:@"FDRowRenderDelegate"];
    return [self objectWithClassName:className];
}

- (id<FDTableViewActionsProtocol>)actionsDelegate
{
    NSString *className = [self.plistDictionary objectForKey:@"FDActionsDelegate"];
    return [self objectWithClassName:className];
}

#pragma mark - Utility Methods
- (id)objectWithClassName:(NSString *)className
{
    if(className)
    {
        return [[[NSClassFromString(className) alloc] init] autorelease];
    } 
    else
    {
        return nil;
    }
     
}
@end
