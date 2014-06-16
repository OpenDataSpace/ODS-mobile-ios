//
//  LinkManagementViewController.m
//  FreshDocs
//
//  Created by bdt on 6/9/14.
//
//

#import "LinkManagementViewController.h"
#import "LinkTableViewCell.h"
#import "CreateLinkViewController.h"

@interface LinkManagementViewController ()

@end

@implementation LinkManagementViewController
@synthesize parentURL = _parentURL;
@synthesize repositoryItem = _repositoryItem;
@synthesize accountUUID = _accountUUID;
@synthesize fileLinks = _fileLinks;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
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
    //[self.tableView registerClass:[LinkTableViewCell class] forCellReuseIdentifier:@"LinkCellIdentifier"];
    
    [self.tableView addLongPressRecognizer];
    
    self.title = @"Link Management";
    if (IS_IPAD) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(back:)];
    }
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addLink:)];
    [self.tableView registerNib:[UINib nibWithNibName:@"LinkTableViewCell" bundle:nil] forCellReuseIdentifier:@"LinkCellIdentifier"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 4;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LinkTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LinkCellIdentifier" forIndexPath:indexPath];
    
    cell.lblLinkName.text = @"Name:tim.lei@bdt-cn.com";
    cell.lblLinkExpirationDate.text = @"Expiration Date:2014-06-30";
    cell.lblLinkURL.text = @"Https://dataspace.cc/cmis/atom/content?324354325423543254325432543";
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (float) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80.0f;
}

#pragma mark -
#pragma mark Actions
- (void) addLink:(id) sender {
    NSLog(@"add link");
    CreateLinkViewController *createLinkController = [[CreateLinkViewController alloc] init];
    
    [self.navigationController pushViewController:createLinkController animated:YES];
}

- (void) back:(id) sender {
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - TableView Long Press Delegate methods
- (void)tableView:(UITableView *)tableView didRecognizeLongPressOnRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
    NSLog(@"Long press cell:%d", indexPath.row);
    
    UIActionSheet *sheet = [[UIActionSheet alloc]
                            initWithTitle:NSLocalizedString(@"operation.pop.menu.title", @"Operations")
                            delegate:self
                            cancelButtonTitle:nil
                            destructiveButtonTitle:nil
                            otherButtonTitles: nil];
    
    [sheet addButtonWithTitle:NSLocalizedString(@"Delete", @"Delete")];
    [sheet addButtonWithTitle:NSLocalizedString(@"Edit", @"Edit")];
    
	[sheet setCancelButtonIndex:[sheet addButtonWithTitle:NSLocalizedString(@"add.actionsheet.cancel", @"Cancel")]];
    
    if (IS_IPAD)
    {
        //[self setActionSheetSenderControl:sender];
        [sheet setActionSheetStyle:UIActionSheetStyleDefault];
        
        //UIBarButtonItem *actionButton = (UIBarButtonItem *)sender;
        
        CGRect actionButtonRect = cell.frame;
        actionButtonRect.size.height = actionButtonRect.size.height/2;
        if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]))
        {
            actionButtonRect.origin.y = 10;
            [sheet showFromRect:actionButtonRect inView:cell animated:YES];
        }
        else
        {
            // iOS 5.1 bug workaround
            actionButtonRect.origin.y += 70;
            [sheet showFromRect:actionButtonRect inView:self.view.window animated:YES];
            
        }
    }
    else
    {
        [sheet showInView:[[self tabBarController] view]];
    }
	
    //[sheet setTag:kOperationActionSheetTag];
}
@end
