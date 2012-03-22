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
//  AccountTypeViewController.m
//

#import "AccountTypeViewController.h"
#import "TableCellViewController.h"
#import "AccountInfo.h"
#import "Theme.h"
#import "AppProperties.h"
#import "UIColor+Theme.h"

static NSString * const kDefaultCloudAccountValues = @"kDefaultCloudAccountValues";
static NSString * const kPlistFileExtension = @"plist";


@interface AccountTypeViewController()
- (UIView *)cloudAccountFooter;
- (TTTAttributedLabel *)serverAccountFooter;
@end

@implementation AccountTypeViewController
@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
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
    [self setTitle:NSLocalizedString(@"accountdetails.title.newaccount", @"New Account")];
    
    [self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                             target:self
                                                                                             action:@selector(cancelAccountSelection:)] autorelease]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)cancelAccountSelection:(id)sender
{
    if(delegate) {
        [delegate accountControllerDidCancel:nil];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (!tableGroups)
	{
		[self constructTableGroups];
	}
	
	if (tableFooters)
	{
		id object = [tableFooters objectAtIndex:section];
		if ([object isKindOfClass:[NSString class]])
		{
			if ([object length] > 0)
			{
				return 30;
			}
		}
        
        if([object isKindOfClass:[UILabel class]]) 
        {
            UILabel *footerLabel = (UILabel *)object;
            return [footerLabel numberOfLines] * 30;
        }
	}
    
	return 60;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (!tableGroups)
	{
		[self constructTableGroups];
	}
	
	if (tableFooters)
	{
		id object = [tableFooters objectAtIndex:section];
		if ([object isKindOfClass:[NSString class]])
		{
			if ([object length] > 0)
			{
                UIView *originalView = [super tableView:tableView viewForFooterInSection:section];
				return originalView;
			}
		}
        
        if ([object isKindOfClass:[UIView class]])
		{
            return object;
		}
	}
    
	return nil;
}

#pragma mark - GenericTableView
- (void)constructTableGroups
{
    // Arrays for section headers, bodies and footers
	NSMutableArray *groups = [NSMutableArray array];
    NSMutableArray *footers = [NSMutableArray array];
    
    TableCellViewController *alfrescoCell = [[[TableCellViewController alloc] initWithAction:@selector(performAlfrescoTap:) onTarget:self] autorelease];
    [alfrescoCell.textLabel setText:NSLocalizedString(@"accounttype.button.alfresco", @"Alfresco Server")];
    [alfrescoCell.imageView setImage:[UIImage imageNamed:@"server.png"]];
    
    TableCellViewController *alfrescoMeCell = [[[TableCellViewController alloc] initWithAction:@selector(performAlfrescoMeTap:) onTarget:self] autorelease];
    [alfrescoMeCell.textLabel setText:NSLocalizedString(@"accounttype.button.alfrescome", @"Alfresco Cloud")];
    [alfrescoMeCell.imageView setImage:[UIImage imageNamed:@"cloud.png"]];
    
    NSArray *alfrescoGroup = [NSMutableArray arrayWithObject:alfrescoCell];
    NSArray *alfrescoMeGroup = [NSMutableArray arrayWithObject:alfrescoMeCell];
    
    [groups addObject:alfrescoGroup];
    [footers addObject:[self serverAccountFooter]];
    
    [groups addObject:alfrescoMeGroup];
    [footers addObject:[self cloudAccountFooter]];
    
    [tableGroups release];
    [tableFooters release];
    tableGroups = [groups retain];
    tableFooters = [footers retain];

	[self assignFirstResponderHostToCellControllers];
}

- (UIView *)cloudAccountFooter
{
    NSString *signupText = NSLocalizedString(@"accounttype.footer.signuplink", @"New to Alfresco? Sign up...") ;
    NSString *footerText = NSLocalizedString(@"accounttype.footer.alfrescome", @"Access your Alfresco in the cloud account");
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 0)];
    [footerView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth];
    
    UILabel *footerTextView = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    [footerTextView setAdjustsFontSizeToFitWidth:YES];
    [footerTextView setBackgroundColor:self.tableView.backgroundColor];
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
    [signupLabel setBackgroundColor:self.tableView.backgroundColor];
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
//         NSRange signupRange = [completeText rangeOfString:signupText];
//         
//         // Core Text APIs use C functions without a direct bridge to UIFont.
//         UIFont *boldSystemFont = [UIFont boldSystemFontOfSize:14]; 
//         CTFontRef font = CTFontCreateWithName((CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
//         
//         if (signupRange.length > 0 && font) 
//         {
//             [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(id)font range:signupRange];
//             CFRelease(font);
//         }
         
         return mutableAttributedString;
     }];
    
    NSRange signupRange = [signupText rangeOfString:NSLocalizedString(@"accounttype.footer.signuplink.linktext", @"Sign up")];
    if (signupRange.length > 0) 
    {
        NSString *signupLink = [NSString stringWithFormat:[AppProperties propertyForKey:kAlfrescoMeSignupLink],
                                IS_IPAD ? @"tablet" : @"phone",
                                [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
        [signupLabel addLinkToURL:[NSURL URLWithString:signupLink] withRange:signupRange];
        [signupLabel setDelegate:self];
    }
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

- (TTTAttributedLabel *)serverAccountFooter
{
    TTTAttributedLabel *footerLabel = [[[TTTAttributedLabel alloc] initWithFrame:CGRectZero] autorelease];
    [footerLabel setAdjustsFontSizeToFitWidth:YES];
    [footerLabel setBackgroundColor:self.tableView.backgroundColor];
    [footerLabel setUserInteractionEnabled:YES];
    [footerLabel setTextAlignment:UITextAlignmentCenter];
    [footerLabel setVerticalAlignment:TTTAttributedLabelVerticalAlignmentTop];
    [footerLabel setTextColor:[UIColor colorWIthHexRed:76.0 green:86.0 blue:108.0 alphaTransparency:1]];
    [footerLabel setFont:[UIFont systemFontOfSize:15]];
    [footerLabel setText:NSLocalizedString(@"accounttype.footer.alfresco", @"Connect to an Alfresco Server")];
    return footerLabel;
}

- (void)performAlfrescoTap:(id)sender
{
    AccountViewController *newAccountController = [[AccountViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [newAccountController setIsEdit:YES];
    [newAccountController setIsNew:YES];
    [newAccountController setDelegate:self.delegate];
    
    AccountInfo *newAccount = [[AccountInfo alloc] init];
    [newAccount setProtocol:kFDHTTP_Protocol];
    [newAccount setPort:kFDHTTP_DefaultPort];
    [newAccountController setAccountInfo:newAccount];
    
    [self.navigationController pushViewController:newAccountController animated:YES];
    [newAccountController release];
    [newAccount release];
}

- (void)performAlfrescoMeTap:(id)sender
{
    //Set the default values for alfresco cloud
    NSString *path = [[NSBundle mainBundle] pathForResource:kDefaultAccountsPlist_FileName ofType:kPlistFileExtension];
    NSDictionary *defaultAccountsPlist = [[[NSDictionary alloc] initWithContentsOfFile:path] autorelease];
    
    NSDictionary *defaultCloudValues = [defaultAccountsPlist objectForKey:kDefaultCloudAccountValues];
    
    AccountInfo *account = [[AccountInfo alloc] init];
    [account setProtocol:kFDHTTP_Protocol];
    [account setPort:kFDHTTP_DefaultPort];
    [account setVendor:[defaultCloudValues objectForKey:@"Vendor"]];
    [account setDescription:[defaultCloudValues objectForKey:@"Description"]];
    [account setProtocol:[defaultCloudValues objectForKey:@"Protocol"]];
    [account setHostname:[defaultCloudValues objectForKey:@"Hostname"]];
    [account setPort:[defaultCloudValues objectForKey:@"Port"]];
    [account setServiceDocumentRequestPath:[defaultCloudValues objectForKey:@"ServiceDocumentRequestPath"]];
    [account setMultitenant:[defaultCloudValues objectForKey:@"Multitenant"]];
    
    AccountViewController *newAccountController = [[AccountViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [newAccountController setIsEdit:YES];
    [newAccountController setIsNew:YES];
    [newAccountController setDelegate:self.delegate];
    [newAccountController setAccountInfo:account];
    
    [self.navigationController pushViewController:newAccountController animated:YES];
    [newAccountController release];
    [account release];
}

- (void)openSignupLink:(id)sender {
    NSString *signupLink = [AppProperties propertyForKey:kAlfrescoMeSignupLink];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:signupLink]];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    /*
    [[UIApplication sharedApplication] openURL:url];*/
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"NewCloudAccountConfiguration" ofType:@"plist"];
    FDGenericTableViewController *viewController = [FDGenericTableViewController genericTableViewWithPlistPath:plistPath andTableViewStyle:UITableViewStyleGrouped];
    [[self navigationController] pushViewController:viewController animated:YES];
}

@end
