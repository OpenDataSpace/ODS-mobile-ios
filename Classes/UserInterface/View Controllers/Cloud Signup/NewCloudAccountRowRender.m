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
//  NewCloudAccountRowRender.m
//

#import "NewCloudAccountRowRender.h"
#import "IFTextCellController.h"
#import "IFTemporaryModel.h"
#import "AccountUtils.h"
#import "IFButtonCellController.h"
#import "UIColor+Theme.h"
#import "AppProperties.h"

@interface NewCloudAccountRowRender(private)
// Creates the footer view with tappeable links to external urls
- (UIView *)cloudAccountFooter;
@end

@implementation NewCloudAccountRowRender
@synthesize signupButtonCell = _signupButtonCell;

- (void)dealloc
{
    [_signupButtonCell release];
    [super dealloc];
}

- (BOOL)allowsSelection
{
    return YES;
}

- (NSArray *)tableGroupsWithDatasource:(NSDictionary *)datasource
{
    IFTemporaryModel *model = [datasource objectForKey:@"model"];
    
    IFTextCellController *firstNameCell = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.fields.firstName", @"First Name") andPlaceholder:NSLocalizedString(@"accountdetails.placeholder.required", @"required")   
                                                          atKey:kAccountFirstNameKey inModel:model] autorelease];
    [firstNameCell setAutocapitalizationType:UITextAutocapitalizationTypeWords];
    [firstNameCell setReturnKeyType:UIReturnKeyNext];
    [firstNameCell setUpdateTarget:self];
    
    IFTextCellController *lastNameCell = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.fields.lastName", @"Last Name") andPlaceholder:NSLocalizedString(@"accountdetails.placeholder.required", @"required")   
                                                                                 atKey:kAccountLastNameKey inModel:model] autorelease];
    [lastNameCell setAutocapitalizationType:UITextAutocapitalizationTypeWords];
    [lastNameCell setReturnKeyType:UIReturnKeyNext];
    [lastNameCell setUpdateTarget:self];
    
    IFTextCellController *emailCell = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.fields.email", @"Email") andPlaceholder:NSLocalizedString(@"accountdetails.placeholder.required", @"required")   
                                                                                atKey:kAccountUsernameKey inModel:model] autorelease];
    [emailCell setReturnKeyType:UIReturnKeyNext];
    [emailCell setKeyboardType:UIKeyboardTypeEmailAddress];
    [emailCell setUpdateTarget:self];
    
    IFTextCellController *passwordCell = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.fields.password", @"Password") 
                                                                       andPlaceholder:NSLocalizedString(@"accountdetails.placeholder.required", @"required")  
                                                                                atKey:kAccountPasswordKey inModel:model] autorelease];
    [passwordCell setReturnKeyType:UIReturnKeyNext];
    [passwordCell setSecureTextEntry:YES];
    [passwordCell setUpdateTarget:self];
    
    IFTextCellController *confirmPasswordCell = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.fields.confirmPassword", @"Confirm Password") 
                                                                       andPlaceholder:NSLocalizedString(@"accountdetails.placeholder.required", @"required")  
                                                                                atKey:kAccountConfirmPasswordKey inModel:model] autorelease];
    [confirmPasswordCell setReturnKeyType:UIReturnKeyDone];
    [confirmPasswordCell setSecureTextEntry:YES];
    [confirmPasswordCell setUpdateTarget:self];
    
    NSArray *cloudGroup = [NSArray arrayWithObjects:firstNameCell, lastNameCell, emailCell, passwordCell, confirmPasswordCell, nil];
    
    IFButtonCellController *signupCell = [[[IFButtonCellController alloc] initWithLabel:NSLocalizedString(@"cloudsignup.buttons.signup", @"Browse Documents")
                                                                                      withAction:nil
                                                                                    onTarget:nil] autorelease];
    // Color to give the "disabled" look
    [signupCell setTextColor:[UIColor grayColor]];
    [signupCell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [self setSignupButtonCell:signupCell];

    
    NSArray *signupGroup = [NSArray arrayWithObject:signupCell];
    return [NSArray arrayWithObjects:cloudGroup, signupGroup, nil];
}

- (NSArray *)tableHeadersWithDatasource:(NSDictionary *)datasource
{
    return nil;
}

- (NSArray *)tableFootersWithDatasource:(NSDictionary *)datasource
{
    return [NSArray arrayWithObjects:@"", [self cloudAccountFooter], nil];
}

- (void)addLink:(NSURL *)url toText:(NSString *)text inString:(NSString *)completeString label:(TTTAttributedLabel *)label
{
    NSRange textRange = [completeString rangeOfString:text];
    if (textRange.length > 0) 
    {
        [label addLinkToURL:url withRange:textRange];
        [label setDelegate:self];
    }
}

- (UIView *)cloudAccountFooter
{
    NSString *footerText = NSLocalizedString(@"cloudsignup.footer.firstLine", @"By tapping 'Sign Up'...");
    NSString *signupText = NSLocalizedString(@"cloudsignup.footer.secondLine", @"Alfresco Terms of ...");
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 0)];
    [footerView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth];
    
    UILabel *footerTextView = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    [footerTextView setAdjustsFontSizeToFitWidth:YES];
    [footerTextView setBackgroundColor:[UIColor clearColor]];
    [footerTextView setUserInteractionEnabled:YES];
    [footerTextView setTextAlignment:UITextAlignmentCenter];
    [footerTextView setTextColor:[UIColor colorWIthHexRed:76.0 green:86.0 blue:108.0 alphaTransparency:1]];
    [footerTextView setFont:[UIFont systemFontOfSize:15]];
    [footerTextView setText:footerText];
    [footerTextView sizeToFit];
    [footerTextView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
    
    //Set the width to 320 to fix an issue with iOS 4.3 that will not center the text
    //instead all the text was aligned left
    CGRect frame = footerTextView.frame;
    frame.size.width = 320;
    [footerTextView setFrame:frame];
    
    TTTAttributedLabel *signupLabel = [[[TTTAttributedLabel alloc] initWithFrame:CGRectMake(0, footerTextView.frame.size.height, 0, 0)] autorelease];
    //TODO: Update/Fix the TTTAttributedLabel so that this method works on 4.3
    // currently only works for 5.0
    //[signupLabel setAdjustsFontSizeToFitWidth:YES];
    [signupLabel setBackgroundColor:[UIColor clearColor]];
    [signupLabel setNumberOfLines:1];
    [signupLabel setUserInteractionEnabled:YES];
    [signupLabel setTextAlignment:UITextAlignmentCenter];
    [signupLabel setTextColor:[UIColor colorWIthHexRed:76.0 green:86.0 blue:108.0 alphaTransparency:1]];
    [signupLabel setFont:[UIFont systemFontOfSize:15]];
    [signupLabel setVerticalAlignment:TTTAttributedLabelVerticalAlignmentTop];
    [signupLabel setDelegate:self];
    
    [signupLabel setText:signupText afterInheritingLabelAttributesAndConfiguringWithBlock:
     ^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) 
     {
         return mutableAttributedString;
     }];
    
    NSString *termsOfServiceUrl = [AppProperties propertyForKey:kAlfrescoCloudTermsOfServiceUrl];
    [self addLink:[NSURL URLWithString:termsOfServiceUrl] toText:NSLocalizedString(@"cloudsignup.footer.termsOfService", @"") inString:signupText label:signupLabel];
    NSString *privacyPolicyUrl = [AppProperties propertyForKey:kAlfrescoCloudPrivacyPolicyUrl];
    [self addLink:[NSURL URLWithString:privacyPolicyUrl] toText:NSLocalizedString(@"cloudsignup.footer.privacyPolicy", @"") inString:signupText label:signupLabel];
    
    [signupLabel sizeToFit];
    [signupLabel setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
    [signupLabel sizeToFit];
    
    frame = signupLabel.frame;
    frame.size.width = 320;
    [signupLabel setFrame:frame];
    
    [footerView addSubview:footerTextView];
    [footerView addSubview:signupLabel];
    return [footerView autorelease];
}

//Launch the external url in safari
- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    [[UIApplication sharedApplication] openURL:url];
}

@end
