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
 * Portions created by the Initial Developer are Copyright (C) 2011
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  SimpleSettingsViewController.m
//

#import "SimpleSettingsViewController.h"
#import "IFPreferencesModel.h"
#import "IFTextCellController.h"
#import "Theme.h"

@implementation SimpleSettingsViewController
@synthesize delegate;
@synthesize originalUsername;
@synthesize originalPassword;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [originalPassword release];
    [originalUsername release];
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

    [self.view setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    [[self navigationItem] setTitle:NSLocalizedString(@"SimpleSettingsViewTitle", "The title for the login credentials view from the main app")];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"flip.settings.login", @"Login") 
                                                                   style:UIBarButtonItemStylePlain 
                                                                  target:self action:@selector(done:)];
///    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
    [self.navigationItem setLeftBarButtonItem:doneButton];
    [doneButton release];
    
    [[NSUserDefaults standardUserDefaults] setObject:@"NO" forKey:@"isFirstLaunch"];
    if([[[NSUserDefaults standardUserDefaults] objectForKey:@"isFirstLaunch"] isEqualToString:@"NO"]) {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
        [self.navigationItem setRightBarButtonItem:cancelButton];
        [cancelButton release];
    }
    
    if (![self.model isKindOfClass:[IFPreferencesModel class]]) {
		model = [[IFPreferencesModel alloc] init];
	}
    self.originalUsername = [model objectForKey:@"username"];
    self.originalPassword = [model objectForKey:@"password"];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;//  (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 2;
}


#pragma mark -
#pragma IBActions 
- (IBAction)done:(id)sender {
    BOOL settingsValueDidChange = ![originalPassword isEqualToString:[model objectForKey:@"password"]] || ![originalUsername isEqualToString:[model objectForKey:@"username"]];
	[self.delegate simpleSettingsViewDidFinish:self settingsDidChange:settingsValueDidChange];
}

- (IBAction)cancel:(id)sender {
    [model setObject:originalPassword forKey:@"password"];
    [model setObject:originalUsername forKey:@"username"];
	[self.delegate simpleSettingsViewDidFinish:self settingsDidChange:NO];
}

- (IBAction)settingsValueChanged:(id)sender 
{
    [[NSUserDefaults standardUserDefaults] setObject:@"NO" forKey:@"isFirstLaunch"];
}

#pragma mark GenericTableView stuff

- (void)constructTableGroups {

	if (![self.model isKindOfClass:[IFPreferencesModel class]]) {
		model = [[IFPreferencesModel alloc] init];
	}
    
    // Arrays for section headers, bodies and footers
	NSMutableArray *headers = [NSMutableArray array];
	NSMutableArray *groups =  [NSMutableArray array];
	NSMutableArray *footers = [NSMutableArray array];

    
    NSMutableArray *loginCredentialsCellGroup = [NSMutableArray arrayWithCapacity:2];
    
  	IFTextCellController *cellController = nil;
    
    // Username
    cellController = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"flip.settings.username", @"FlipView Settings Username Label")
                                                   andPlaceholder:@""
                                                            atKey:@"username"
                                                          inModel:model] autorelease];
    [cellController setReturnKeyType:UIReturnKeyNext];
    [cellController setKeyboardType:UIKeyboardTypeAlphabet];
    [cellController setAutocorrectionType:UITextAutocorrectionTypeNo];
    [cellController setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [cellController setUpdateTarget:self];
    [cellController setUpdateAction:@selector(settingsValueChanged:)];
    
    
    [loginCredentialsCellGroup addObject:cellController];
    
    // Password
    cellController = [[[IFTextCellController alloc] initWithLabel:NSLocalizedString(@"flip.settings.password", @"FlipView Settings Password Label") 
                                                   andPlaceholder:@"" 
                                                            atKey:@"password" 
                                                          inModel:model] autorelease];
    [cellController setReturnKeyType:UIReturnKeyDefault];
    [cellController setKeyboardType:UIKeyboardTypeAlphabet];
    [cellController setAutocorrectionType:UITextAutocorrectionTypeNo];
    [cellController setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [cellController setSecureTextEntry:YES];
    [cellController setUpdateTarget:self];
    [cellController setUpdateAction:@selector(settingsValueChanged:)];
    [loginCredentialsCellGroup addObject:cellController];
    
    
    [headers addObject:NSLocalizedString(@"flip.settings.credentials.group.label", @"Login Credentials")];
	[groups addObject:loginCredentialsCellGroup];
	[footers addObject:@""];
    
    tableGroups = [groups retain];
	tableHeaders = [headers retain];
	tableFooters = [footers retain];
	
	[self assignFirstResponderHostToCellControllers];
}


@end
