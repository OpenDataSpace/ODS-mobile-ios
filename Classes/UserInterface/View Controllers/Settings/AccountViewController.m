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
//  AccountViewController.m
//

#import "AccountViewController.h"
#import "AccountInfo.h"
#import "IFTemporaryModel.h"
#import "IFTextCellController.h"
#import "IFSwitchCellController.h"
#import "MetaDataCellController.h"
#import "Theme.h"
#import "IFValueCellController.h"
#import "IFButtonCellController.h"
#import "Utility.h"
#import "IpadSupport.h"
#import "NSString+Utils.h"
#import "NSNotificationCenter+CustomNotification.h"
#import "AccountManager+FileProtection.h"
#import "AccountUtils.h"
#import "ASIHTTPRequest.h"
#import "BaseHTTPRequest.h"

static NSInteger kAlertPortProtocolTag = 0;
static NSInteger kAlertDeleteAccountTag = 1;

@interface AccountViewController (private)
- (IFTemporaryModel *)accountInfoToModel:(AccountInfo *)anAccountInfo;
- (void)updateAccountInfo:(AccountInfo *)anAccountInfo withModel:(id<IFCellModel>)tempModel;
- (void)saveButtonClicked:(id)sender;
- (void)saveAccount;
- (NSInteger)indexForAccount:(AccountInfo *)account inArray:(NSArray *)accountArray;

- (NSArray *)authenticationEditGroup;
- (NSArray *)advancedEditGroup;
- (NSArray *)authenticationViewGroup;
- (NSArray *)advancedViewGroup;
- (BOOL)validateAccountFieldsOnServer;
- (BOOL)validateAccountFieldsOnCloud;
- (BOOL)validateAccountFieldsOnStandardServer;
- (BOOL)validateAccountFieldsValues;

- (void)startHUD;
- (void)stopHUD;

@end

@implementation AccountViewController
@synthesize isEdit;
@synthesize isNew;
@synthesize accountInfo;
@synthesize delegate;
@synthesize usernameCell;
@synthesize saveButton;
@synthesize HUD;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [accountInfo release];
    [usernameCell release];
    [saveButton release];
    [HUD release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
 // Implement loadView to create a view hierarchy programmatically, without using a nib.
 - (void)loadView
 {
 }
 */

- (void)viewDidLoad
{
    [super viewDidLoad];
    [Theme setThemeForUINavigationBar:self.navigationController.navigationBar];
    
    //We give preference to the description of the account as the title
    //otherwise we set it to a generic "Account Information" and "Editing Account"
    if(isNew) {
        [self setTitle:NSLocalizedString(@"accountdetails.title.newaccount", @"New Account")];
    } else if(accountInfo && [accountInfo description]) {
        [self setTitle:[accountInfo description]];
    } else if(isEdit){
        [self setTitle:NSLocalizedString(@"accountdetails.title.editingaccount", @"Editing Account")];
    } else {
        [self setTitle:NSLocalizedString(@"accountdetails.title.accountinfo", @"Account Information")];
    }
    
    if(isEdit) {
        //Ideally displayed in a modal view
        self.saveButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                     target:self
                                                                                     action:@selector(saveButtonClicked:)] autorelease];
        styleButtonAsDefaultAction(saveButton);
        [self.navigationItem setRightBarButtonItem:saveButton];
        
        [self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                                 target:self
                                                                                                 action:@selector(cancelEdit:)] autorelease]];
        [self setModel:[self accountInfoToModel:accountInfo]];
//        [saveButton setEnabled:[self validateAccountFieldsOnServer]];
    } else {
        //Ideally pushed in a navigation stack
        [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editAccount:)] autorelease]];
    }
    
    [saveButton setEnabled:[self validateAccountFieldsValues]];
    
    shouldSetResponder = YES;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAccountListUpdated:) 
                                                 name:kNotificationAccountListUpdated object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (shouldSetResponder)
    {
        [usernameCell becomeFirstResponder];
        shouldSetResponder = NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationAccountListUpdated object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark -
#pragma mark FIX to enable the name field to become the first responder after a reload
- (void)updateAndReload
{
    [super updateAndReload];
    shouldSetResponder = YES;
}

#pragma mark -
#pragma mark NavigationBar actions

- (void)saveButtonClicked:(id)sender
{
    [self startHUD];
 
    dispatch_queue_t downloadQueue = dispatch_queue_create("image downloader", NULL);
    
    dispatch_async(downloadQueue, ^{
        
    NSMutableDictionary *modelDictionary = [(IFTemporaryModel *)self.model dictionary];
    for (NSString *key in [modelDictionary allKeys]) 
    {
        if (nil == [modelDictionary objectForKey:key]) 
        {
            [self.model setObject:@"" forKey:key];
        }
    }
    
    
    //User input validations
    /*NSString *description = [model objectForKey:kAccountDescriptionKey];
    NSString *hostname = [model objectForKey:kAccountHostnameKey];*/
    NSString *port = [model objectForKey:kAccountPortKey];
    port = [port stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (port == nil) {
        [model setObject:@"" forKey:port];
        port = @"";
    }
    
    
    
    /*NSString *username = [[model objectForKey:kAccountUsernameKey] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    [model setObject:username forKey:kAccountUsernameKey];
    NSString *password = [[model objectForKey:kAccountPasswordKey] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    BOOL descriptionError = !description || [description isEqualToString:[NSString string]];
    NSRange hostnameRange = [hostname rangeOfString:@"^[a-zA-Z0-9_\\-\\.]+$" options:NSRegularExpressionSearch];
    BOOL hostnameError = ( !hostname || (hostnameRange.location == NSNotFound) );
    BOOL passwordError = !password || [password isEqualToString:[NSString string]];
    
    BOOL isMultitenant = [[model objectForKey:kAccountMultitenantKey] boolValue];
    BOOL portIsInvalid = ([port rangeOfString:@"^[0-9]*$" options:NSRegularExpressionSearch].location == NSNotFound);*/
    BOOL https = [[model objectForKey:kAccountBoolProtocolKey] boolValue];
    BOOL portConflictDetected = ((https && [port isEqualToString:kFDHTTP_DefaultPort]) || (!https && [port isEqualToString:kFDHTTPS_DefaultPort]));
    /*BOOL usernameError = NO;
    
    if(isMultitenant) 
    {
        usernameError = ![username isValidEmail];
    } else
    {
        usernameError = !username || [username isEqualToString:[NSString string]];
    }
    
    if (hostnameError || descriptionError || portIsInvalid || (usernameError && !isMultitenant) || passwordError)
    {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"accountdetails.alert.save.title", @"Save Account") 
                                                             message:NSLocalizedString(@"accountdetails.alert.save.fieldserror", @"Save error") 
                                                            delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles: nil];
        [errorAlert show];
        [errorAlert release];
        [self updateAndReload];  
    }
    else if(usernameError && isMultitenant)
    {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"accountdetails.alert.save.title", @"Save Account") 
                                                             message:NSLocalizedString(@"accountdetails.alert.save.emailerror", @"Invalid Email") 
                                                            delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles: nil];
        [errorAlert show];
        [errorAlert release];
        [self updateAndReload];
    } 
    else */if (portConflictDetected) 
    {
        UIAlertView *portPrompt = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"accountdetails.alert.save.title", @"Save Account") 
                                                             message:NSLocalizedString(@"accountdetails.alert.save.porterror", @"Port error") 
                                                            delegate:self cancelButtonTitle:NSLocalizedString(@"NO", @"NO") 
                                                   otherButtonTitles:NSLocalizedString(@"YES", @"YES"), nil];
        [portPrompt setTag:kAlertPortProtocolTag];
        [portPrompt show];
        [portPrompt release];
    }
    
    BOOL validFields = [self validateAccountFieldsOnServer];
    if (validFields && !portConflictDetected) 
    {
        NSString *description = [model objectForKey:kAccountDescriptionKey];
        if(![description isNotEmpty])
        {
            //Setting the default description if the user does not input any description
            [model setObject:NSLocalizedString(@"accountdetails.placeholder.serverdescription", @"Alfresco Server") forKey:kAccountDescriptionKey];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
        [self saveAccount];
        });
    }
    else 
    {
        dispatch_async(dispatch_get_main_queue(), ^{
        [self stopHUD];
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"accountdetails.alert.save.title", @"Save Account") 
                                                        message:NSLocalizedString(@"accountdetails.alert.save.validationerror", @"Validation Error") 
                                                        delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles: nil];
        [errorAlert show];
        [errorAlert release];
        });
        
    }
    });
}

- (void)saveAccount 
{
    [self updateAccountInfo:accountInfo withModel:model];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationAccountListUpdated object:nil];
    [[AccountManager sharedManager] saveAccountInfo:accountInfo];
    
    [self stopHUD];
    if(delegate) {
        [delegate accountControllerDidFinishSaving:self];
    }
}

/**
 validateAccountFieldsValues
 checks the validity of hostname, port and username in terms of characters entered.
 */
- (BOOL)validateAccountFieldsValues
{
    NSMutableDictionary *modelDictionary = [(IFTemporaryModel *)self.model dictionary];
    for (NSString *key in [modelDictionary allKeys]) 
    {
        if (nil == [modelDictionary objectForKey:key]) 
        {
            [self.model setObject:@"" forKey:key];
        }
    }
    
    
    //User input validations
    NSString *hostname = [model objectForKey:kAccountHostnameKey];
    NSString *port = [model objectForKey:kAccountPortKey];
    port = [port stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (port == nil) {
        [model setObject:@"" forKey:port];
        port = @"";
    }
    
    NSString *username = [[model objectForKey:kAccountUsernameKey] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    [model setObject:username forKey:kAccountUsernameKey];
    
    NSRange hostnameRange = [hostname rangeOfString:@"^[a-zA-Z0-9_\\-\\.]+$" options:NSRegularExpressionSearch];
    BOOL hostnameError = ( !hostname || (hostnameRange.location == NSNotFound) );
    
    BOOL isMultitenant = [[model objectForKey:kAccountMultitenantKey] boolValue];
    BOOL portIsInvalid = ([port rangeOfString:@"^[0-9]*$" options:NSRegularExpressionSearch].location == NSNotFound);
    BOOL usernameError = NO;
    if(isMultitenant) 
    {
        usernameError = ![username isValidEmail];
    } else
    {
        usernameError = ![username isNotEmpty];
    }
    
    NSString *serviceDoc = [model objectForKey:kAccountServiceDocKey];
    BOOL serviceDocError = ![serviceDoc isNotEmpty];
    
    return !hostnameError && !portIsInvalid && !usernameError && !serviceDocError; 
}

/**
 validateAccountFieldsOnServer
 checks if the credentials of the account are valid. Sends a synchronous HTTP request via ASIHTTPRequest 
 and checks the HTTP response
 */
- (BOOL)validateAccountFieldsOnServer
{
    if (![self validateAccountFieldsValues]) 
    {
        return NO;
    }
    if ([[model objectForKey:kAccountMultitenantKey] boolValue]) {
        return [self validateAccountFieldsOnCloud];
    }
    else 
    {
        return [self validateAccountFieldsOnStandardServer];
    }
    
}

- (BOOL)validateAccountFieldsOnCloud
{
    NSString *path = [[NSBundle mainBundle] pathForResource:kDefaultAccountsPlist_FileName ofType:@"plist"];
    NSDictionary *defaultAccountsPlist = [[[NSDictionary alloc] initWithContentsOfFile:path] autorelease];
    
    //Default cloud account values
    NSDictionary *defaultCloudValues = [defaultAccountsPlist objectForKey:@"kDefaultCloudAccountValues"];
    NSString *protocol = [defaultCloudValues objectForKey:@"Protocol"];
    NSString *port = [defaultCloudValues objectForKey:@"Port"];
    NSString *hostname = [defaultCloudValues objectForKey:@"Hostname"];
    NSString *servicePath = [defaultCloudValues objectForKey:@"ServiceDocumentRequestPath"];
    NSString *username = [model objectForKey:kAccountUsernameKey];
    NSString *password = [[model objectForKey:kAccountPasswordKey] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (password == nil || [password isEqualToString:@""]) 
    {
        return YES;
    }
    NSString *cloudKeyValue = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"AlfrescoCloudAPIKey"];
    NSString *urlStringCloud = [NSString stringWithFormat:@"%@://%@:%@%@/a/-default-/internal/cloud/user/%@/accounts",protocol,hostname,port,servicePath,username];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlStringCloud]];                                        
    if (nil == request) 
    {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"accountdetails.alert.save.title", @"Save Account") 
                                                             message:NSLocalizedString(@"accountdetails.alert.save.validationerror", @"Validation Error") 
                                                            delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles: nil];
        [errorAlert show];
        [errorAlert release];
        return NO;
    }
    [request addRequestHeader:@"key" value:cloudKeyValue];
    [request addBasicAuthenticationHeaderWithUsername:username andPassword:password];
    
    [request setTimeOutSeconds:20];
    [request setValidatesSecureCertificate:userPrefValidateSSLCertificate()];
    [request setUseSessionPersistence:NO];
    [request startSynchronous];
    int statusCode = [request responseStatusCode];
    if (200 <= statusCode && 299 >= statusCode) 
    {
        return YES;
    }
    else 
    {
        return NO;
    }    
}

- (BOOL)validateAccountFieldsOnStandardServer
{
    NSString *protocol = [[model objectForKey:kAccountBoolProtocolKey]boolValue] ? kFDHTTPS_Protocol : kFDHTTP_Protocol;
    NSString *hostname = [model objectForKey:kAccountHostnameKey];
    NSString *servicePath = [model objectForKey:kAccountServiceDocKey];
    NSString *port = [model objectForKey:kAccountPortKey];
    NSString *username = [model objectForKey:kAccountUsernameKey];
    NSString *password = [[model objectForKey:kAccountPasswordKey] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (password == nil || [password isEqualToString:@""]) 
    {
        return YES;
    }
    NSString *uri = [NSString stringWithFormat:@"%@://%@:%@%@",protocol,hostname,port,servicePath];
    NSURL *url = [NSURL URLWithString:uri];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    if (nil == request) 
    {
        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"accountdetails.alert.save.title", @"Save Account") 
                                                        message:NSLocalizedString(@"accountdetails.alert.save.validationerror", @"Validation Error") 
                                                        delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK") otherButtonTitles: nil];
        [errorAlert show];
        [errorAlert release];
        return NO;
    }
    [request addBasicAuthenticationHeaderWithUsername:username andPassword:password];
    [request setTimeOutSeconds:20];
    [request setValidatesSecureCertificate:userPrefValidateSSLCertificate()];
    [request setUseSessionPersistence:NO];
    [request startSynchronous];
    int statusCode = [request responseStatusCode];
    if (200 <= statusCode && 299 >= statusCode) 
    {
        return YES;
    }
    else 
    {
        return NO;
    }    
}



- (void)cancelEdit:(id)sender
{
    if(delegate) {
        [delegate accountControllerDidCancel:self];
    }
}

- (void)editAccount:(id)sender
{
    AccountViewController *editAccountController = [[AccountViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [editAccountController setIsEdit:YES];
    [editAccountController setAccountInfo:accountInfo];
    [editAccountController setDelegate:self];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editAccountController];
    
    [navController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    [navController setModalPresentationStyle:UIModalPresentationFormSheet];
    [self presentModalViewController:navController animated:YES];
    
    [navController release];
    [editAccountController release];
}

#pragma mark -
#pragma mark AccountViewControllerDelegate
- (void)accountControllerDidCancel:(AccountViewController *)accountViewController {
    
    [accountViewController dismissModalViewControllerAnimated:YES];
}

- (void)accountControllerDidFinishSaving:(AccountViewController *)accountViewController {
    /*[self setModel:[self accountInfoToModel:accountInfo]];
    [self updateAndReload];*/
    [accountViewController dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark GenericViewController

- (void)constructTableGroups
{
    if (![self.model isKindOfClass:[IFTemporaryModel class]]) {
        [self setModel:[self accountInfoToModel:accountInfo]];
	}
    
    // Arrays for section headers, bodies and footers
	NSMutableArray *headers = [NSMutableArray array];
	NSMutableArray *groups =  [NSMutableArray array];
    
    if(accountInfo) 
    {
        NSArray *authCellGroup = nil;
        NSArray *advancedCellGroup = nil;
        NSMutableArray *browseCellGroup = nil;
        NSMutableArray *deleteCellGroup = nil;
        
        if(isEdit) {
            authCellGroup = [self authenticationEditGroup];
            advancedCellGroup = [self advancedEditGroup];
        } 
        else 
        {
            IFButtonCellController *browseDocumentsCell = [[[IFButtonCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.buttons.browse", @"Browse Documents")
                                                                                              withAction:@selector(browseDocuments:) 
                                                                                                onTarget:self] autorelease];
            IFButtonCellController *deleteAccountCell = [[[IFButtonCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.buttons.delete", @"Delete Account")
                                                                                            withAction:@selector(promptDeleteAccount:) 
                                                                                              onTarget:self] autorelease];
            [deleteAccountCell setBackgroundColor:[UIColor redColor]];
            [deleteAccountCell setTextColor:[UIColor whiteColor]];
            [browseDocumentsCell setBackgroundColor:[UIColor whiteColor]];
            
            authCellGroup = [self authenticationViewGroup];
            advancedCellGroup = [self advancedViewGroup];
            browseCellGroup = [NSMutableArray arrayWithObjects:browseDocumentsCell,nil];
            deleteCellGroup = [NSMutableArray arrayWithObjects:deleteAccountCell,nil];
        }
        
        [headers addObject:NSLocalizedString(@"accountdetails.header.authentication", @"Account Authentication")];
        [groups addObject:authCellGroup];
        
        if(advancedCellGroup) {
            [headers addObject:NSLocalizedString(@"accountdetails.header.advanced", @"Advanced")];
            [groups addObject:advancedCellGroup];
        }
        
        if(!isEdit) {
            [headers addObject:@""];
            [headers addObject:@""];
            [groups addObject:browseCellGroup];
            [groups addObject:deleteCellGroup];
        }
    }
    
    tableGroups = [groups retain];
	tableHeaders = [headers retain];
	[self assignFirstResponderHostToCellControllers];
}

- (NSArray *)authenticationEditGroup
{
    NSArray *authCellGroup = nil;
    
    IFTextCellController *passwordCell = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.fields.password", @"Password") 
                                                                       andPlaceholder:NSLocalizedString(@"accountdetails.placeholder.optional", @"required")  
                                                                                atKey:kAccountPasswordKey inModel:self.model] autorelease];
    [passwordCell setReturnKeyType:UIReturnKeyNext];
    [passwordCell setSecureTextEntry:YES];
    [passwordCell setUpdateTarget:self];
    [passwordCell setEditChangedAction:@selector(textValueChanged:)];
    
    IFTextCellController *descriptionCell = nil;    
    
    if(![accountInfo isMultitenant]) 
    {
        self.usernameCell = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.fields.username", @"Username") andPlaceholder:NSLocalizedString(@"accountdetails.placeholder.required", @"required")   
                                                                                    atKey:kAccountUsernameKey inModel:self.model] autorelease];
        [usernameCell setReturnKeyType:UIReturnKeyNext];
        [usernameCell setUpdateTarget:self];
        [usernameCell setEditChangedAction:@selector(textValueChanged:)];
        IFTextCellController *hostnameCell = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.fields.hostname", @"Hostname")  andPlaceholder:NSLocalizedString(@"accountdetails.placeholder.required", @"required")   
                                                                                    atKey:kAccountHostnameKey inModel:self.model] autorelease];
        [hostnameCell setReturnKeyType:UIReturnKeyNext];
        [hostnameCell setKeyboardType:UIKeyboardTypeURL];
        [hostnameCell setUpdateTarget:self];
        [hostnameCell setEditChangedAction:@selector(textValueChanged:)];
        
        descriptionCell = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.fields.description", @"Description") 
                                                        andPlaceholder:NSLocalizedString(@"accountdetails.placeholder.serverdescription", @"required")  
                                                                 atKey:kAccountDescriptionKey inModel:self.model] autorelease];
        [descriptionCell setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
        [descriptionCell setReturnKeyType:UIReturnKeyNext];
        [descriptionCell setUpdateTarget:self];
        [descriptionCell setEditChangedAction:@selector(textValueChanged:)];
        
        IFSwitchCellController *protocolCell = [[[IFSwitchCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.fields.protocol", @"Protocol") 
                                                                                        atKey:kAccountBoolProtocolKey inModel:self.model] autorelease];
        [protocolCell setUpdateTarget:self];
        [protocolCell setUpdateAction:@selector(protocolUpdate:)];
        
        
        authCellGroup = [NSArray arrayWithObjects:usernameCell, passwordCell, hostnameCell, descriptionCell, protocolCell, nil];
    } 
    else 
    {
        self.usernameCell = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.fields.email", @"Email") 
                                                                           andPlaceholder:NSLocalizedString(@"accountdetails.placeholder.email", @"example@acme.com")   
                                                                                    atKey:kAccountUsernameKey inModel:self.model] autorelease];
        [usernameCell setReturnKeyType:UIReturnKeyNext];
        [usernameCell setKeyboardType:UIKeyboardTypeEmailAddress];
        [usernameCell setUpdateTarget:self];
        [usernameCell setEditChangedAction:@selector(textValueChanged:)];
        
        descriptionCell = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.fields.description", @"Description") 
                                                        andPlaceholder:NSLocalizedString(@"accountdetails.placeholder.clouddescription", @"required")  
                                                                 atKey:kAccountDescriptionKey inModel:self.model] autorelease];
        [descriptionCell setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
        [descriptionCell setReturnKeyType:UIReturnKeyDone];
        [descriptionCell setUpdateTarget:self];
        [descriptionCell setEditChangedAction:@selector(textValueChanged:)];
        
        authCellGroup = [NSArray arrayWithObjects:usernameCell, passwordCell, descriptionCell, nil];
    }
    
    return  authCellGroup;
}

- (NSArray *)advancedEditGroup
{
    NSArray *advancedGroup = nil;
    if(![self.accountInfo isMultitenant]) 
    {
        BOOL portHasError = ([[self.model objectForKey:kAccountPortKey] rangeOfString:@"^[0-9]*$" options:NSRegularExpressionSearch].location == NSNotFound);
        IFTextCellController *portCell = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.fields.port", @"Port") andPlaceholder:@"" 
                                                                                atKey:kAccountPortKey inModel:self.model] autorelease];
        if(portHasError) [portCell setTextFieldColor:[[UIColor redColor] colorWithAlphaComponent:0.5]];
        [portCell setKeyboardType:UIKeyboardTypeNumberPad];
        [portCell setReturnKeyType:UIReturnKeyNext];
        
        
        IFTextCellController *serviceDocumentCell = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.fields.servicedoc", @"Service Document") andPlaceholder:@"" 
                                                                                           atKey:kAccountServiceDocKey inModel:self.model] autorelease];
        [serviceDocumentCell setUpdateTarget:self];
        [serviceDocumentCell setEditChangedAction:@selector(textValueChanged:)];
        [serviceDocumentCell setReturnKeyType:UIReturnKeyDone];
        
        advancedGroup = [NSArray arrayWithObjects:portCell, serviceDocumentCell, nil];
    }
    return advancedGroup;
}

- (NSArray *)authenticationViewGroup
{
    NSArray *authCellGroup = nil;
    //End Setup Display values
    
    MetaDataCellController *passwordCell = [[[MetaDataCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.fields.password", @"Password") 
                                                                                    atKey:@"securePassword" inModel:self.model] autorelease];
    
    MetaDataCellController *descriptionCell = [[[MetaDataCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.fields.description", @"Description")
                                                                                       atKey:kAccountDescriptionKey inModel:self.model] autorelease];
    
    if(![self.accountInfo isMultitenant]) 
    {
        MetaDataCellController *usernameReadCell = [[[MetaDataCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.fields.username", @"Username")
                                                                                        atKey:kAccountUsernameKey inModel:self.model] autorelease];
        MetaDataCellController *hostnameCell = [[[MetaDataCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.fields.hostname", @"Hostname") 
                                                                                        atKey:kAccountHostnameKey inModel:self.model] autorelease];
        MetaDataCellController *protocolCell = [[[MetaDataCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.fields.protocol", @"Protocol") //@"HTTPS" 
                                                                                        atKey:kAccountProtocolKey inModel:self.model] autorelease];
        
        authCellGroup = [NSArray arrayWithObjects:usernameReadCell, passwordCell, hostnameCell, descriptionCell, protocolCell, nil];
    } 
    else 
    {
        MetaDataCellController *usernameReadCell = [[[MetaDataCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.fields.email", @"Email")
                                                                                        atKey:kAccountUsernameKey inModel:self.model] autorelease];
        authCellGroup = [NSArray arrayWithObjects:usernameReadCell, passwordCell, descriptionCell, nil];
    }
    
    return authCellGroup;
}

- (NSArray *)advancedViewGroup
{
    NSArray *advancedGroup = nil;
    if(![self.accountInfo isMultitenant]) 
    {
        MetaDataCellController *portCell = [[MetaDataCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.fields.port", @"Port") 
                                                                                   atKey:kAccountPortKey inModel:self.model];
        MetaDataCellController *vendorCell = [[MetaDataCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.fields.vendor", @"Vendor")
                                                                                     atKey:kAccountVendorKey inModel:self.model];
        MetaDataCellController *serviceDocumentCell = [[MetaDataCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.fields.servicedoc", @"Service Document")
                                                                                              atKey:kAccountServiceDocKey inModel:self.model];
        
        advancedGroup = [NSArray arrayWithObjects:portCell, vendorCell, serviceDocumentCell, nil];
        [portCell release];
        [vendorCell release];
        [serviceDocumentCell release];
    }
    return advancedGroup;
}

- (void) setObjectIfNotNil: (id) object forKey: (NSString *) key inModel:(IFTemporaryModel *)tempModel {
    if(object) {
        [tempModel setObject:object forKey:key];
    }
}

- (void)textValueChanged:(id)sender
{
    [saveButton setEnabled:[self validateAccountFieldsValues]];
}

#pragma mark - Cell actions
- (void)protocolUpdate:(id)sender 
{
    BOOL newProtocol = [[self.model objectForKey:kAccountBoolProtocolKey] boolValue];
    NSString *port = [[self.model objectForKey:kAccountPortKey] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    // Update the port if the protocol was toggled (HTTPS ON/OFF)
    // if HTTPS ON, set to port 443 if port is empty or 80
    // if HTTPS OFF, set to port 80 if port is empty or 443
    
    if(newProtocol && (![port length] || [port isEqualToString:kFDHTTP_DefaultPort])) 
    {
        [self.model setObject:kFDHTTPS_DefaultPort forKey:kAccountPortKey];
        [self updateAndRefresh];
    } 
    else if(!newProtocol && (![port length] || [port isEqualToString:kFDHTTPS_DefaultPort])) 
    {
        [self.model setObject:kFDHTTP_DefaultPort forKey:kAccountPortKey];
        [self updateAndRefresh];
    }
}

#pragma mark - Dictionary to AccountInfo, AccountInfo to Dictionary
- (IFTemporaryModel *)accountInfoToModel:(AccountInfo *)anAccountInfo 
{
    IFTemporaryModel *tempModel = [[[IFTemporaryModel alloc] initWithDictionary:[NSMutableDictionary dictionary]] autorelease];
    [tempModel setObject:kFDAlfresco_RepositoryVendorName forKey:kAccountVendorKey];
    
    [self setObjectIfNotNil:[anAccountInfo vendor] forKey:kAccountVendorKey inModel:tempModel];
    [self setObjectIfNotNil:[anAccountInfo description] forKey:kAccountDescriptionKey inModel:tempModel];
    
    BOOL protocol = NO;
    if([[anAccountInfo protocol] isKindOfClass:[NSString class]]) 
    {
        protocol = [[anAccountInfo protocol] isEqualToCaseInsensitiveString:kFDHTTPS_Protocol];
    }
    NSNumber *boolProtocol = [NSNumber numberWithBool:protocol];
    
    NSString *protocolDisplay = NSLocalizedString((protocol ? @"On" : @"Off"), (protocol ? @"On" : @"Off"));
    
    [self setObjectIfNotNil:boolProtocol forKey:kAccountBoolProtocolKey inModel:tempModel];
    [self setObjectIfNotNil:protocolDisplay forKey:kAccountProtocolKey inModel:tempModel];
    [self setObjectIfNotNil:[anAccountInfo hostname] forKey:kAccountHostnameKey inModel:tempModel];
    [self setObjectIfNotNil:[anAccountInfo port] forKey:kAccountPortKey inModel:tempModel];
    [self setObjectIfNotNil:[anAccountInfo serviceDocumentRequestPath] forKey:kAccountServiceDocKey inModel:tempModel];
    [self setObjectIfNotNil:[anAccountInfo username] forKey:kAccountUsernameKey inModel:tempModel];
    [self setObjectIfNotNil:[anAccountInfo password] forKey:kAccountPasswordKey inModel:tempModel];
    [self setObjectIfNotNil:@"**************" forKey:@"securePassword" inModel:tempModel];
    
    [self setObjectIfNotNil:[anAccountInfo multitenant] forKey:kAccountMultitenantKey inModel:tempModel];
    
    return ( tempModel );
}

- (void)updateAccountInfo:(AccountInfo *)anAccountInfo withModel:(id<IFCellModel>)tempModel 
{
    [anAccountInfo setVendor:[tempModel objectForKey:kAccountVendorKey]];
    [anAccountInfo setDescription:[tempModel objectForKey:kAccountDescriptionKey]];
    [anAccountInfo setProtocol:[[tempModel objectForKey:kAccountBoolProtocolKey] boolValue] ? kFDHTTPS_Protocol : kFDHTTP_Protocol];
    [anAccountInfo setHostname:[tempModel objectForKey:kAccountHostnameKey]];
    [anAccountInfo setPort:[tempModel objectForKey:kAccountPortKey]];
    [anAccountInfo setServiceDocumentRequestPath:[tempModel objectForKey:kAccountServiceDocKey]];
    [anAccountInfo setUsername:[tempModel objectForKey:kAccountUsernameKey]];
    [anAccountInfo setPassword:[tempModel objectForKey:kAccountPasswordKey]];
    
    NSNumber *multitenantBoolNumber = [tempModel objectForKey:kAccountMultitenantKey];
    [anAccountInfo setMultitenant:multitenantBoolNumber];
}

- (void)browseDocuments:(id)sender 
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[accountInfo uuid] forKey:@"accountUUID"];
    [[NSNotificationCenter defaultCenter] postBrowseDocumentsNotification:userInfo];
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)promptDeleteAccount:(id)sender 
{
    //If this is the last qualifying account we want to warn the user that this is the last qualifying account.
    UIAlertView *deletePrompt;
    //Retrieving an updated accountInfo object for the uuid since it might contain an outdated isQualifyingAccount property
    [self setAccountInfo:[[AccountManager sharedManager] accountInfoForUUID:[accountInfo uuid]]];
    if([accountInfo isQualifyingAccount] && [[AccountManager sharedManager] numberOfQualifyingAccounts] == 1)
    {
        deletePrompt = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"dataProtection.lastAccount.title", @"Data Protection") 
                                                  message:NSLocalizedString(@"dataProtection.lastAccount.message", @"Last qualifying account...") 
                                                 delegate:self 
                                        cancelButtonTitle:NSLocalizedString(@"No", @"No") 
                                        otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil];
    } 
    else 
    {
        deletePrompt = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"accountdetails.alert.delete.title", @"Delete Account") 
                                                  message:NSLocalizedString(@"accountdetails.alert.delete.confirm", @"Are you sure you want to remove this account?") 
                                                 delegate:self 
                                        cancelButtonTitle:NSLocalizedString(@"No", @"No") 
                                        otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil];
    }
    [deletePrompt setTag:kAlertDeleteAccountTag];
    [deletePrompt show];
    [deletePrompt release];
}

- (NSInteger)indexForAccount:(AccountInfo *)account inArray:(NSArray *)accountArray 
{
    NSInteger index = -1;
    
    for(NSInteger i = 0; i < [accountArray count]; i++) {
        AccountInfo *currAccount = [accountArray objectAtIndex:i];
        if([[currAccount uuid] isEqualToString:[account uuid]]) {
            index = i;
            break;
        }
    }
    
    return index;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex 
{
    if([alertView tag] == kAlertDeleteAccountTag) 
    {
        if(buttonIndex == 1) 
        {
            //Delete account
            [[AccountManager sharedManager] removeAccountInfo:accountInfo];
        } 
    } 
    else if([alertView tag] == kAlertPortProtocolTag) 
    {
        if(buttonIndex == 1) 
        {
            [self saveAccount];
        }
    }
}

#pragma mark - IFCellControllerFirstResponder
- (void)lastResponderIsDone: (NSObject<IFCellController> *)cellController
{
	[super lastResponderIsDone:cellController];
    [self saveButtonClicked:cellController];
}

#pragma mark - NorificationCenter actions
- (void)handleAccountListUpdated:(NSNotification *)notification
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(handleAccountListUpdated:) withObject:notification waitUntilDone:NO];
        return;
    }
    
    NSString *updateType = [[notification userInfo] objectForKey:@"type"];
    NSString *uuid = [[notification userInfo] objectForKey:@"uuid"];
    if ([updateType isEqualToString:kAccountUpdateNotificationDelete] && [[accountInfo uuid] isEqualToString:uuid])
    {
        if (IS_IPAD)
        {
            [IpadSupport clearDetailController];
        }
        else
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    else if ([updateType isEqualToString:kAccountUpdateNotificationEdit] && [uuid isEqualToString:self.accountInfo.uuid])
    {
        [self setAccountInfo:[[AccountManager sharedManager] accountInfoForUUID:uuid]];
        [self setModel:[self accountInfoToModel:accountInfo]];
        [self setTitle:[self.accountInfo description]];
        [self updateAndReload];
    }
    
}

#pragma mark - MBProgressHUD Helper Methods

- (void)hudWasHidden:(MBProgressHUD *)hud
{
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


@end
