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
//  AwaitingVerificationViewController.m
//

#import "AwaitingVerificationViewController.h"
#import "AttributedLabelCellController.h"
#import "AccountManager.h"
#import "AccountInfo.h"
#import "AppProperties.h"
#import "UIColor+Theme.h"

@implementation AwaitingVerificationViewController
@synthesize selectedAccountUUID = _selectedAccountUUID;

- (void)dealloc
{
    [_selectedAccountUUID release];
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setTitle:NSLocalizedString(@"awaitingverification.title", @"Alfresco Cloud")];
}

- (void)constructTableGroups
{
    AccountInfo *account = [[AccountManager sharedManager] accountInfoForUUID:self.selectedAccountUUID];
    AttributedLabelCellController *textCell = [[AttributedLabelCellController alloc] init];
    [textCell setTextColor:[UIColor colorWIthHexRed:74.0f green:136.0f blue:218.0f alphaTransparency:1]];
    [textCell setBackgroundColor:[UIColor colorWIthHexRed:255.0f green:229.0f blue:153.0f alphaTransparency:1]];
    [textCell setText:[NSString stringWithFormat:NSLocalizedString(@"awaitingverification.description", @"Account Awaiting Email Verification..."), account.firstName, account.lastName, account.username]];
    
    [textCell setBlock:^ (NSMutableAttributedString *mutableAttributedString) 
     {
         NSRange titleRange = [[mutableAttributedString string] rangeOfString:NSLocalizedString(@"awaitingverification.description.title", @"")];
         UIFont *boldSystemFont = [UIFont boldSystemFontOfSize:20]; 
         CTFontRef font = CTFontCreateWithName((CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
         if (font) {
             [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(id)font range:titleRange];
             CFRelease(font);
         }
         return mutableAttributedString;
     }];
    
    NSString *customerCareUrl = [AppProperties propertyForKey:kAlfrescoCustomerCareUrl];
    NSRange textRange = [textCell.text rangeOfString:@"Alfresco" options:NSBackwardsSearch];
    if (textRange.length > 0) 
    {
        [textCell addLinkToURL:[NSURL URLWithString:customerCareUrl] withRange:textRange];
        [textCell setDelegate:self];
    }
    
    NSArray *textGroup = [NSArray arrayWithObject:textCell];
    tableGroups = [[NSArray arrayWithObject:textGroup] retain];
    
    [textCell release];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    [[UIApplication sharedApplication] openURL:url];
}

@end
