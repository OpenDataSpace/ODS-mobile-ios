//
//  CreateLinkViewController.m
//  FreshDocs
//
//  Created by bdt on 6/11/14.
//
//

#import "CreateLinkViewController.h"
#import "Utility.h"
#import "FDRowRenderer.h"
#import "IFTemporaryModel.h"
#import "CMISCreateLinkHTTPRequest.h"

@interface CreateLinkViewController ()

@end

@implementation CreateLinkViewController
@synthesize delegate = _delegate;
@synthesize createButton = _createButton;
@synthesize progressHUD = _progressHUD;
@synthesize repositoryItem = _repositoryItem;
@synthesize accountUUID = _accountUUID;
@synthesize linkCreateURL = _linkCreateURL;

- (void) dealloc {
    _delegate = nil;
    _createButton = nil;
    _progressHUD = nil;
    _repositoryItem = nil;
    _accountUUID = nil;
    _linkCreateURL = nil;
}

- (id)initWithRepositoryItem:(RepositoryItem *)repoItem accountUUID:(NSString *)accountUUID {
    if (self = [super init])
    {
        self.repositoryItem = repoItem;
        self.accountUUID = accountUUID;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    // Create button
    
    //if (IS_IPAD) {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(handleCancelButton:)];
        cancelButton.title = NSLocalizedString(@"cancelButton", @"Cancel");
        self.navigationItem.leftBarButtonItem = cancelButton;
    //}
    
    UIBarButtonItem *createButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Create", @"Create")
                                                                     style:UIBarButtonItemStyleDone
                                                                    target:self
                                                                    action:@selector(handleCreateButton:)];
    createButton.enabled = NO;
    styleButtonAsDefaultAction(createButton);
    self.navigationItem.rightBarButtonItem = createButton;
    self.createButton = createButton;
    
    // Empty model
    self.model = [[IFTemporaryModel alloc] initWithDictionary:[NSMutableDictionary dictionary]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setCellControllerFirstResponder {
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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Set the first responder
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0 && IS_IPAD)
    {
        [self performSelector:@selector(setCellControllerFirstResponder) withObject:nil afterDelay:.2];
    }
    else {
        [self setCellControllerFirstResponder];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (BOOL)validateFormValues  //TODO:validate form values for create link.
{
    //email, subject, expirationdate, password, message
    
    BOOL isValid = YES;
    
    NSString *linkName = [self.model objectForKey:@"email"];
    if (linkName == nil  || [linkName rangeOfString:@"^.+@.+\\..{2,}$" options:NSRegularExpressionSearch].location == NSNotFound)
    {
        // Name check against regex - requires no match
        isValid = NO;
    }
    
    NSString *subject = [self.model objectForKey:@"subject"];
    if (subject == nil || [subject length] < 1) {
        isValid = NO;
    }
    
    NSString *message = [self.model objectForKey:@"message"];
    if ( message == nil || [message length] < 1) {
        isValid = NO;
    }
    
    return isValid;
}

#pragma mark - IFGenericTableView

- (void)constructTableGroups
{
    NSDictionary *configuration = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"CreateLinkConfiguration" ofType:@"plist"]];
    FDRowRenderer *rowRenderer = [[FDRowRenderer alloc] initWithSettings:configuration[@"CreateLinkFields"]
                                                            stringsTable:configuration[@"StringsTable"]
                                                                andModel:self.model];
    
    [rowRenderer setUpdateTarget:self];
    [rowRenderer setUpdateAction:@selector(textValueChanged:)];
    
    tableGroups = rowRenderer.groups;
	tableHeaders = rowRenderer.headers;
	[self assignFirstResponderHostToCellControllers];
}

- (void)textValueChanged:(id)sender
{
    self.createButton.enabled = [self validateFormValues];
}

#pragma mark -
#pragma mark Handle Expiration Date
- (NSDate *) handleExpirationDate:(NSDate*) orgDate {
    
    NSInteger unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit;
    NSDateComponents *orgDateComponents = [[NSCalendar currentCalendar] components:unitFlags fromDate:orgDate == nil?[NSDate date]: orgDate];
    [orgDateComponents setDay:[orgDateComponents day] + 1];
    [orgDateComponents setHour:0];
    [orgDateComponents setMinute:0];
    [orgDateComponents setSecond:0];
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    [cal setTimeZone:[NSTimeZone localTimeZone]];
    [cal setLocale:[NSLocale currentLocale]];
    
    NSDate *newDate = [cal dateFromComponents:orgDateComponents];
    
    return newDate;
}

#pragma mark - UI event handlers

- (void)handleCancelButton:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^(void) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(createLinkCancelled:)])
        {
            [self.delegate performSelector:@selector(createLinkCancelled:) withObject:self];
        }
    }];
}

- (void)handleCreateButton:(id)sender 
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = NSLocalizedString(@"creating.link", @"Creating link...");
    self.progressHUD = hud;
    [self.view resignFirstResponder];    
	
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyy-MM-dd'T'HH:mm:ss'Z'"];
    NSDate *dateSelected = [self handleExpirationDate:[self.model objectForKey:@"expirationdate"]];
    NSString *expirationDate = [dateFormatter stringFromDate: dateSelected == nil?[NSDate date]: dateSelected];
    NSDictionary *linkInfo =[NSDictionary dictionaryWithObjectsAndKeys:[self.model objectForKey:@"email"], @"Email",
                          [self.model objectForKey:@"subject"], @"Subject",
                          [self.model objectForKey:@"message"], @"Message",
                          expirationDate, @"ExpirationDate",
                             [self.model objectForKey:@"password"], @"Password",nil];
    
    CMISCreateLinkHTTPRequest *request = [CMISCreateLinkHTTPRequest cmisCreateLinkRequestWithItem:_repositoryItem destURL:_linkCreateURL linkType:@"gds:downloadLink" linkInfo:linkInfo accountUUID:_accountUUID];
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
        if (self.delegate && [self.delegate respondsToSelector:@selector(createLink:succeededForName:)])
        {
            [self.delegate performSelector:@selector(createLink:succeededForName:) withObject:self withObject:[self.model objectForKey:@"email"]];
        }
    }];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    stopProgressHUD(self.progressHUD);
    if (self.delegate && [self.delegate respondsToSelector:@selector(createLink:failedForName:)])
    {
        [self.delegate performSelector:@selector(createLink:failedForName:) withObject:self withObject:[self.model objectForKey:@"email"]];
    }
    
    // Specific error message for "duplicate item" conflict
    //NSString *errorMessageKey = (request.responseStatusCode == 409) ? @"create-folder.duplicate" : @"create-folder.failure";
    //displayErrorMessage([NSString stringWithFormat:NSLocalizedString(errorMessageKey, @"Failed to create folder"), [self.model objectForKey:@"name"]]);
}

/*- (UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UISegmentedControl *segControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Upload Link", @"Download Link", nil]];
    [segControl setSegmentedControlStyle:UISegmentedControlStyleBar];
    [segControl setSelectedSegmentIndex:0];
    
    return segControl;
}

- (float) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30.0f;
}*/

@end
