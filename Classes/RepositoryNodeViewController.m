//
//  RepositoryNodeViewController.m
//  Alfresco
//
//  Created by Michael Muller on 9/1/09.
//  Copyright 2009 Zia Consulting. All rights reserved.
//

#import "CMISTypeDefinitionDownload.h"
#import "RepositoryNodeViewController.h"
#import "DocumentViewController.h"
#import "RepositoryItemTableViewCell.h"
#import "Utility.h"
#import "RepositoryItem.h"
#import "FolderItemsDownload.h"
#import "NSData+Base64.h"
#import "UIImageUtils.h"
#import "Theme.h"
#import "RepositoryServices.h"
#import "LinkRelationService.h"
#import "MetaDataTableViewController.h"
#import "UploadFormTableViewController.h"
#import "IFTemporaryModel.h"
#import "SavedDocument.h"

@implementation RepositoryNodeViewController

@synthesize guid;
@synthesize folderItems;
@synthesize downloadProgressBar;
@synthesize postProgressBar;
@synthesize itemDownloader;
@synthesize contentStream;
@synthesize popover;
@synthesize alertField;

- (void)dealloc {
	[guid release];
	[folderItems release];
	[downloadProgressBar release];
	[itemDownloader release];
	[contentStream release];
	[popover release];
	[alertField release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    BOOL hideAddButton = [[[RepositoryServices shared] currentRepositoryInfo] isPreReleaseCmis];
	
	replaceData = NO;
	if (!hideAddButton && nil != [folderItems item] && ([folderItems item].canCreateFolder || [folderItems item].canCreateDocument)) {
		[[self navigationItem] setRightBarButtonItem:
		 [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
													   target:self action:@selector(performAction:)] autorelease]];
	}


	[Theme setThemeForUITableViewController:self];
    [self.tableView setRowHeight:60.0f];
}

//- (void)didReceiveMemoryWarning {
//    [super didReceiveMemoryWarning];
//}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)performAction:(id)sender {
	if (IS_IPAD) {
		if(nil != popover && [popover isPopoverVisible]) {
			[popover dismissPopoverAnimated:YES];
            [self setPopover:nil];
		}
	} 
    
	UIActionSheet *sheet = [[UIActionSheet alloc]
							initWithTitle:@""
							delegate:self 
							cancelButtonTitle:nil
							destructiveButtonTitle:nil 
							otherButtonTitles: nil];
	
	
	if (folderItems.item.canCreateDocument) {
		BOOL hasCamera = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
		if (hasCamera) {
			[sheet addButtonWithTitle:@"Take Photo"];
		}
		[sheet addButtonWithTitle:@"Choose Photo from Library"];
	}
    
    if (folderItems.item.canCreateFolder) {
		[sheet addButtonWithTitle:@"Create Folder"];
	}
	
	[sheet setCancelButtonIndex:[sheet addButtonWithTitle:@"Cancel"]];
    
	[sheet showInView:[[self tabBarController] view]];
	[sheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *buttonLabel = [actionSheet buttonTitleAtIndex:buttonIndex];
	if (![buttonLabel isEqualToString:@"Cancel"]) {
        
        // TODO
        // Re-implement using a switch and button indices.  
        //
        
        if ([buttonLabel isEqualToString:@"Upload a Photo"]) {
            UploadFormTableViewController *formController = [[UploadFormTableViewController alloc] init];
            [formController setExistingDocumentNameArray:[folderItems valueForKeyPath:@"children.title"]];
            [formController setUpLinkRelation:[[self.folderItems item] identLink]];
            [formController setUpdateAction:@selector(metaDataChanged)];
            [formController setUpdateTarget:self];
            
            
            [self.navigationController pushViewController:formController animated:YES];
            [formController release];
        }
		else if ([buttonLabel isEqualToString:@"Choose Photo from Library"]) {
			UIImagePickerController *picker = [[UIImagePickerController alloc] init];
			[picker setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
			[picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
			[picker setDelegate:self];
			
			if (IS_IPAD) {
                UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:picker];
                [self setPopover:popoverController];
                [popoverController release];
                
                [popover presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem 
                                permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
			} else  {
				[[self navigationController] presentModalViewController:picker animated:YES];
			}
            
			[picker release];
            
		}
        else if ([buttonLabel isEqualToString:@"Take Photo"]) {
			UIImagePickerController *picker = [[UIImagePickerController alloc] init];
			[picker setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
			[picker setSourceType:UIImagePickerControllerSourceTypeCamera];
			[picker setDelegate:self];
			
			if (IS_IPAD) 
            {
                UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:picker];
                [self setPopover:popoverController];
                [popoverController release];
                
                [popover presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem 
                                permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
                
                NSLog(@"On an iPad so showing the popover");
			} 
            else {
				[[self navigationController] presentModalViewController:picker animated:YES];
            }
			
			[picker release];
            
		} 
        else if ([buttonLabel isEqualToString:@"Create Folder"]) {
			UIAlertView *alert = [[UIAlertView alloc] 
								  initWithTitle:@"Name:"
								  message:@" \r\n "
								  delegate:self 
								  cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel Button Text")
								  otherButtonTitles:NSLocalizedString(@"okayButtonText", @"OK Button Text"), nil];
            
			self.alertField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 45.0, 260.0, 25.0)];
			[alertField setBackgroundColor:[UIColor whiteColor]];
			[alert addSubview:alertField];
			[alert show];
			[alert release];
		}
	}
}


#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info 
{
//	UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
//	image = [image imageByScalingToWidth:1024];
//	if (nil != image) {
//		self.contentStream = [NSData dataWithData:UIImagePNGRepresentation(image)];
//		UIAlertView *alert = [[UIAlertView alloc] 
//							  initWithTitle:@"Enter a Name:"
//							  message:@" "
//							  delegate:self 
//                              cancelButtonTitle:NSLocalizedString(@"closeButtonText", @"Cancel Button Text")
//                              otherButtonTitles:NSLocalizedString(@"okayButtonText", @"OK Button Text"), nil];
//  		
//		self.alertField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 45.0, 260.0, 25.0)];
//		[alertField setBackgroundColor:[UIColor whiteColor]];
//			[alert addSubview:alertField];
//
//		[alert show];
//		[alert release];
//	}
    
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
	image = [image imageByScalingToWidth:1024];
    
    [picker dismissModalViewControllerAnimated:YES];
    if (IS_IPAD) {
		if(nil != popover && [popover isPopoverVisible]) {
			[popover dismissPopoverAnimated:YES];
            [self setPopover:nil];
		}
	}
    
	if (nil != image) 
    {    
        UploadFormTableViewController *formController = [[UploadFormTableViewController alloc] init];
        [formController setExistingDocumentNameArray:[folderItems valueForKeyPath:@"children.title"]];
        [formController setUpLinkRelation:[[self.folderItems item] identLink]];
        [formController setUpdateAction:@selector(metaDataChanged)];
        [formController setUpdateTarget:self];
        
        IFTemporaryModel *formModel = [[IFTemporaryModel alloc] init];
        [formModel setObject:image forKey:@"media"];
        [formController setModel:formModel];
        [formModel release];
        
        [self.navigationController pushViewController:formController animated:YES];
        [formController release];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker 
{
	[picker dismissModalViewControllerAnimated:YES];
    if (IS_IPAD) {
		if(nil != popover && [popover isPopoverVisible]) {
			[popover dismissPopoverAnimated:YES];
            [self setPopover:nil];
		}
	}
}

- (void)didPresentAlertView:(UIAlertView *)alertView {
	[alertField becomeFirstResponder];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (IS_IPAD) {
		if(nil != popover && [popover isPopoverVisible]) {
			[popover dismissPopoverAnimated:YES];
            [self setPopover:nil];
		}
	}
    
	NSString *userInput = [alertField text];
	NSString *strippedUserInput = [userInput stringByReplacingOccurrencesOfString:@" " withString:@""];
	self.alertField = nil;
	
	if (1 == buttonIndex && [strippedUserInput length] > 0) {
		if (nil != contentStream) {
			NSString *postBody  = [NSString stringWithFormat:@""
								   "<?xml version=\"1.0\" ?>"
								   "<entry xmlns=\"http://www.w3.org/2005/Atom\" xmlns:app=\"http://www.w3.org/2007/app\" xmlns:cmisra=\"http://docs.oasis-open.org/ns/cmis/restatom/200908/\">"
								   "<cmisra:content>"
								   "<cmisra:mediatype>image/png</cmisra:mediatype>"
								   "<cmisra:base64>%@</cmisra:base64>"
								   "</cmisra:content>"
								   "<cmisra:object xmlns:cmis=\"http://docs.oasis-open.org/ns/cmis/core/200908/\">"
								   "<cmis:properties>"
								   "<cmis:propertyId propertyDefinitionId=\"cmis:objectTypeId\">"
								   "<cmis:value>cmis:document</cmis:value>"
								   "</cmis:propertyId>"
								   "</cmis:properties>"
								   "</cmisra:object><title>%@.png</title></entry>",
								   [contentStream base64EncodedString],
								   userInput
								   ];
			NSLog(@"POSTING DATA: %@", postBody);
			self.contentStream = nil;
			
			RepositoryItem *item = [folderItems item];
			NSString *location   = [item identLink];
			NSLog(@"TO LOCATION: %@", location);
			
			self.postProgressBar = 
			[PostProgressBar createAndStartWithURL:[NSURL URLWithString:location]
									   andPostBody:postBody
										  delegate:self 
										   message:NSLocalizedString(@"Uploading Photo", @"Uploading Photo")];
		} else {
			NSString *postBody = [NSString stringWithFormat:@""
								  "<?xml version=\"1.0\" ?>"
								  "<entry xmlns=\"http://www.w3.org/2005/Atom\" xmlns:app=\"http://www.w3.org/2007/app\" xmlns:cmisra=\"http://docs.oasis-open.org/ns/cmis/restatom/200908/\">"
								  "<title type=\"text\">%@</title>"
								  "<cmisra:object xmlns:cmis=\"http://docs.oasis-open.org/ns/cmis/core/200908/\">"
								  "<cmis:properties>"
								  "<cmis:propertyId  propertyDefinitionId=\"cmis:objectTypeId\">"
								  "<cmis:value>cmis:folder</cmis:value>"
								  "</cmis:propertyId>"
								  "</cmis:properties>"
								  "</cmisra:object>"
								  "</entry>", userInput];
			NSLog(@"POSTING DATA: %@", postBody);
			
			RepositoryItem *item = [folderItems item];
			NSString *location   = [item identLink];
			NSLog(@"TO LOCATION: %@", location);
			
			self.postProgressBar = 
				[PostProgressBar createAndStartWithURL:[NSURL URLWithString:location]
								 andPostBody:postBody
								 delegate:self 
								 message:@"Creating Folder"];
		}
	}
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[folderItems children] count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	RepositoryItemTableViewCell *cell = (RepositoryItemTableViewCell *) [tableView dequeueReusableCellWithIdentifier:RepositoryItemCellIdentifier];
    if (cell == nil) {
		NSArray *nibItems = [[NSBundle mainBundle] loadNibNamed:@"RepositoryItemTableViewCell" owner:self options:nil];
		cell = [nibItems objectAtIndex:0];
		NSAssert(nibItems, @"Failed to load object from NIB");
    }
       
	RepositoryItem *child = [[folderItems children] objectAtIndex:[indexPath row]];
    
    // work around for those cmis producers that aren't compliant and do not
    // include all required attributes, for this case, cmis:name.  Will use the atom title instead
    NSString *fileName = [child.metadata valueForKey:@"cmis:name"];
    if (!fileName || ([fileName length] == 0)) {
        fileName = child.title;
    }
    [cell.filename setText:fileName];

    
    //	cell.details.text = [[NSString alloc] initWithFormat:@"%@ %@", child.lastModifiedBy, formatDateTime(child.lastModifiedDate)];
	if ([child isFolder]) {
        UIImage * img = [UIImage imageNamed:@"folder.png"];
		cell.imageView.image  = img;
        cell.details.text = [[NSString alloc] initWithFormat:@"%@", formatDateTime(child.lastModifiedDate)]; // TODO: Externalize to a configurable property?
	}
	else {
        NSString *contentStreamLengthStr = [child contentStreamLengthString];
        if ([child contentStreamLengthString] == nil) {
            contentStreamLengthStr = [child.metadata objectForKey:@"cmis:contentStreamLength"];
        }
        cell.details.text = [[NSString alloc] initWithFormat:@"%@ | %@", formatDateTime(child.lastModifiedDate), [SavedDocument stringForLongFileSize:[contentStreamLengthStr longLongValue]]]; // TODO: Externalize to a configurable property?
		cell.imageView.image = imageForFilename(child.title);
	}
    
	[cell setAccessoryType:(([[[RepositoryServices shared] currentRepositoryInfo] isPreReleaseCmis])
							? UITableViewCellAccessoryNone
							: UITableViewCellAccessoryDetailDisclosureButton)];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	RepositoryItem *child = [[folderItems children] objectAtIndex:[indexPath row]];
	
	if ([child isFolder]) {
		[self.itemDownloader.urlConnection cancel];
		
		NSDictionary *optionalArguments = [[LinkRelationService shared] 
										   optionalArgumentsForFolderChildrenCollectionWithMaxItems:nil skipCount:nil filter:nil 
										   includeAllowableActions:YES includeRelationships:NO renditionFilter:nil orderBy:nil includePathSegment:NO];
		NSURL *getChildrenURL = [[LinkRelationService shared] getChildrenURLForCMISFolder:child 
																   withOptionalArguments:optionalArguments];
		FolderItemsDownload *down = [[FolderItemsDownload alloc] initWithURL:getChildrenURL delegate:self];
		[self setItemDownloader:down];
		down.item = child;
		down.parentTitle = child.title;
		[down start];
		[down release];
	}
	else {
		if (child.contentLocation) {
			NSString *urlStr  = child.contentLocation;
			NSURL *contentURL = [NSURL URLWithString:urlStr];
			[self setDownloadProgressBar:[DownloadProgressBar createAndStartWithURL:contentURL delegate:self 
                                                                          message:NSLocalizedString(@"Downloading Document", @"Downloading Document")
                                                                         filename:child.title contentLength:[child contentStreamLength]]];
            [[self downloadProgressBar] setCmisObjectId:[child guid]];
            [[self downloadProgressBar] setCmisContentStreamMimeType:[[child metadata] objectForKey:@"cmis:contentStreamMimeType"]];
		}
		else {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"noContentWarningTitle", @"No content")
                                                            message:NSLocalizedString(@"noContentWarningMessage", @"This document has no content.") 
                                                           delegate:nil 
                                                  cancelButtonTitle:NSLocalizedString(@"okayButtonText", @"OK Button Text")
                                                  otherButtonTitles:nil];
			[alert show];
            [alert release];
		}
	}
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {

	RepositoryItem *child = [[folderItems children] objectAtIndex:[indexPath row]];
	
	CMISTypeDefinitionDownload *down = [[CMISTypeDefinitionDownload alloc] initWithURL:[NSURL URLWithString:child.describedByURL] delegate:self];
	down.repositoryItem = child;
	[down start];
	[down release];
	
}

- (void) asyncDownloadDidComplete:(AsynchonousDownload *)async {
	
	if ([async isKindOfClass:[FolderItemsDownload class]]) {
		// if we're reloading then just tell the view to update
		if (replaceData) {
			replaceData = NO;
			[((UITableView *)[self view]) reloadData];
			[[self tableView] reloadData];
		}
		// otherwise we're loading a child which needs to
		// be created and pushed onto the nav stack
		else {
			FolderItemsDownload *fid = (FolderItemsDownload *) async;

			// create a new view controller for the list of repository items (documents and folders)
			RepositoryNodeViewController *vc = [[RepositoryNodeViewController alloc] initWithNibName:nil bundle:nil];

			vc.folderItems = fid;
			vc.title = fid.parentTitle;

			// push that view onto the nav controller's stack
			[self.navigationController pushViewController:vc animated:YES];
			[vc release];
		}
	}
	else if ([async isKindOfClass:[CMISTypeDefinitionDownload class]]) {
		CMISTypeDefinitionDownload *tdd = (CMISTypeDefinitionDownload *) async;
        MetaDataTableViewController *viewController = [[MetaDataTableViewController alloc] initWithStyle:UITableViewStylePlain];
        [viewController setCmisObjectId:tdd.repositoryItem.guid];
        [viewController setMetadata:tdd.repositoryItem.metadata];
        [viewController setPropertyInfo:tdd.properties];
        [self.navigationController pushViewController:viewController animated:YES];
        [viewController release];
	}
}

- (void)metaDataChanged
{
	replaceData = YES;
	RepositoryItem *currentNode = [folderItems item];
	NSDictionary *optionalArguments = [[LinkRelationService shared] 
									   optionalArgumentsForFolderChildrenCollectionWithMaxItems:nil skipCount:nil filter:nil 
									   includeAllowableActions:YES includeRelationships:NO renditionFilter:nil orderBy:nil includePathSegment:NO];
	NSURL *getChildrenURL = [[LinkRelationService shared] getChildrenURLForCMISFolder:currentNode 
															   withOptionalArguments:optionalArguments];

	FolderItemsDownload *down = [[FolderItemsDownload alloc] initWithURL:getChildrenURL delegate:self];
	[down setItem:currentNode];
	[down start];
	[self setFolderItems:down];
	[down release];
}

- (void) asyncDownload:(AsynchonousDownload *)async didFailWithError:(NSError *)error {
	
}

- (void) download:(DownloadProgressBar *)down completeWithData:(NSData *)data {

	NSString *nibName = @"DocumentViewController";
	DocumentViewController *doc = [[DocumentViewController alloc] initWithNibName:nibName bundle:[NSBundle mainBundle]];
	[doc setCmisObjectId:down.cmisObjectId];
    [doc setFileData:data];
    [doc setFileName:down.filename];
    [doc setContentMimeType:[down cmisContentStreamMimeType]];
    [doc setHidesBottomBarWhenPushed:YES];
	
	[self.navigationController pushViewController:doc animated:YES];	
	[doc release];
}

- (void) post:(PostProgressBar *)bar completeWithData:(NSData *)data {	
	// cause our folderItems object to update
	// we're going to handle this ourselves so
	// we need to know to update ourself rather 
	// than loading a new subview.
	replaceData = YES;
	[self.itemDownloader.urlConnection cancel];
	[folderItems setDelegate:self];
	self.itemDownloader = folderItems;
	[folderItems restart];	
}

@end
