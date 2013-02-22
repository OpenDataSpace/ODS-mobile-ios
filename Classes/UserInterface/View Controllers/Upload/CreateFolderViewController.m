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
 *
 * ***** END LICENSE BLOCK ***** */
//
//  CreateFolderViewController.m
//

#import "CreateFolderViewController.h"
#import "CMISCreateFolderHTTPRequest.h"
#import "Utility.h"
#import "FDRowRenderer.h"
#import "IFTemporaryModel.h"

@implementation CreateFolderViewController

- (void)dealloc
{
    _delegate = nil;
    [_createButton release];
    [_progressHUD release];
    [_parentItem release];
    [_accountUUID release];
    [super dealloc];
}

- (id)initWithParentItem:(RepositoryItem *)parentItem accountUUID:(NSString *)accountUUID
{
    if (self = [super init])
    {
        self.parentItem = parentItem;
        self.accountUUID = accountUUID;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Cancel button
    UIBarButtonItem *cancelButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(handleCancelButton:)] autorelease];
    cancelButton.title = NSLocalizedString(@"cancelButton", @"Cancel");
    self.navigationItem.leftBarButtonItem = cancelButton;

    // Create button
    UIBarButtonItem *createButton = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Create", @"Create")
                                                                      style:UIBarButtonItemStyleDone
                                                                     target:self
                                                                     action:@selector(handleCreateButton:)] autorelease];
    createButton.enabled = NO;
    styleButtonAsDefaultAction(createButton);
    self.navigationItem.rightBarButtonItem = createButton;
    self.createButton = createButton;

    // Empty model
    self.model = [[[IFTemporaryModel alloc] initWithDictionary:[NSMutableDictionary dictionary]] autorelease];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Set the first responder
    for (NSArray *group in tableGroups)
    {
        for (id cell in group)
        {
            if ([cell conformsToProtocol:@protocol(IFCellControllerFirstResponder)])
            {
                [(id<IFCellControllerFirstResponder>)cell becomeFirstResponder];
                return;
            }
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (BOOL)validateFormValues
{
    NSString *folderName = [self.model objectForKey:@"name"];
    BOOL isValid = (folderName.length > 0);
    
    if (isValid)
    {
        NSError *error = nil;
        // Regex taken from Alfresco Share's forms-runtime.js "node name" validation handler
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([\"*\\><\?/:|]+)|([.]?[.]+$)" options:0 error:&error];
        NSArray *matches = [regex matchesInString:folderName options:0 range:NSMakeRange(0, folderName.length)];

        isValid = (matches.count == 0);
    }
    
    return isValid;
}

#pragma mark - IFGenericTableView

- (void)constructTableGroups
{
    NSDictionary *configuration = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"CreateFolderConfiguration" ofType:@"plist"]];
    FDRowRenderer *rowRenderer = [[[FDRowRenderer alloc] initWithSettings:configuration[@"CreateFolderFields"]
                                                             stringsTable:configuration[@"StringsTable"]
                                                                 andModel:self.model] autorelease];
    
    [rowRenderer setUpdateTarget:self];
    [rowRenderer setUpdateAction:@selector(textValueChanged:)];
    
    tableGroups = [rowRenderer.groups retain];
	tableHeaders = [rowRenderer.headers retain];
	[self assignFirstResponderHostToCellControllers];
}

- (void)textValueChanged:(id)sender
{
    self.createButton.enabled = [self validateFormValues];
}

#pragma mark - UI event handlers

- (void)handleCancelButton:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^(void) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(createFolderCancelled:)])
        {
            [self.delegate performSelector:@selector(createFolderCancelled:) withObject:self];
        }
    }];
}

- (void)handleCreateButton:(id)sender
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = NSLocalizedString(@"create-folder.in-progress", @"Creating folder...");
    self.progressHUD = hud;
    [self.view resignFirstResponder];

	NSString *folderName = [self.model objectForKey:@"name"];
    CMISCreateFolderHTTPRequest *request = [CMISCreateFolderHTTPRequest cmisCreateFolderRequestNamed:folderName
                                                                                          parentItem:self.parentItem
                                                                                         accountUUID:self.accountUUID];
    request.delegate = self;
    request.suppressAllErrors = YES;
    request.ignore500StatusError = YES;
    [request startAsynchronous];
}

#pragma mark ASIHttpRequest delegate

- (void)requestFinished:(ASIHTTPRequest *)request
{
    stopProgressHUD(self.progressHUD);
    [self dismissViewControllerAnimated:YES completion:^(void) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(createFolder:succeededForName:)])
        {
            [self.delegate performSelector:@selector(createFolder:succeededForName:) withObject:self withObject:[self.model objectForKey:@"name"]];
        }
    }];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    stopProgressHUD(self.progressHUD);
    if (self.delegate && [self.delegate respondsToSelector:@selector(createFolder:failedForName:)])
    {
        [self.delegate performSelector:@selector(createFolder:failedForName:) withObject:self withObject:[self.model objectForKey:@"name"]];
    }

    // Specific error message for "duplicate item" conflict
    NSString *errorMessageKey = (request.responseStatusCode == 409) ? @"create-folder.duplicate" : @"create-folder.failure";
    displayErrorMessage([NSString stringWithFormat:NSLocalizedString(errorMessageKey, @"Failed to create folder"), [self.model objectForKey:@"name"]]);
}

@end
