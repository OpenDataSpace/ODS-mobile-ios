//
//  FavoritesViewController.h
//  Alfresco
//
//  Created by Michael Muller on 10/7/09.
//  Copyright 2009 Zia Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DirectoryWatcher.h"

//
//	TODO: Rename this class to something to the terms of "LocalFileSystemBrowser"
//


@interface FavoritesViewController : UITableViewController <DirectoryWatcherDelegate, UIDocumentInteractionControllerDelegate> {
@private
	DirectoryWatcher *dirWatcher;
}
@property (nonatomic, retain) DirectoryWatcher *dirWatcher;

@end

