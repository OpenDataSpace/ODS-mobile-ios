//
//  ***** BEGIN LICENSE BLOCK *****
//  Version: MPL 1.1
//
//  The contents of this file are subject to the Mozilla Public License Version
//  1.1 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS" basis,
//  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
//  for the specific language governing rights and limitations under the
//  License.
//
//  The Original Code is the Alfresco Mobile App.
//  The Initial Developer of the Original Code is Zia Consulting, Inc.
//  Portions created by the Initial Developer are Copyright (C) 2011
//  the Initial Developer. All Rights Reserved.
//
//
//  ***** END LICENSE BLOCK *****
//
//
//  MetaDataTableViewController.m
//

#import "MetaDataTableViewController.h"
#import "Theme.h"
#import "MetaDataCellController.h"
#import "IFTemporaryModel.h"
#import "IFMultilineCellController.h"
#import "PropertyInfo.h"
#import "IFTextCellController.h"
#import "CMISUpdateProperties.h"
#import "NodeRef.h"
#import "Utility.h"
#import "RepositoryServices.h"

static NSArray * cmisPropertiesToDisplay = nil;

@implementation MetaDataTableViewController
@synthesize delegate;
@synthesize cmisObjectId;
@synthesize metadata;
@synthesize propertyInfo;
@synthesize describedByURL;
@synthesize mode;
@synthesize tagsArray;

- (void)dealloc
{
    [cmisObjectId release];
    [metadata release];
	[propertyInfo release];
    [describedByURL release];
    [mode release];
    [tagsArray release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

+ (void)initialize {
    if (! cmisPropertiesToDisplay) {
        cmisPropertiesToDisplay = [[NSArray alloc] initWithObjects:@"cmis:createdBy", @"cmis:creationDate", 
                                   @"cmis:lastModifiedBy", @"cmis:lastModificationDate", @"cmis:name", @"cmis:versionLabel", nil];
        
    }
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        [self setMode:@"VIEW_MODE"];  // TODO... Constants // VIEW | EDIT | READONLY (?)
        [self setTagsArray:nil];
    }
    return self;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    BOOL usingAlfresco = [[RepositoryServices shared] isCurrentRepositoryVendorNameEqualTo:kAlfrescoRepositoryVendorName];
    
    [Theme setThemeForUINavigationBar:self.navigationController.navigationBar];
    
    [self.navigationItem setTitle:[metadata objectForKey:@"cmis:name"]]; // XXX should check if value exists
    
    if ([self.mode isEqualToString:@"VIEW_MODE"]) {
        
        // TODO Check if editable
    
//        UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit 
//                                                                                    target:self 
//                                                                                    action:@selector(editButtonPressed)];
//        [self.navigationItem setRightBarButtonItem:editButton];
//        [editButton release];
    }
    else if ([self.mode isEqualToString:@"EDIT_MODE"]) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone 
                                                                                    target:self 
                                                                                    action:@selector(doneButtonPressed)];
        [self.navigationItem setRightBarButtonItem:doneButton];
        [doneButton release];
        
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
                                                                                      target:self action:@selector(cancelButtonPressed)];
        [self.navigationItem setLeftBarButtonItem:cancelButton animated:YES];
        [cancelButton release];
    }

    if (usingAlfresco) {
        @try {
            TaggingHttpRequest *request = [TaggingHttpRequest httpRequestGetNodeTagsForNode:[NodeRef nodeRefFromCmisObjectId:cmisObjectId]];
            [request setDelegate:self];
            [request startAsynchronous];
        }
        @catch (NSException *exception) {
            NSLog(@"Failed to retrieve tags");
        }
        @finally {
        }
    }

}


-(void)requestFinished:(TaggingHttpRequest *)request
{
    if ([NSThread isMainThread]) {
        NSArray *parsedTags = [TaggingHttpRequest tagsArrayWithResponseString:[request responseString]];
        [self setTagsArray:parsedTags];
        [self updateAndReload];
    } else {
        [self performSelectorOnMainThread:@selector(requestFinished:) withObject:request waitUntilDone:NO];
    }
}

-(void)requestFailed:(TaggingHttpRequest *)request
{
    NSLog(@"faild");
}

- (void)editButtonPressed {
    MetaDataTableViewController *viewController = [[MetaDataTableViewController alloc] initWithStyle:UITableViewStylePlain];
    [viewController setMode:@"EDIT_MODE"];
    [viewController setMetadata:[[self.metadata copy] autorelease]];
    [viewController setPropertyInfo:[[self.propertyInfo copy] autorelease]];
    [viewController setDescribedByURL:self.describedByURL];
    [viewController setDelegate:self.delegate];
    
    [self.navigationController pushViewController:viewController animated:YES];
    [viewController release];
}

- (void)doneButtonPressed {
    // NSLOG DO SOMETHING
    NSLog(@"DONE BUTTON PRESSED, EXECUTE A SAVE!");
    
    // Peform Save
    
    if (self.delegate) {
        [self.delegate tableViewController:self metadataDidChange:YES];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)cancelButtonPressed {
    
    if (self.delegate) {
        [self.delegate tableViewController:self metadataDidChange:NO];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
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
    // Always Rotate
    return YES;
}


#pragma mark -
#pragma mark Generic Table View Construction

- (void)constructTableGroups
{
    if (![self.model isKindOfClass:[IFTemporaryModel class]]) {
        IFTemporaryModel *tempModel = [[IFTemporaryModel alloc] initWithDictionary:metadata];
        [self setModel:tempModel];
        [tempModel release];
	}
    
    // Arrays for section headers, bodies and footers
	NSMutableArray *headers = [NSMutableArray array];
	NSMutableArray *groups =  [NSMutableArray array];
	NSMutableArray *footers = [NSMutableArray array];
    
    NSMutableArray *metadataCellGroup = [NSMutableArray arrayWithCapacity:[metadata count]];

    NSArray *sortedKeys = [[metadata allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    for (NSString *key in sortedKeys) {
        
        if ( ! [cmisPropertiesToDisplay containsObject:key]) {
            // Skip - this is specific to Alfresco
            continue;
        }
        
        PropertyInfo *i = [self.propertyInfo objectForKey:key];
        
        NSString *displayKey = i.displayName ? i.displayName : key;
        displayKey = [NSString stringWithFormat:@"%@:", displayKey];
        
        if (self.mode && [self.mode isEqualToString:@"EDIT_MODE"]) { // TODO Externalize this string
            
            IFTextCellController *cellController = [[IFTextCellController alloc] initWithLabel:displayKey andPlaceholder:@"" 
                                                                                         atKey:key inModel:self.model];
            [metadataCellGroup addObject:cellController];
            [cellController release];

            // FIXME: IMPLEMENT ME
            
        } else {

            if ([i.propertyType isEqualToString:@"datetime"]) {
                NSString *value = formatDateTime([model objectForKey:key]);
                key = [key stringByAppendingString:@"Ex"];
                [model setObject:value forKey:key];
            }
            
            MetaDataCellController *cellController = [[MetaDataCellController alloc] initWithLabel:displayKey 
                                                                                             atKey:key inModel:self.model];
            [metadataCellGroup addObject:cellController];
            [cellController release];
        }
    }
    
    // TODO: Handle Edit MOde
    if (self.tagsArray && ([tagsArray count] > 0)) {
        [model setObject:([tagsArray componentsJoinedByString:@", "]) forKey:@"tags"];
        MetaDataCellController *tagsCellController = [[MetaDataCellController alloc] initWithLabel:@"Tags:" atKey:@"tags" inModel:self.model];
        [metadataCellGroup addObject:tagsCellController];
        [tagsCellController release];
    }
    
    [headers addObject:@""];
	[groups addObject:metadataCellGroup];
	[footers addObject:@""];
    
    
    tableGroups = [groups retain];
	tableHeaders = [headers retain];
	tableFooters = [footers retain];
	[self assignFirstResponderHostToCellControllers];
}

#pragma mark -
#pragma mark MetaDataTableViewDelegate

- (void)tableViewController:(MetaDataTableViewController *)controller metadataDidChange:(BOOL)metadataDidChange
{
    // TODO
    
}


@end
