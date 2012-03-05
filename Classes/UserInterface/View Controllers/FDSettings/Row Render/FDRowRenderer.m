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
//  FDRowRenderer.m
//

#import "FDRowRenderer.h"
#import "IFCellController.h"
#import "FDKeychainCellModel.h"
#import "IFSwitchCellController.h"
#import "IFChoiceCellController.h"
#import "IFLabelValuePair.h"
#import "FDSettingsPlistReader.h"
#import "IFValueCellController.h"
#import "IFTextCellController.h"

static NSDictionary *kStringToKeyboardTypeEnum;
static NSDictionary *kStringToAutocapitalizationTypeEnum;
static NSDictionary *kStringToAutocorrectionTypeEnum;

@interface FDRowRenderer (private)
- (void)generateSettings;

/*
 Processes a NSDictionary setting and generates the respective cell (IFCellController)
 that can handles the user interaction for that setting
 */
- (id<IFCellController>)processSetting:(NSDictionary *)setting;
- (BOOL)isGroupSetting:(NSDictionary *)setting;
/*
 Returns an array with the localized strings of the keys in the arrayOfKeys
 */
- (NSArray *)localizeArray:(NSArray *)arrayOfKeys;
/*
 Returns an array with the IFLabelValuePair objects containing both value and title
 */
- (NSArray *)labelPairWithValues:(NSArray *)values andTitles:(NSArray *)titles;
@end

@implementation FDRowRenderer
@synthesize headers = _headers;
@synthesize groups = _groups;

- (void)dealloc
{
    [_settings release];
    [_stringsTable release];
    [super dealloc];
}

+ (void)initialize
{
    kStringToKeyboardTypeEnum = [[NSDictionary alloc] initWithObjectsAndKeys:
                                 [NSNumber numberWithInt:UIKeyboardTypeAlphabet], @"Alphabet",
                                 [NSNumber numberWithInt:UIKeyboardTypeNumbersAndPunctuation], @"NumbersAndPunctuation",
                                 [NSNumber numberWithInt:UIKeyboardTypeNumberPad], @"NumberPad",
                                 [NSNumber numberWithInt:UIKeyboardTypeEmailAddress], @"EmailAddress",
                                 [NSNumber numberWithInt:UIKeyboardTypeURL], @"URL",nil];
    
    kStringToAutocapitalizationTypeEnum = [[NSDictionary alloc] initWithObjectsAndKeys:
                                 [NSNumber numberWithInt:UITextAutocapitalizationTypeNone], @"None",
                                 [NSNumber numberWithInt:UITextAutocapitalizationTypeSentences], @"Sentences",
                                 [NSNumber numberWithInt:UITextAutocapitalizationTypeWords], @"Words",
                                 [NSNumber numberWithInt:UITextAutocapitalizationTypeAllCharacters], @"AllCharacters",nil];
    
    kStringToAutocorrectionTypeEnum = [[NSDictionary alloc] initWithObjectsAndKeys:
                                           [NSNumber numberWithInt:UITextAutocorrectionTypeDefault], @"Default",
                                           [NSNumber numberWithInt:UITextAutocorrectionTypeNo], @"No",
                                           [NSNumber numberWithInt:UITextAutocorrectionTypeYes], @"Yes",nil];
}

- (id)initWithSettings:(FDSettingsPlistReader *)settingsReader
{
    self = [super init];
    if(self)
    {
        _settings = [[settingsReader allSettings] retain];
        _stringsTable = [[settingsReader stringsTable] copy];
        [self generateSettings];
    }
    return self;
}

- (void)generateSettings
{
    // IF the settings is empty we cannot generate the settings
    if([_settings count] == 0)
    {
        return;
    }
    [self setHeaders:[NSMutableArray array]];
    [self setGroups:[NSMutableArray array]];
    
    NSMutableArray *currentGroup = [NSMutableArray array];
    NSString *header;
    NSDictionary *firstSetting = [_settings objectAtIndex:0];
    NSInteger index = 0;
    
    // In the special case for starting the setting generation
    // the first group header is either an empty string, or if the first
    // setting is a group specifier, then the header is the title from that setting
    if([self isGroupSetting:firstSetting])
    {
        header = [firstSetting objectForKey:@"Title"];
        index++;
    }
    else
    {
        header = @"";
    }
    
    [self.headers addObject:header];
    [self.groups addObject:currentGroup];
    NSDictionary *setting;
    for(;index < [_settings count]; index++)
    {
        setting = [_settings objectAtIndex:index];
        // If the setting is a group we have to add a new header and a new group
        if([self isGroupSetting:setting])
        {
            header = [setting objectForKey:@"Title"];
            [self.headers addObject:header];
            currentGroup = [NSMutableArray array];
            [self.groups addObject:currentGroup];
        } 
        else
        {
            [currentGroup addObject:[self processSetting:setting]];
        }
    }
}

- (id<IFCellController>)processSetting:(NSDictionary *)setting
{
    id<IFCellModel> model = [[[FDKeychainCellModel alloc] init] autorelease];
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *title = NSLocalizedStringFromTableInBundle([setting objectForKey:@"Title"], _stringsTable, bundle, @"Title for the setting");
    NSString *key = [setting objectForKey:@"Key"];
    NSString *type = [setting objectForKey:@"Type"];
    id defaultValue = [setting objectForKey:@"DefaultValue"];
    
    //Assigning the default value if the default is not set.
    if(key && ![[FDKeychainUserDefaults standardUserDefaults] objectForKey:key])
    {
        [[FDKeychainUserDefaults standardUserDefaults] setObject:defaultValue forKey:key];
    }
    
    if([type isEqualToString:@"PSToggleSwitchSpecifier"])
    {
        IFSwitchCellController *cell = [[[IFSwitchCellController alloc] initWithLabel:title atKey:key inModel:model] autorelease];
        return cell;
    } 
    else if([type isEqualToString:@"PSMultiValueSpecifier"])
    {
        NSArray *titles = [setting objectForKey:@"Titles"];
        NSArray *values = [setting objectForKey:@"Values"];
        titles = [self localizeArray:titles];
        NSArray *choices = [self labelPairWithValues:values andTitles:titles];
        IFChoiceCellController *cell = [[[IFChoiceCellController alloc] initWithLabel:title andChoices:choices atKey:key inModel:model] autorelease];
        return cell;
    }
    else if ([type isEqualToString:@"PSTitleValueSpecifier"])
    {
        IFValueCellController *cell = [[[IFValueCellController alloc] initWithLabel:title atKey:key inModel:model] autorelease];
        return cell;
    }
    else if ([type isEqualToString:@"PSTextFieldSpecifier"])
    {
        BOOL isSecure = [[setting objectForKey:@"IsSecure"] boolValue];
        NSString *keyboardType = [setting objectForKey:@"KeyboardType"];
        NSString *autocapitalizationType = [setting objectForKey:@"AutocapitalizationType"];
        NSString *autocorrectionType = [setting objectForKey:@"AutocorrectionType"];
        IFTextCellController *cell = [[[IFTextCellController alloc] initWithLabel:title andPlaceholder:nil atKey:key inModel:model] autorelease];
        [cell setSecureTextEntry:isSecure];
        
        if(keyboardType && [kStringToKeyboardTypeEnum objectForKey:keyboardType])
        {
            [cell setKeyboardType:[[kStringToKeyboardTypeEnum objectForKey:keyboardType] intValue]];
        }
        
        if(autocapitalizationType && [kStringToAutocapitalizationTypeEnum objectForKey:autocapitalizationType])
        {
            [cell setAutocapitalizationType:[[kStringToAutocapitalizationTypeEnum objectForKey:autocapitalizationType] intValue]];
        }
        
        if(autocorrectionType && [kStringToAutocorrectionTypeEnum objectForKey:autocorrectionType])
        {
            [cell setAutocorrectionType:[[kStringToAutocorrectionTypeEnum objectForKey:autocorrectionType] intValue]];
        }
        return cell;
    }
    // TODO: Render other type of settings
    
    return nil;
}

- (BOOL)isGroupSetting:(NSDictionary *)setting
{
    return [[setting objectForKey:@"Type"] isEqualToString:@"PSGroupSpecifier"];
}

- (NSArray *)localizeArray:(NSArray *)arrayOfKeys;
{
    NSMutableArray *localizedArray = [NSMutableArray arrayWithCapacity:[arrayOfKeys count]];
    for(NSString *key in arrayOfKeys)
    {
        NSBundle *bundle = [NSBundle mainBundle];
        [localizedArray addObject:NSLocalizedStringFromTableInBundle(key, _stringsTable, bundle, @"Title for the key")];
    }
    return [NSArray arrayWithArray:localizedArray];
}

- (NSArray *)labelPairWithValues:(NSArray *)values andTitles:(NSArray *)titles
{
    NSMutableArray *labelPairArray = [NSMutableArray arrayWithCapacity:[values count]];
    
    for(NSInteger i = 0; i<[values count]; i++)
    {
        NSString *title = [titles objectAtIndex:i];
        NSString *value = [[values objectAtIndex:i] stringValue];
        IFLabelValuePair *labelValuePair = [[IFLabelValuePair alloc] initWithLabel:title andValue:value];
        [labelPairArray addObject:labelValuePair];
        [labelValuePair release];
    }
    return labelPairArray;
}
@end
