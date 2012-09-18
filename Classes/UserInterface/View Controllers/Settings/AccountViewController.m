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
#import "AppProperties.h"
#import "FDRowRenderer.h"
#import "AccountStatusService.h"
#import "FDMultilineCellController.h"
#import "ConnectivityManager.h"
#import "FavoriteManager.h"

static NSInteger kAlertPortProtocolTag = 0;
static NSInteger kAlertDeleteAccountTag = 1;

@interface AccountViewController (private)
- (IFTemporaryModel *)accountInfoToModel:(AccountInfo *)anAccountInfo;
- (void)updateAccountInfo:(AccountInfo *)anAccountInfo withModel:(id<IFCellModel>)tempModel;
- (void)saveButtonClicked:(id)sender;
- (void)saveAccount;
- (void)addExtensionsToGroups:(NSMutableArray *)groups andHeaders:(NSMutableArray *)headers;
- (BOOL)validateAccountFieldsOnServer;
- (int)requestToCloud;
- (BOOL)validateAccountFieldsOnCloud;
- (int)requestToStandardServer;
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
@synthesize saveButton;
@synthesize HUD;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [accountInfo release];
    [saveButton release];
    [HUD release];
    [_vendorSelection release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

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
    } else {
        //Ideally pushed in a navigation stack
        [self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editAccount:)] autorelease]];
    }
    
    [saveButton setEnabled:[self validateAccountFieldsValues]];
    
    shouldSetResponder = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAccountListUpdated:) 
                                                 name:kNotificationAccountListUpdated object:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationAccountListUpdated object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (shouldSetResponder)
    {
        for(NSArray *group in tableGroups)
        {
            for(id cell in group)
            {
                if([cell conformsToProtocol:@protocol(IFCellControllerFirstResponder)])
                {
                    [(id<IFCellControllerFirstResponder>)cell becomeFirstResponder];
                    shouldSetResponder = NO;
                    break;
                }
            }
            
            if(!shouldSetResponder)
            {
                break;
            }
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (accountInfoNeedsToBeSaved)
    {
        accountInfoNeedsToBeSaved = NO;
        [[AccountManager sharedManager] saveAccountInfo:accountInfo withNotification:YES];
    }
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
        NSString *port = [model objectForKey:kAccountPortKey];
        port = [port stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (port == nil) {
            [model setObject:@"" forKey:port];
            port = @"";
        }
    
        BOOL https = [[model objectForKey:kAccountBoolProtocolKey] boolValue];
        BOOL portConflictDetected = ((https && [port isEqualToString:kFDHTTP_DefaultPort]) || (!https && [port isEqualToString:kFDHTTPS_DefaultPort]));

        if (portConflictDetected) 
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
    if([self.accountInfo.accountStatusInfo isError])
    {
        //We clear the errors when saving an account
        [self.accountInfo setAccountStatus:FDAccountStatusActive];
        [[AccountStatusService sharedService] synchronize];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationAccountListUpdated object:nil];
    
    accountInfoNeedsToBeSaved = YES;

    [self stopHUD];
    if (delegate)
    {
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
    if([self.accountInfo accountStatus] == FDAccountStatusInactive)
    {
        //For inactive account we don't test the connection
        return YES;
    }
    else if ([[model objectForKey:kAccountMultitenantKey] boolValue]) {
        return [self validateAccountFieldsOnCloud];
    }
    else 
    {
        return [self validateAccountFieldsOnStandardServer];
    }
    
}

- (int)requestToCloud
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
    
    NSString *cloudKeyValue = externalAPIKey(APIKeyAlfrescoCloud);
    NSString *urlStringCloud = [NSString stringWithFormat:@"%@://%@:%@%@/a/-default-/internal/cloud/user/%@/accounts",protocol,hostname,port,servicePath,username];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlStringCloud]];                                        
    if (nil == request) 
    {
        return 400;
    }
    [request addRequestHeader:@"key" value:cloudKeyValue];
    [request addBasicAuthenticationHeaderWithUsername:username andPassword:password];
    
    [request setTimeOutSeconds:20];
    [request setValidatesSecureCertificate:userPrefValidateSSLCertificate()];
    [request setUseSessionPersistence:NO];
    [request startSynchronous];
    return [request responseStatusCode];
}

- (BOOL)validateAccountFieldsOnCloud
{
    if([[self.model objectForKey:@"description"] isEqualToString:@""] || [self.model objectForKey:@"description"] == nil)
    {
        [self.model setObject:@"Alfresco Cloud" forKey:@"description"];
    }
    
    NSString *password = [[model objectForKey:kAccountPasswordKey] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (password == nil || [password isEqualToString:@""]) 
    {
        return YES;
    }
    
    int statusCode = [self requestToCloud];
    if (200 <= statusCode && 299 >= statusCode) 
    {
        return YES;
    }
    else 
    {
        return NO;
    }    
}

- (int)requestToStandardServer
{
    NSString *protocol = [[model objectForKey:kAccountBoolProtocolKey]boolValue] ? kFDHTTPS_Protocol : kFDHTTP_Protocol;
    NSString *hostname = [model objectForKey:kAccountHostnameKey];
    NSString *servicePath = [model objectForKey:kAccountServiceDocKey];
    NSString *port = [model objectForKey:kAccountPortKey];
    NSString *username = [model objectForKey:kAccountUsernameKey];
    NSString *password = [[model objectForKey:kAccountPasswordKey] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSString *uri = [NSString stringWithFormat:@"%@://%@:%@%@",protocol,hostname,port,servicePath];
    NSURL *url = [NSURL URLWithString:uri];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    if (nil == request) 
    {
        return 400;
    }
    [request addBasicAuthenticationHeaderWithUsername:username andPassword:password];
    [request setTimeOutSeconds:20];
    [request setValidatesSecureCertificate:userPrefValidateSSLCertificate()];
    [request setUseSessionPersistence:NO];
    [request startSynchronous];
    return [request responseStatusCode];
}

- (BOOL)validateAccountFieldsOnStandardServer
{
    NSString *password = [[model objectForKey:kAccountPasswordKey] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    int statusCode = [self requestToStandardServer];
    
    if ((password == nil || [password isEqualToString:@""]) && statusCode == 401) 
    {
        return YES;
    }
    
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

- (void)accountControllerDidFinishSaving:(AccountViewController *)accountViewController
{
    [accountViewController dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark GenericViewController

- (void)constructTableGroups
{
    if (![self.model isKindOfClass:[IFTemporaryModel class]]) {
        [self setModel:[self accountInfoToModel:accountInfo]];
	}
    
    NSDictionary *accountConfiguration = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"AccountConfiguration" ofType:@"plist"]];
    NSString *stringsTable = [accountConfiguration objectForKey:@"StringsTable"];
    FDRowRenderer *rowRenderer = nil;
    if(![self.accountInfo isMultitenant])
    {
        NSArray *accountFields = [accountConfiguration objectForKey:@"AccountFields"];
        rowRenderer = [[[FDRowRenderer alloc] initWithSettings:accountFields stringsTable:stringsTable andModel:self.model] autorelease];
    }
    else 
    {
        NSArray *accountFields = [accountConfiguration objectForKey:@"CloudAccountFields"];
        rowRenderer = [[[FDRowRenderer alloc] initWithSettings:accountFields stringsTable:stringsTable andModel:self.model] autorelease];
    }
    
    [rowRenderer setUpdateTarget:self];
    [rowRenderer setUpdateAction:@selector(textValueChanged:)];
    
    if(!self.isEdit)
    {
        [rowRenderer setReadOnlyCellClass:[MetaDataCellController class]];
        [rowRenderer setReadOnly:YES];
    }
    
    // Arrays for section headers, bodies and footers
	NSMutableArray *headers = [[rowRenderer headers] retain];
	NSMutableArray *groups =  [[rowRenderer groups] retain];
    
    /*
     Adding the extensions fields (if present) read from the AccountConfiguration.plist
     */
    [self addExtensionsToGroups:groups andHeaders:headers];
    
    if(!isEdit) 
    {
        NSString *errorMessage = [self.accountInfo.accountStatusInfo detailedMessage];
        if(errorMessage)
        {
            FDMultilineCellController *errorCell = [[[FDMultilineCellController alloc] initWithTitle:errorMessage andSubtitle:nil inModel:self.model] autorelease];
            [errorCell setCellImage:[UIImage imageNamed:kImageUIButtonBarBadgeError]];
            [errorCell setTitleTextColor:[UIColor redColor]];
            [errorCell setTitleFont:[UIFont systemFontOfSize:[UIFont systemFontSize]]];
            
            //We are "hardcoding" the error cell at the end of the first cell group, in the current implementation 
            //is right after the Account active/inactive switch.
            //Since it involves a lot of customization (custom image, text color and font) it's too much
            //for the FDRowRender to handle for this special case.
            //Maybe refactoring it to support extensions?
            [[groups objectAtIndex:0] addObject:errorCell];
        }
        
        // account is active, password is not set and sync is enabled - show a warning
        BOOL isSyncEnabled = [[FavoriteManager sharedManager] isSyncEnabled];
        if (isSyncEnabled && [self.accountInfo.accountStatusInfo isActive] && (!self.accountInfo.password || [self.accountInfo.password isEqualToString:@""]))
        {
            NSString *warningMessage = NSLocalizedString(@"accountdetails.fields.no-password-warning", @"Password is not set message");
            FDMultilineCellController *errorCell = [[[FDMultilineCellController alloc] initWithTitle:warningMessage andSubtitle:nil inModel:self.model] autorelease];
            [errorCell setCellImage:[UIImage imageNamed:@"ui-button-bar-badge-warning"]];
            [errorCell setTitleFont:[UIFont systemFontOfSize:[UIFont systemFontSize]]];
            
            // Like the error message cell, we are adding this cell manually as it is too complex for FDRowRender to handle
            [[groups objectAtIndex:0] addObject:errorCell];
        }
        
        if([self.accountInfo accountStatus] != FDAccountStatusInactive)
        {
            IFButtonCellController *browseDocumentsCell = [[[IFButtonCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.buttons.browse", @"Browse Documents")
                                                                                              withAction:@selector(browseDocuments:) 
                                                                                                onTarget:self] autorelease];
            [browseDocumentsCell setBackgroundColor:[UIColor whiteColor]];
            [browseDocumentsCell setTextColor:[UIColor blackColor]];
            NSMutableArray *browseCellGroup = [NSMutableArray arrayWithObjects:browseDocumentsCell,nil];
            [headers addObject:@""];
            [groups addObject:browseCellGroup];
        }
        
        IFButtonCellController *deleteAccountCell = [[[IFButtonCellController alloc] initWithLabel:NSLocalizedString(@"accountdetails.buttons.delete", @"Delete Account")
                                                                                        withAction:@selector(promptDeleteAccount:) 
                                                                                          onTarget:self] autorelease];
        [deleteAccountCell setBackgroundColor:[UIColor redColor]];
        [deleteAccountCell setTextColor:[UIColor whiteColor]];

        NSMutableArray *deleteCellGroup = [NSMutableArray arrayWithObjects:deleteAccountCell,nil];
        [headers addObject:@""];
        [groups addObject:deleteCellGroup];
    }
    
    tableGroups = groups;
	tableHeaders = headers;
	[self assignFirstResponderHostToCellControllers];
}

- (void)addExtensionsToGroups:(NSMutableArray *)groups andHeaders:(NSMutableArray *)headers
{
    NSString *vendorName = [self.model objectForKey:kAccountVendorKey];
    NSDictionary *extensions = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"AccountConfiguration" ofType:@"plist"]];
    NSArray *extensionVendors = [extensions objectForKey:@"ExtensionVendors"];
    if([extensionVendors containsObject:vendorName])
    {
        NSString *stringsTable = [extensions objectForKey:@"StringsTable"];
        NSString *extensionsDictName = [extensions objectForKey:@"AccountExtensionsDictionary"];
        NSMutableDictionary *serverInformation = [self.model objectForKey:kAccountServerInformationKey];
        NSMutableDictionary *extensionsDatasource = [serverInformation objectForKey:extensionsDictName];
        NSArray *extensionSettings = [extensions objectForKey:@"AccountExtensions"];
        if(!extensionsDatasource)
        {
            extensionsDatasource = [NSMutableDictionary dictionaryWithCapacity:[extensionSettings count]];
        }
        // IFTemporaryModel creates a new dictionary, we need to retrieve that dictionary to avoid
        // retrieving this model before saving the account
        IFTemporaryModel *extensionsModel = [[IFTemporaryModel alloc] initWithDictionary:extensionsDatasource];
        extensionsDatasource = [extensionsModel dictionary];
        [serverInformation setObject:extensionsDatasource forKey:extensionsDictName];
        
        FDRowRenderer *rowRenderer = [[FDRowRenderer alloc] initWithSettings:extensionSettings stringsTable:stringsTable andModel:extensionsModel];
        
        if(!self.isEdit)
        {
            [rowRenderer setReadOnlyCellClass:[MetaDataCellController class]];
            [rowRenderer setReadOnly:YES];
        }
        else if([self cellsContainDoneKey:[rowRenderer groups]])
        {
            [self changeDoneReturnKeyForType:UIReturnKeyNext inCellGroups:groups];
        }
        
        [headers addObjectsFromArray:[rowRenderer headers]];
        [groups addObjectsFromArray:[rowRenderer groups]];
        [rowRenderer release];
        [extensionsModel release];
    }
}

- (BOOL)cellsContainDoneKey:(NSArray *)groups
{
    for(NSArray *group in groups)
    {
        for (id cellController in group) {
            if([cellController respondsToSelector:@selector(returnKeyType)] && 
               [cellController returnKeyType] == UIReturnKeyDone)
            {
                return YES;
            }
        }
    }
    return NO;
}

- (void)changeDoneReturnKeyForType:(UIReturnKeyType)type inCellGroups:(NSArray *)groups
{
    for(NSArray *group in groups)
    {
        for (id cellController in group) {
            if([cellController respondsToSelector:@selector(returnKeyType)] && 
               [cellController returnKeyType] == UIReturnKeyDone && 
               [cellController respondsToSelector:@selector(setReturnKeyType:)])
            {
                [cellController setReturnKeyType:type];
            }
        }
    }
}


- (void) setObjectIfNotNil: (id) object forKey: (NSString *) key inModel:(IFTemporaryModel *)tempModel {
    if(object) {
        [tempModel setObject:object forKey:key];
    }
}

- (NSArray *)allVendorNames
{
    NSArray *vendors = [AppProperties propertyForKey:kAccountsVendors];
    NSMutableArray *vendorNames = [NSMutableArray arrayWithCapacity:[vendors count]];
    
    for(NSDictionary *vendor in vendors)
    {
        [vendorNames addObject:NSLocalizedString([vendor objectForKey:@"name"], @"localized vendor name" )];
    }
    
    return vendorNames;
}

- (NSString *)defaultServiceDocumentForVendor:(NSString *)vendorName
{
    NSArray *vendors = [AppProperties propertyForKey:kAccountsVendors];
    
    // The vendor name from the app property is the key to the localized and the vendorName is the localized string
    // we have to localize the key and then compare it with the vendorName
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        NSString *localizedName = NSLocalizedString([evaluatedObject objectForKey:@"name"], @"localized vendor name");
        return [localizedName isEqualToString:vendorName];
    }];
    NSArray *results = [vendors filteredArrayUsingPredicate:predicate];
    if([results count] > 0)
    {
        NSDictionary *vendor = [results objectAtIndex:0];
        return [vendor objectForKey:@"serviceDocument"];
    }
    
    return nil;
}

- (id)defaultServiceDocumentLocationsArray
{
    NSArray *vendors = [AppProperties propertyForKey:kAccountsVendors];
    return [vendors valueForKeyPath:@"serviceDocument"];
}

#pragma mark - Cell actions
- (void)textValueChanged:(id)sender
{
    if(self.isEdit)
    {
        [saveButton setEnabled:[self validateAccountFieldsValues]];
        
        if(_vendorSelection && ![_vendorSelection isEqualToString:[self.model objectForKey:kAccountVendorKey]])
        {
            [_vendorSelection release];
            _vendorSelection = [[self.model objectForKey:kAccountVendorKey] copy];
            [self vendorSelectionChanged:sender];
        }
        
        if(_protocolSelection != [[self.model objectForKey:kAccountBoolProtocolKey] boolValue])
        {
            _protocolSelection = [[self.model objectForKey:kAccountBoolProtocolKey] boolValue];
            [self protocolUpdate:sender];
        }
    }
    else 
    {
        //When not editing the only setting that can change is the account stauts (active/inactive)
        BOOL boolStatus = [[self.model objectForKey:kAccountBoolStatusKey] boolValue];
        [self startHUD];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
            if(boolStatus)
            {
                [self.accountInfo setAccountStatus:FDAccountStatusActive];
                //We need to test the connection on account reactivate
                //only when there's a network connection available
                if([[ConnectivityManager sharedManager] hasInternetConnection])
                {
                    [self checkAccountReActivate];
                }
            }
            else 
            {
                [self.accountInfo setAccountStatus:FDAccountStatusInactive];
            }
            [[AccountStatusService sharedService] synchronize];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postAccountListUpdatedNotification:[NSDictionary dictionaryWithObject:[self.accountInfo uuid] forKey:@"uuid"]];
                [self updateAndReload];
                [self stopHUD];
            });
        });
    }
}

- (void)checkAccountReActivate
{
    NSString *password = [[model objectForKey:kAccountPasswordKey] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    int statusCode = 200;
    if([self.accountInfo isMultitenant])
    {
        if (password == nil || [password isEqualToString:@""]) 
        {
            return;
        }
        
        statusCode = [self requestToCloud];
    }
    else 
    {
        statusCode = [self requestToStandardServer];
        if ((password == nil || [password isEqualToString:@""]) && statusCode == 401) 
        {
            return;
        }
    }
    
    if (statusCode == 401) 
    {
        [self.accountInfo setAccountStatus:FDAccountStatusInvalidCredentials];
    }
    else if(200 > statusCode || 299 <= statusCode)
    {
        [self.accountInfo setAccountStatus:FDAccountStatusConnectionError];
    }    
}

- (void)vendorSelectionChanged:(id)sender
{
    NSString *newVendor = [self.model objectForKey:kAccountVendorKey];
    NSString *serviceDocPath = [[self.model objectForKey:kAccountServiceDocKey] trimWhiteSpace];
    
    if (!serviceDocPath || ([serviceDocPath length] == 0) || [[self defaultServiceDocumentLocationsArray] containsObject:serviceDocPath])
    {
        NSString *defaultServiceDoc = [self defaultServiceDocumentForVendor:newVendor];
        [self.model setObject:defaultServiceDoc forKey:kAccountServiceDocKey];
    }
    
    [self updateAndReload];
}

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
    
    NSNumber *boolStatus = [NSNumber numberWithBool:[anAccountInfo accountStatus] != FDAccountStatusInactive];
    
    [self setObjectIfNotNil:boolProtocol forKey:kAccountBoolProtocolKey inModel:tempModel];
    [self setObjectIfNotNil:protocolDisplay forKey:kAccountProtocolKey inModel:tempModel];
    [self setObjectIfNotNil:boolStatus forKey:kAccountBoolStatusKey inModel:tempModel];
    [self setObjectIfNotNil:[anAccountInfo hostname] forKey:kAccountHostnameKey inModel:tempModel];
    [self setObjectIfNotNil:[anAccountInfo port] forKey:kAccountPortKey inModel:tempModel];
    [self setObjectIfNotNil:[anAccountInfo serviceDocumentRequestPath] forKey:kAccountServiceDocKey inModel:tempModel];
    [self setObjectIfNotNil:[anAccountInfo username] forKey:kAccountUsernameKey inModel:tempModel];
    [self setObjectIfNotNil:[anAccountInfo password] forKey:kAccountPasswordKey inModel:tempModel];
    if ([anAccountInfo password] && ![[anAccountInfo password] isEqualToString:@""]) {
        [self setObjectIfNotNil:@"************" forKey:@"securePassword" inModel:tempModel];
    } else {
        [self setObjectIfNotNil:@"Not Set" forKey:@"securePassword" inModel:tempModel];
    }
    
    [self setObjectIfNotNil:[anAccountInfo multitenant] forKey:kAccountMultitenantKey inModel:tempModel];
    
    if(![anAccountInfo infoDictionary])
    {
        [anAccountInfo setInfoDictionary:[NSMutableDictionary dictionary]];
    }
    [tempModel setObject:[anAccountInfo infoDictionary] forKey:kAccountServerInformationKey];
    
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
    [anAccountInfo setInfoDictionary:[tempModel objectForKey:kAccountServerInformationKey]];
    
    NSNumber *multitenantBoolNumber = [tempModel objectForKey:kAccountMultitenantKey];
    [anAccountInfo setMultitenant:multitenantBoolNumber];
}

- (void)browseDocuments:(id)sender 
{
    [self.navigationController popToRootViewControllerAnimated:NO];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[accountInfo uuid] forKey:@"accountUUID"];
    [[NSNotificationCenter defaultCenter] postBrowseDocumentsNotification:userInfo];
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
