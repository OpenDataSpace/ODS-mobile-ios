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
#import "AccountViewController.h"

@implementation NewCloudAccountRowRender

- (BOOL)allowsSelection
{
    return YES;
}

- (NSArray *)tableGroupsWithDatasource:(NSDictionary *)datasource
{
    IFTemporaryModel *model = [datasource objectForKey:@"model"];
    
    IFTextCellController *firstNameCell = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.fields.firstName", @"First Name") andPlaceholder:NSLocalizedString(@"accountdetails.placeholder.required", @"required")   
                                                          atKey:kAccountFirstNameKey inModel:model] autorelease];
    [firstNameCell setReturnKeyType:UIReturnKeyNext];
    [firstNameCell setUpdateTarget:self];
    [firstNameCell setEditChangedAction:@selector(textValueChanged:)];
    
    IFTextCellController *lastNameCell = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.fields.lastName", @"Last Name") andPlaceholder:NSLocalizedString(@"accountdetails.placeholder.required", @"required")   
                                                                                 atKey:kAccountLastNameKey inModel:model] autorelease];
    [lastNameCell setReturnKeyType:UIReturnKeyNext];
    [lastNameCell setUpdateTarget:self];
    [lastNameCell setEditChangedAction:@selector(textValueChanged:)];
    
    IFTextCellController *emailCell = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.fields.email", @"Email") andPlaceholder:NSLocalizedString(@"accountdetails.placeholder.required", @"required")   
                                                                                atKey:kAccountUsernameKey inModel:model] autorelease];
    [emailCell setReturnKeyType:UIReturnKeyNext];
    [emailCell setKeyboardType:UIKeyboardTypeEmailAddress];
    [emailCell setUpdateTarget:self];
    [emailCell setEditChangedAction:@selector(textValueChanged:)];
    
    IFTextCellController *passwordCell = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.fields.password", @"Password") 
                                                                       andPlaceholder:NSLocalizedString(@"accountdetails.placeholder.required", @"required")  
                                                                                atKey:kAccountPasswordKey inModel:model] autorelease];
    [passwordCell setReturnKeyType:UIReturnKeyNext];
    [passwordCell setSecureTextEntry:YES];
    [passwordCell setUpdateTarget:self];
    [passwordCell setEditChangedAction:@selector(textValueChanged:)];
    
    IFTextCellController *confirmPasswordCell = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.fields.confirmPassword", @"Confirm Password") 
                                                                       andPlaceholder:NSLocalizedString(@"accountdetails.placeholder.required", @"required")  
                                                                                atKey:kAccountConfirmPasswordKey inModel:model] autorelease];
    [confirmPasswordCell setReturnKeyType:UIReturnKeyDone];
    [confirmPasswordCell setSecureTextEntry:YES];
    [confirmPasswordCell setUpdateTarget:self];
    [confirmPasswordCell setEditChangedAction:@selector(textValueChanged:)];
    
    NSArray *cloudGroup = [NSArray arrayWithObjects:firstNameCell, lastNameCell, emailCell, passwordCell, confirmPasswordCell, nil];
    
    return [NSArray arrayWithObject:cloudGroup];
}

- (NSArray *)tableHeadersWithDatasource:(NSDictionary *)datasource
{
    return nil;
}

- (NSArray *)tableFootersWithDatasource:(NSDictionary *)datasource
{
    return nil;
}

- (void)textValueChanged:(id)sender
{
    //[saveButton setEnabled:[self validateAccountFields]];
}

@end
