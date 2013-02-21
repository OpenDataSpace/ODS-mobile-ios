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
//  PasswordPromptViewController.m
//

#import "PasswordPromptViewController.h"
#import "AccountInfo.h"
#import "IFTemporaryModel.h"
#import "IFTextCellController.h"
#import "Theme.h"
#import "IFValueCellController.h"
#import "Utility.h"

@interface PasswordPromptViewController ()
@property (nonatomic, retain) IFTextCellController *passwordCell;
@property (nonatomic, retain) UIBarButtonItem *saveButton;
@end

@interface PasswordPromptViewController (Private)
- (IFTemporaryModel *)accountInfoToModel:(AccountInfo *)anAccountInfo;
- (void)setObjectIfNotNil: (id) object forKey: (NSString *) key inModel:(IFTemporaryModel *)tempModel;
- (void)saveAction:(id)sender;
@end

@implementation PasswordPromptViewController

- (void)dealloc
{
    _delegate = nil;
    [_accountInfo release];
    [_saveButton release];
    [_password release];
    [_passwordCell release];
    
    [super dealloc];
}

- (id)initWithAccountInfo:(AccountInfo *)accountInfo
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self)
    {
        self.accountInfo = accountInfo;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [Theme setThemeForUINavigationBar:self.navigationController.navigationBar];
    [self setTitle:NSLocalizedString(@"passwordPrompt.title", "Secure Credentials")];

    UIBarButtonItem *saveButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(saveAction:)] autorelease];
    saveButton.enabled = NO;
    styleButtonAsDefaultAction(saveButton);
    [self.navigationItem setRightBarButtonItem:saveButton];
    self.saveButton = saveButton;

    [self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)] autorelease]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.passwordCell becomeFirstResponder];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

#pragma mark - Navigation button actions

- (void)cancelAction:(id)sender
{
    if (self.delegate)
    {
        [self.delegate passwordPromptWasCancelled:self];
    }
}

- (void)saveAction:(id)sender
{
    NSString *password = [self.model objectForKey:@"password"];

    if (self.delegate)
    {
        [self.delegate passwordPrompt:self savedWithPassword:password];
    }
}

#pragma mark - GenericViewController

- (void)constructTableGroups
{
    if (![self.model isKindOfClass:[IFTemporaryModel class]])
    {
        [self setModel:[self accountInfoToModel:_accountInfo]];
	}
    
    if (self.accountInfo)
    {
        // Arrays for section headers, bodies and footers
        NSMutableArray *headers = [NSMutableArray array];
        NSMutableArray *groups = [NSMutableArray array];
        
        IFValueCellController *descriptionCell = [[[IFValueCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.fields.description", @"Description")
                                                                                         atKey:@"accountDescription"
                                                                                       inModel:self.model] autorelease];

        NSString *usernameLabelKey = (self.accountInfo.isMultitenant) ? @"accountdetails.fields.email" : @"accountdetails.fields.username";
        IFValueCellController *usernameReadCell = [[[IFValueCellController alloc] initWithLabel:NSLocalizedString(usernameLabelKey, @"Username/Email")
                                                                                          atKey:@"accountUsername"
                                                                                        inModel:self.model] autorelease];

        IFTextCellController *passwordCell = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.fields.password", @"Password")
                                                                           andPlaceholder:NSLocalizedString(@"accountdetails.placeholder.required", @"required")  
                                                                                    atKey:@"password"
                                                                                  inModel:self.model] autorelease];
        [passwordCell setReturnKeyType:UIReturnKeyDone];
        [passwordCell setSecureTextEntry:YES];
        [passwordCell setUpdateTarget:self];
        [passwordCell setEditChangedAction:@selector(textValueChanged:)];
        self.passwordCell = passwordCell;
        
        [groups addObject:@[descriptionCell, usernameReadCell, passwordCell]];
        
        if (self.isRequestForExpiredFiles)
        {
            [headers addObject:NSLocalizedString(@"passwordPrompt.header.restrictedTitle", "Provide the password... to unlock restricted files")];
        }
        else
        {
            [headers addObject:NSLocalizedString(@"passwordPrompt.header.title", "Provide the password for the following account")];
        }

        tableGroups = [groups retain];
        tableHeaders = [headers retain];
        [self assignFirstResponderHostToCellControllers];
    }
}

- (void)textValueChanged:(id)sender
{
    NSString *password = [self.model objectForKey:@"password"];
    if (password && ![password isEqualToString:[NSString string]])
    {
        [_saveButton setEnabled:YES];
    }
    else
    {
        [_saveButton setEnabled:NO];
    }
}

#pragma mark - Dictionary to AccountInfo, AccountInfo to Dictionary

- (void)setObjectIfNotNil: (id) object forKey: (NSString *) key inModel:(IFTemporaryModel *)tempModel
{
    if (object)
    {
        [tempModel setObject:object forKey:key];
    }
}

- (IFTemporaryModel *)accountInfoToModel:(AccountInfo *)anAccountInfo 
{
    IFTemporaryModel *tempModel = [[[IFTemporaryModel alloc] initWithDictionary:[NSMutableDictionary dictionary]] autorelease];
    
    [self setObjectIfNotNil:[anAccountInfo description] forKey:@"accountDescription" inModel:tempModel];
    [self setObjectIfNotNil:[anAccountInfo username] forKey:@"accountUsername" inModel:tempModel];
    
    return tempModel;
}

#pragma mark - IFCellControllerFirstResponder

- (void)lastResponderIsDone: (NSObject<IFCellController> *)cellController
{
	[super lastResponderIsDone:cellController];
    if ([_saveButton isEnabled])
    {
        [self saveAction:cellController];
    }
}

@end
