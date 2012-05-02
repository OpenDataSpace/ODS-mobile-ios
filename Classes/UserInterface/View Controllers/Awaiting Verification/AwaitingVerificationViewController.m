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
#import "IFButtonCellController.h"
#import "NewCloudAccountHTTPRequest.h"
#import "AccountStatusHTTPRequest.h"
#import "IpadSupport.h"
#import "Utility.h"

NSInteger const kDeleteAccountAlert = 0;
NSInteger const kVerifiedAccountAlert = 1;

@interface AwaitingVerificationViewController ()
- (void)showAccountActiveAlert;
@end

@implementation AwaitingVerificationViewController
@synthesize isSettings = _isSettings;
@synthesize resendEmailRequest = _resendEmailRequest;
@synthesize accountStatusRequest = _accountStatusRequest;
@synthesize selectedAccountUUID = _selectedAccountUUID;
@synthesize HUD = _HUD;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_resendEmailRequest release];
    [_accountStatusRequest release];
    [_selectedAccountUUID release];
    [_HUD release];
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
    
    //We remove this object as an observer first so we avoid readding the object if the ViewController gets reloaded
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAccountListUpdated:) 
                                                         name:kNotificationAccountListUpdated object:nil];
}

/*
 Creates a group of cells for the account status description/instructions.
 It is actually just one AttributedLabelCellController with the text, a bigger font size for the title
 and a link to the Alfresco customer team
 */
- (NSArray *)descriptionGroup:(AccountInfo *)account
{
    AttributedLabelCellController *textCell = [[AttributedLabelCellController alloc] init];
    [textCell setTextColor:[UIColor blackColor]];
    // Note: iOS < 5 has the grouped cell background color as 0xffffff - won't fix.
    [textCell setBackgroundColor:[UIColor whiteColor]];
    [textCell setTextAlignment:UITextAlignmentLeft];
    [textCell setText:[NSString stringWithFormat:NSLocalizedString(@"awaitingverification.description", @"Account Awaiting Email Verification..."), account.username]];
    
    [textCell setBlock:^(NSMutableAttributedString *mutableAttributedString) 
    {
        NSRange titleRange = [[mutableAttributedString string] rangeOfString:NSLocalizedString(@"awaitingverification.description.title", @"")];
        NSRange helpRange = [[mutableAttributedString string] rangeOfString:NSLocalizedString(@"awaitingverification.description.subtitle", @"")];
        UIFont *boldSystemFont = [UIFont boldSystemFontOfSize:20]; 
        CTFontRef font = CTFontCreateWithName((CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
        if (font)
        {
            [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(id)font range:titleRange];
            [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(id)font range:helpRange];
            CFRelease(font);
        }
        return mutableAttributedString;
    }];
    
    NSString *customerCareUrl = [AppProperties propertyForKey:kAlfrescoCustomerCareUrl];
    NSRange textRange = [textCell.text rangeOfString:NSLocalizedString(@"awaitingverification.description.customerCare", @"") options:NSBackwardsSearch];
    if (textRange.length > 0) 
    {
        [textCell addLinkToURL:[NSURL URLWithString:customerCareUrl] withRange:textRange];
        [textCell setDelegate:self];
    }
    
    NSArray *descriptionGroup = [NSArray arrayWithObject:textCell];
    [textCell release];
    return descriptionGroup;
}

/*
 Creates a group of cells for the account status description/instructions.
 It is actually just one IFButtonCellController with the action to refresh the account
 */
- (NSArray *)refreshGroup
{
    IFButtonCellController *refreshCell = [[[IFButtonCellController alloc] initWithLabel:NSLocalizedString(@"awaitingverification.buttons.refresh", @"Refresh")
                                                                                      withAction:@selector(refreshAccount:) 
                                                                                        onTarget:self] autorelease];
    return [NSArray arrayWithObject:refreshCell];
}

/*
 Creates a group of cells for the account status description/instructions.
 It is actually just one IFButtonCellController with the action to resend the verification email
 */
- (NSArray *)resendEmailGroup
{
    IFButtonCellController *resendEmailCell = [[[IFButtonCellController alloc] initWithLabel:NSLocalizedString(@"awaitingverification.buttons.resendEmail", @"Browse Documents")
                                                                                      withAction:@selector(resendEmail:) 
                                                                                        onTarget:self] autorelease];
    return [NSArray arrayWithObject:resendEmailCell];
}

/*
 Creates a group of cells for the account status description/instructions.
 It is actually just one IFButtonCellController with the action to delete de account
 */
- (NSArray *)deleteAccountGroup
{
    IFButtonCellController *deleteAccountCell = [[[IFButtonCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.buttons.delete", @"Delete Account")
                                                                                    withAction:@selector(promptDeleteAccount:) 
                                                                                      onTarget:self] autorelease];
    [deleteAccountCell setBackgroundColor:[UIColor redColor]];
    [deleteAccountCell setTextColor:[UIColor whiteColor]];
    return [NSArray arrayWithObject:deleteAccountCell];
}

- (void)constructTableGroups
{
    AccountInfo *account = [[AccountManager sharedManager] accountInfoForUUID:self.selectedAccountUUID];
    if(!self.isSettings)
    {
        tableGroups = [[NSArray arrayWithObject:[self descriptionGroup:account]] retain];
    }
    else
    {
        tableGroups = [[NSArray arrayWithObjects:[self descriptionGroup:account], [self refreshGroup], [self resendEmailGroup], [self deleteAccountGroup], nil] retain];
    }
}

#pragma mark - TTTAttributedLabelDelegate methods
- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    [[UIApplication sharedApplication] openURL:url];
}

#pragma mark - Button actions
- (void)refreshAccount:(id)sender
{
    [self startHUD];
    AccountInfo *accountInfo = [[AccountManager sharedManager] accountInfoForUUID:self.selectedAccountUUID];
    AccountStatusHTTPRequest *request = [AccountStatusHTTPRequest accountStatusWithAccount:accountInfo];
    [self setAccountStatusRequest:request];
    [request setDelegate:self];
    [request startAsynchronous];
}

- (void)resendEmail:(id)sender 
{
    [self startHUD];
    AccountInfo *accountInfo = [[AccountManager sharedManager] accountInfoForUUID:self.selectedAccountUUID];
    NewCloudAccountHTTPRequest *request = [NewCloudAccountHTTPRequest cloudSignupRequestWithAccount:accountInfo];
    [self setResendEmailRequest:request];
    [request setDelegate:self];
    [request startAsynchronous];
}

- (void)promptDeleteAccount:(id)sender 
{
    UIAlertView *deletePrompt = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"accountdetails.alert.delete.title", @"Delete Account") 
                                                           message:NSLocalizedString(@"accountdetails.alert.delete.confirm", @"Are you sure you want to remove this account?") 
                                                          delegate:self 
                                                 cancelButtonTitle:NSLocalizedString(@"No", @"No") 
                                                 otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil];
    [deletePrompt setTag:kDeleteAccountAlert];
    [deletePrompt show];
    [deletePrompt release];
}

#pragma mark - ASIHTTPRequestDelegate methods
- (void)requestFinished:(ASIHTTPRequest *)request
{
    if([request isEqual:self.resendEmailRequest])
    {
        NewCloudAccountHTTPRequest *signupRequest = (NewCloudAccountHTTPRequest *)request;
        if([signupRequest signupSuccess])
        {
            UIAlertView *successAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"awaitingverification.alert.resendEmail.title", @"Resend Success") message:NSLocalizedString(@"awaitingverification.alert.resendEmail.success", @"The Email was...") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles: nil];
            [successAlert show];
            [successAlert release];
        }
        else
        {
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"awaitingverification.alerts.title", @"Alfresco Cloud") message:NSLocalizedString(@"awaitingverification.alert.resendEmail.error", @"The Email resend unsuccessful...") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles: nil];
            [errorAlert show];
            [errorAlert release];
        }
    }
    else if ([request isEqual:self.accountStatusRequest])
    {
        AccountStatusHTTPRequest *statusRequest = (AccountStatusHTTPRequest *)request;
        if([statusRequest accountStatus] == FDAccountStatusAwaitingVerification)
        {
            UIAlertView *awaitingAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"awaitingverification.alerts.title", @"Alfresco Cloud") message:NSLocalizedString(@"awaitingverification.alert.refresh.awaiting", @"The Account is still...") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles: nil];
            [awaitingAlert show];
            [awaitingAlert release];
        }
        else
        {
            [self showAccountActiveAlert];
        }
    }
    [self stopHUD];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    [self stopHUD];
    // When we get a 404 means that the account is now verified and we need to show the "Account Acive" alert
    // and navigate away from the awaiting verification account details
    if([request isEqual:self.accountStatusRequest] && request.responseStatusCode == 404)
    {
        [self showAccountActiveAlert];
    }
}

- (void)showAccountActiveAlert
{
    UIAlertView *verifiedAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"awaitingverification.alerts.title", @"Alfresco Cloud") message:NSLocalizedString(@"awaitingverification.alert.refresh.verified", @"The Account is now...") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles: nil];
    [verifiedAlert setTag:kVerifiedAccountAlert];
    [verifiedAlert show];
    [verifiedAlert release];
}

#pragma mark - UIAlertViewDelegate methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex 
{
    if([alertView tag] == kDeleteAccountAlert && buttonIndex == 1) 
    {
        //Delete account
        AccountInfo *account = [[AccountManager sharedManager] accountInfoForUUID:self.selectedAccountUUID];
        [[AccountManager sharedManager] removeAccountInfo:account];
    } 
    else if([alertView tag] == kVerifiedAccountAlert && buttonIndex == 0)
    {
        AccountInfo *account = [[AccountManager sharedManager] accountInfoForUUID:self.selectedAccountUUID];
        [account setAccountStatus:FDAccountStatusActive];
        [[AccountManager sharedManager] saveAccountInfo:account];
        if(IS_IPAD)
        {
            [IpadSupport clearDetailController];
        }
        else
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

#pragma mark - MBProgressHUD Helper Methods

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    // Remove HUD from screen when the HUD was hidden
    [self stopHUD];
}

- (void)startHUD
{
	if (!self.HUD)
    {
        self.HUD = createAndShowProgressHUDForView(self.navigationController.view);
        [self.HUD setDelegate:self];
	}
}

- (void)stopHUD
{
	if (self.HUD)
    {
        stopProgressHUD(self.HUD);
		self.HUD = nil;
	}
}

#pragma mark - NSNotificationCenter selectors
- (void)handleAccountListUpdated:(NSNotification *)notification
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(handleAccountListUpdated:) withObject:notification waitUntilDone:NO];
        return;
    }
    
    //We need to remove the current awaiting for verification screen 
    //in case the account was updated and is now active
    NSString *uuid = [[notification userInfo] objectForKey:@"uuid"];
    AccountInfo *acconuntInfo = [[AccountManager sharedManager] accountInfoForUUID:self.selectedAccountUUID];
    if([[self selectedAccountUUID] isEqualToString:uuid] && [acconuntInfo accountStatus] == FDAccountStatusActive) {
        if(IS_IPAD) {
            [IpadSupport clearDetailController];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

@end
