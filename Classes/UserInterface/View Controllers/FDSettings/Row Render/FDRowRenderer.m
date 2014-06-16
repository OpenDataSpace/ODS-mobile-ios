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
#import "FDChoiceCellController.h"
#import "IFLabelValuePair.h"
#import "FDSettingsPlistReader.h"
#import "IFValueCellController.h"
#import "IFTextCellController.h"
#import "UIDeviceHardware.h"
#import "IFTemporaryModel.h"
#import "IFSettingsCellController.h"
#import "PreviewCacheManager.h"
#import "DateInputCellController.h"
#import "TextViewCellController.h"

static NSDictionary *kStringToKeyboardTypeEnum;
static NSDictionary *kStringToAutocapitalizationTypeEnum;
static NSDictionary *kStringToAutocorrectionTypeEnum;
static NSDictionary *kStringToReturnKeyTypeEnum;

@interface FDRowRenderer (private)
- (void)generateSettings;

/*
 Processes a NSDictionary setting and generates the respective cell (IFCellController)
 that can handles the user interaction for that setting
 */
- (id<IFCellController>)processSetting:(NSDictionary *)setting;
- (id<IFCellController>)processReadonlySetting:(NSDictionary *)setting;
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
@synthesize model = _model;
@synthesize readOnlyCellClass = _readOnlyCellClass;
@synthesize readOnly = _readOnly;
@synthesize updateAction = _updateAction;
@synthesize updateTarget = _updateTarget;

- (void)dealloc
{
    [_headers release];
    [_groups release];
    [_settings release];
    [_stringsTable release];
    [_model release];
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
    kStringToReturnKeyTypeEnum = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  
                                  [NSNumber numberWithInt:UIReturnKeyDefault], @"Default",
                                  [NSNumber numberWithInt:UIReturnKeyDone], @"Done",
                                  [NSNumber numberWithInt:UIReturnKeyGo], @"Go",
                                  [NSNumber numberWithInt:UIReturnKeyNext], @"Next",
                                  [NSNumber numberWithInt:UIReturnKeySend], @"Send", nil];
}

- (id)initWithSettings:(FDSettingsPlistReader *)settingsReader
{
    self = [super init];
    if(self)
    {
        _settings = [[settingsReader allSettings] retain];
        _stringsTable = [[settingsReader stringsTable] copy];
        _model = [[FDKeychainCellModel alloc] init];
    }
    return self;
}


- (id)initWithSettings:(FDSettingsPlistReader *)settingsReader andExludedKeys:(NSArray *)keys
{
    self = [super init];
    if (self) 
    {
        _settings = [[settingsReader allSettings] retain];
        _stringsTable = [[settingsReader stringsTable] copy];
        _model = [[FDKeychainCellModel alloc] init];
    }
    return self;
}

- (id)initWithSettings:(NSArray *)settings stringsTable:(NSString *)stringsTable andModel:(id<IFCellModel>)model
{
    self = [super init];
    if(self)
    {
        _settings = [settings retain];
        _stringsTable = [stringsTable copy];
        _model = [model retain];
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
    if(!self.readOnlyCellClass)
    {
        [self setReadOnlyCellClass:[IFValueCellController class]];
    }
    
    [self setHeaders:[NSMutableArray array]];
    [self setGroups:[NSMutableArray array]];
    
    NSMutableArray *currentGroup = [NSMutableArray array];
    NSString *header;
    NSDictionary *firstSetting = nil;
    NSInteger index = 0;
    while((firstSetting = [_settings objectAtIndex:index]))
    {
        // We can have a setting that only are available on Read Only mode
        // and we need to adjust the first setting in the case the first settings is read only
        if(self.readOnly || ![[firstSetting objectForKey:@"OnlyOnReadOnly"] boolValue])
        {
            break;
        }
        index++;
    }
    
    NSBundle *bundle = [NSBundle mainBundle];
    
    // In the special case for starting the setting generation
    // the first group header is either an empty string, or if the first
    // setting is a group specifier, then the header is the title from that setting
    if([self isGroupSetting:firstSetting])
    {
        header = NSLocalizedStringFromTableInBundle([firstSetting objectForKey:@"Title"], _stringsTable, bundle, @"");
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
        NSString *key = [setting objectForKey:@"Key"];
        BOOL overrideReadOnly = [[setting objectForKey:@"OverrideReadOnly"] boolValue];
        if (nil == key) 
        {
            key = @"";
        }
        BOOL isHidden = NO;
        BOOL displayOnCellularDeviceOnly = NO;
        NSArray *allKeys = [setting allKeys];
        if ([allKeys containsObject:@"isHidden"])
        {
            isHidden = (nil != [setting objectForKey:@"isHidden"]) ? [[setting objectForKey:@"isHidden"]boolValue] : NO;
        }
        if ([allKeys containsObject:@"displayOnCellularOnly"])
        {
            displayOnCellularDeviceOnly = ([setting objectForKey:@"displayOnCellularOnly"] != nil) ? [[setting objectForKey:@"displayOnCellularOnly"] boolValue] : NO;
        }
        // If the setting is a group we have to add a new header and a new group
        if([self isGroupSetting:setting])
        {
            header = NSLocalizedStringFromTableInBundle([setting objectForKey:@"Title"], _stringsTable, bundle, @"");
            [self.headers addObject:header];
            currentGroup = [NSMutableArray array];
            [self.groups addObject:currentGroup];
        } 
        else if (isHidden) 
        {
            id defaultValue = [setting objectForKey:@"DefaultValue"];
            [self.model setObject:defaultValue forKey:key];
        }
        else if (displayOnCellularDeviceOnly)
        {
            UIDeviceHardware *deviceHardware = [[UIDeviceHardware alloc] init];
            if ([deviceHardware cellularHardwareAvailable])
            {
                [currentGroup addObject:[self processSetting:setting]];
            }
            else
            {
                id defaultValue = [setting objectForKey:@"DefaultValue"];
                [self.model setObject:defaultValue forKey:key];
            }
            [deviceHardware release];
        }
        else if(self.readOnly && !overrideReadOnly)
        {
            [currentGroup addObject:[self processReadonlySetting:setting]];
        }
        else if(self.readOnly || ![[setting objectForKey:@"OnlyOnReadOnly"] boolValue])
        {   
            [currentGroup addObject:[self processSetting:setting]];
        }
    }
}


- (id<IFCellController>)processSetting:(NSDictionary *)setting
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *title = NSLocalizedStringFromTableInBundle([setting objectForKey:@"Title"], _stringsTable, bundle, @"Title for the setting");
    NSString *key = [setting objectForKey:@"Key"];
    NSString *type = [setting objectForKey:@"Type"];
    id defaultValue = [setting objectForKey:@"DefaultValue"];
    
    //Assigning the default value if the default is not set.
    if(key && ![self.model objectForKey:key])
    {
        [self.model setObject:defaultValue forKey:key];
    }
    
    if([type isEqualToString:@"PSToggleSwitchSpecifier"])
    {
        IFSwitchCellController *cell = [[[IFSwitchCellController alloc] initWithLabel:title atKey:key inModel:self.model] autorelease];
        [cell setBackgroundColor:[UIColor whiteColor]];
        [cell setUpdateAction:self.updateAction];
        [cell setUpdateTarget:self.updateTarget];
        return cell;
    } 
    else if([type isEqualToString:@"PSMultiValueSpecifier"])
    {
        NSArray *titles = [setting objectForKey:@"Titles"];
        NSArray *values = [setting objectForKey:@"Values"];
        
        titles = [self localizeArray:titles];
        NSArray *choices = [self labelPairWithValues:values andTitles:titles];
        FDChoiceCellController *cell = [[[FDChoiceCellController alloc] initWithLabel:title andChoices:choices atKey:key inModel:self.model] autorelease];
        [cell setBackgroundColor:[UIColor whiteColor]];
        [cell setUpdateAction:self.updateAction];
        [cell setUpdateTarget:self.updateTarget];
        return cell;
        
    }
    else if ([type isEqualToString:@"PSTitleValueSpecifier"])
    {
        if ([defaultValue isEqualToString:@"CleanCache"]) {  //TODO://for clean cache cell
            IFSettingsCellController *cell = [[IFSettingsCellController alloc] initWithLabel:title subLabel:[[PreviewCacheManager sharedManager] previewCahceSize] withAction:self.updateAction onTarget:self.updateTarget];
            [cell setBackgroundColor:[UIColor whiteColor]];
            
            cell.userInfo = defaultValue;
            return cell;
        }else {
            IFValueCellController *cell = [[[IFValueCellController alloc] initWithLabel:title atKey:key inModel:self.model] autorelease];
            [cell setBackgroundColor:[UIColor whiteColor]];
            return cell;
        }
    }
    else if ([type isEqualToString:@"PSTextFieldSpecifier"])
    {
        BOOL isSecure = [[setting objectForKey:@"IsSecure"] boolValue];
        NSString *keyboardType = [setting objectForKey:@"KeyboardType"];
        NSString *autocapitalizationType = [setting objectForKey:@"AutocapitalizationType"];
        NSString *autocorrectionType = [setting objectForKey:@"AutocorrectionType"];
        NSString *returnKeyType = [setting objectForKey:@"ReturnKeyType"];
        NSString *placeholder = NSLocalizedStringFromTableInBundle([setting objectForKey:@"Placeholder"], _stringsTable, bundle, @"");
        IFTextCellController *cell = [[[IFTextCellController alloc] initWithLabel:title andPlaceholder:placeholder atKey:key inModel:self.model] autorelease];
        [cell setSecureTextEntry:isSecure];
        [cell setBackgroundColor:[UIColor whiteColor]];
        [cell setEditChangedAction:self.updateAction];
        [cell setUpdateTarget:self.updateTarget];
        
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
        
        if(returnKeyType && [kStringToReturnKeyTypeEnum objectForKey:returnKeyType])
        {
            [cell setReturnKeyType:[[kStringToReturnKeyTypeEnum objectForKey:returnKeyType] intValue]];
        }
        return cell;
    }else if ([type isEqualToString:@"PSDatePickerSpecifier"]) {
        DateInputCellController *cell = [[[DateInputCellController alloc] initWithLabel:title atKey:key inModel:self.model] autorelease];
        
        return cell;
    }else if ([type isEqualToString:@"PSTextViewSpecifier"]) {
        NSString *keyboardType = [setting objectForKey:@"KeyboardType"];
        NSString *autocapitalizationType = [setting objectForKey:@"AutocapitalizationType"];
        NSString *autocorrectionType = [setting objectForKey:@"AutocorrectionType"];
        NSString *returnKeyType = [setting objectForKey:@"ReturnKeyType"];
        
        TextViewCellController *cell = [[[TextViewCellController alloc] initWithLabel:title andPlaceholder:@"" atKey:key inModel:self.model] autorelease];
        [cell setBackgroundColor:[UIColor whiteColor]];
        [cell setEditChangedAction:self.updateAction];
        [cell setUpdateTarget:self.updateTarget];
        
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
        
        if(returnKeyType && [kStringToReturnKeyTypeEnum objectForKey:returnKeyType])
        {
            [cell setReturnKeyType:[[kStringToReturnKeyTypeEnum objectForKey:returnKeyType] intValue]];
        }
        
        return cell;
    }
    // TODO: Render the type PSSliderSpecifier configured in the Root.plist
    
    return nil;
}

- (id<IFCellController>)processReadonlySetting:(NSDictionary *)setting
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *title = NSLocalizedStringFromTableInBundle([setting objectForKey:@"Title"], _stringsTable, bundle, @"Title for the setting");
    NSString *key = [setting objectForKey:@"ReadOnlyKey"]? [setting objectForKey:@"ReadOnlyKey"] : [setting objectForKey:@"Key"];
    BOOL isSecure = [[setting objectForKey:@"IsSecure"] boolValue];
    id defaultValue = [setting objectForKey:@"DefaultValue"];
    
    //Assigning the default value if the default is not set.
    if(key && ![self.model objectForKey:key])
    {
        [self.model setObject:defaultValue forKey:key];
    }
    
    if(isSecure)
    {
        key = [NSString stringWithFormat:@"%@_secure", key];
        IFTemporaryModel *model = (IFTemporaryModel *)self.model;
        [self.model setObject:[model.dictionary objectForKey:@"securePassword"] forKey:key];
    }
    
    id cell = [[[self.readOnlyCellClass alloc] initWithLabel:title atKey:key inModel:self.model] autorelease];
    if([cell respondsToSelector:@selector(setBackgroundColor:)])
    {
        [cell setBackgroundColor:[UIColor whiteColor]];
    }
    return cell;
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
        id value = [values objectAtIndex:i];
        if([value respondsToSelector:@selector(stringValue)])
        {
            value = [value stringValue];
        }
        IFLabelValuePair *labelValuePair = [[IFLabelValuePair alloc] initWithLabel:title andValue:value];
        [labelPairArray addObject:labelValuePair];
        [labelValuePair release];
    }
    return labelPairArray;
}

- (void)clearResults
{
    [self setHeaders:nil];
    [self setGroups:nil];
}

#pragma mark - Property getters
- (NSMutableArray *)headers
{
    if(!_headers)
    {
        [self generateSettings];
    }
    return _headers;
}

- (NSMutableArray *)groups
{
    if(!_groups)
    {
        [self generateSettings];
    }
    return _groups;
}

- (void)setReadOnlyCellClass:(Class)readOnlyCellClass
{
    if([readOnlyCellClass conformsToProtocol:@protocol(IFCellController)])
    {
        _readOnlyCellClass = readOnlyCellClass;
    }
}
@end
