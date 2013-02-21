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
//  NewCloudAccountActions.m
//

#import "NewCloudAccountActions.h"
#import "DictionaryModel.h"
#import "Utility.h"
#import "NewCloudAccountHTTPRequest.h"
#import "AccountUtils.h"
#import "AccountManager.h"
#import "NewCloudAccountRowRender.h"
#import "IFButtonCellController.h"

static NSString * const kDefaultCloudValuesKey = @"kDefaultCloudAccountValues";
static NSString * const kPlistExtension = @"plist";

@interface NewCloudAccountActions ()
- (void)setSignupButton:(FDGenericTableViewController *)controller isEnabled:(BOOL)enabled;
@end

@implementation NewCloudAccountActions
@synthesize signupRequest =_signupRequest;
@synthesize controller = _controller;
@synthesize HUD = _HUD;

- (void)dealloc
{
    [_signupRequest release];
    [_controller release];
    [_HUD release];
    [super dealloc];
}

// There's only one row that we can select, the "Sign Up" button
- (void)rowWasSelectedAtIndexPath:(NSIndexPath *)indexPath withDatasource:(NSDictionary *)datasource andController:(FDGenericTableViewController *)controller
{
    NSString *errorMessage = [NewCloudAccountActions validateData:datasource];
    //Validate returns nil if the form is valid
    if(!errorMessage)
    {
        [self setController:(NewCloudAccountViewController *)controller];
        [self startHUD];
        
        DictionaryModel *model = [datasource objectForKey:@"model"];
        NSDictionary *accountDict =  [model dictionary];
        AccountInfo *accountInfo = [AccountUtils accountFromDictionary:accountDict];
        //Set the default values for alfresco cloud
        NSString *path = [[NSBundle mainBundle] pathForResource:kDefaultAccountsPlist_FileName ofType:kPlistExtension];
        NSDictionary *defaultAccountsPlist = [[[NSDictionary alloc] initWithContentsOfFile:path] autorelease];
        
        //Default cloud account values
        NSDictionary *defaultCloudValues = [defaultAccountsPlist objectForKey:kDefaultCloudValuesKey];
        [accountInfo setVendor:[defaultCloudValues objectForKey:@"Vendor"]];
        [accountInfo setProtocol:[defaultCloudValues objectForKey:@"Protocol"]];
        [accountInfo setHostname:[defaultCloudValues objectForKey:@"Hostname"]];
        [accountInfo setPort:[defaultCloudValues objectForKey:@"Port"]];
        [accountInfo setServiceDocumentRequestPath:[defaultCloudValues objectForKey:@"ServiceDocumentRequestPath"]];
        [accountInfo setMultitenant:[defaultCloudValues objectForKey:@"Multitenant"]];
        
        //Cloud Signup values
        [accountInfo setAccountStatus:FDAccountStatusAwaitingVerification];
        [accountInfo setDescription:@"Alfresco Cloud"];
        [[AccountManager sharedManager] saveAccountInfo:accountInfo];

        NewCloudAccountHTTPRequest *request = [NewCloudAccountHTTPRequest cloudSignupRequestWithAccount:accountInfo];
        [request setDelegate:self];
        [request setSuppressAllErrors:YES];
        [request startAsynchronous];
    }
    else 
    {
        [self setSignupButton:controller isEnabled:NO];
    }
}

// If the datasource is valid, which means all fields are not empty and also valid we enable the Save button
- (void)textEditingUpdated:(id)sender
{
    NSString *errorMessage = [NewCloudAccountActions validateData:self.controller.datasource];
    BOOL isCloudAccountRowRender = [self.controller.rowRenderDelegate isKindOfClass:[NewCloudAccountRowRender class]];
    if (isCloudAccountRowRender)
    {
        [self setSignupButton:self.controller isEnabled:!errorMessage];
    }
}

- (void)genericController:(FDGenericTableViewController *)controller lastResponderIsDoneWithDatasource:(NSDictionary *)datasource
{
    [self textEditingUpdated:controller];
    [self rowWasSelectedAtIndexPath:nil withDatasource:datasource andController:controller];
}

// If the datasource is valid, which means all fields are not empty and also valid we enable the Save button
// If the datasource is invalid we do not change the signup button since the tableView reload causes the keyboard to hide, interrupting the user's input
- (void)datasourceChanged:(NSDictionary *)datasource inController:(FDGenericTableViewController *)controller notification:(NSNotification *)notification
{
    //This is the first selector that the generic controller will call
    //we need to set the controller and also suscribe to get notified of the cell updates (when the focus is lost in a cell's UITextView)
    if (!self.controller)
    {
        [self setController:(NewCloudAccountViewController *)controller];
    }
    [self textEditingUpdated:nil];
}

+ (NSString *)validateData:(NSDictionary *)datasource
{
    DictionaryModel *model = [datasource objectForKey:@"model"];
    
    NSString *firstName = [model objectForKey:kAccountFirstNameKey];
    NSString *lastName = [model objectForKey:kAccountLastNameKey];
    NSString *email = [model objectForKey:kAccountUsernameKey];
    NSString *password = [model objectForKey:kAccountPasswordKey];
    NSString *confirmPassword = [model objectForKey:kAccountConfirmPasswordKey];
    
    // FirstName, LastName, password should not be empty
    if(![firstName isNotEmpty] || ![lastName isNotEmpty])
    {
        return NSLocalizedString(@"cloudsignup.invalidForm.message", @"Please fill all the requiered fields");
    }
    // Email is checked for a valid address
    else if(![email isValidEmail])
    {
        return NSLocalizedString(@"accountdetails.alert.save.emailerror", @"The email is invalid");
    }
    //password must contain at least 6 characters
    else if([password length] < 6)
    {
        return NSLocalizedString(@"cloudsignup.passwordLength.message", @"The password must contain at least 6 characters");
    }
    // password should match confirm password
    else if(![password isEqualToString:confirmPassword])
    {
        return NSLocalizedString(@"cloudsignup.passwordMatch.message", @"The password does not match with the confirm password");
    }
    return nil;
}

#pragma mark - Private Methods
- (void)setSignupButton:(FDGenericTableViewController *)controller isEnabled:(BOOL)enabled
{
    // Enabling/disabling the signup cell
    NewCloudAccountRowRender *rowRender = (NewCloudAccountRowRender *)controller.rowRenderDelegate;
    UITableViewCellSelectionStyle styleForDesiredState = enabled ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone;
    UIColor *colorForDesiredState = enabled ? [UIColor blackColor] : [UIColor grayColor];

    if ([rowRender.signupButtonCell selectionStyle] != styleForDesiredState)
    {
        [rowRender.signupButtonCell setTextColor:colorForDesiredState];
        [rowRender.signupButtonCell setSelectionStyle:styleForDesiredState];
        NSIndexPath *indexPath = [controller indexPathForCellController:rowRender.signupButtonCell];
        [controller.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - ASIHTTPRequest delegate methods
-(void)requestFinished:(ASIHTTPRequest *)request {
    NewCloudAccountHTTPRequest *signupRequest = (NewCloudAccountHTTPRequest *)request;
    if([signupRequest signupSuccess])
    {
        AccountInfo *account = [signupRequest signupAccount];
        
        [[AccountManager sharedManager] saveAccountInfo:account];
        
        if(self.controller.delegate)
        {
            [self.controller setSelectedAccountUUID:[account uuid]];
            [self.controller.delegate accountControllerDidFinishSaving:self.controller];
        }
    }
    else
    {
        AccountInfo *account = [signupRequest signupAccount];
        [[AccountManager sharedManager] removeAccountInfo:account];

        displayErrorMessageWithTitle(NSLocalizedString(@"cloudsignup.unsuccessful.message", @"The cloud sign up was unsuccessful, please try again later"), NSLocalizedString(@"cloudsignup.alert.title", @"Alfresco Cloud Sign Up"));
    }
    [[self HUD] hide:YES];
}


-(void)requestFailed:(ASIHTTPRequest *)request
{
    NewCloudAccountHTTPRequest *signupRequest = (NewCloudAccountHTTPRequest *)request;
    AccountInfo *account = [signupRequest signupAccount];
    [[AccountManager sharedManager] removeAccountInfo:account];
    AlfrescoLogDebug(@"Cloud signup request failed: %@", [request error]);
    [[self HUD] hide:YES];
    
    if (signupRequest.blockedEmail)
    {
        displayErrorMessageWithTitle(NSLocalizedString(@"cloudsignup.blockedEmail.message", @"Alfresco requires you to use your company email address so you can be added to your company collaboration network."), NSLocalizedString(@"cloudsignup.alert.title", @"Alfresco Cloud Sign Up"));
    }
    else
    {
        displayErrorMessageWithTitle(NSLocalizedString(@"cloudsignup.unsuccessful.message", @"The cloud sign up was unsuccessful, please try again later"), NSLocalizedString(@"cloudsignup.alert.title", @"Alfresco Cloud Sign Up"));
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
        self.HUD = createAndShowProgressHUDForView([[self.controller navigationController] view]);
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

@end
