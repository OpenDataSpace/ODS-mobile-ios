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
#import "NSString+Utils.h"
#import "AccountViewController.h"
#import "Utility.h"

@interface NewCloudAccountActions (private)
- (BOOL)validateData:(NSDictionary *)datasource;
@end

@implementation NewCloudAccountActions

// If the datasource is valid, which means all fields are not empty and also valid we enable the Save button
- (void)datasourceChanged:(NSDictionary *)datasource inController:(FDGenericTableViewController *)controller notification:(NSNotification *)notification
{
    UIBarButtonItem *saveButton = controller.navigationItem.rightBarButtonItem;
    styleButtonAsDefaultAction(saveButton);
    [saveButton setEnabled:[self validateData:datasource]];
}

- (BOOL)validateData:(NSDictionary *)datasource
{
    DictionaryModel *model = [datasource objectForKey:@"model"];
    
    NSString *firstName = [model objectForKey:kAccountFirstNameKey];
    NSString *lastName = [model objectForKey:kAccountLastNameKey];
    NSString *email = [model objectForKey:kAccountUsernameKey];
    NSString *password = [model objectForKey:kAccountPasswordKey];
    NSString *confirmPassword = [model objectForKey:kAccountConfirmPasswordKey];
    
    // FirstName, LastName, password should not be empty
    // Email is checked for a valid email and password should match confirm password
    return [firstName isNotEmpty] && [lastName isNotEmpty] && [email isValidEmail] && [password isNotEmpty] && [password isEqualToString:confirmPassword];
}
@end
