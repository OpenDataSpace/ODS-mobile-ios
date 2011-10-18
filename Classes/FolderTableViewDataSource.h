//
//  FolderTableViewDataSource.h
//  FreshDocs
//
//  Created by Gi Hyun Lee on 11/9/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FolderTableViewDataSource : NSObject <UITableViewDataSource> {
@private
	NSURL *folderURL;
	NSString *folderTitle;
	NSMutableArray *children;
	
//	NSMutableDictionary *sections;
}
@property (nonatomic, readonly, retain) NSURL *folderURL;
@property (nonatomic, readonly, retain) NSString *folderTitle;
@property (nonatomic, readonly, retain) NSMutableArray *children;

- (id)initWithURL:(NSURL *)url;

- (void)refreshData;
- (id)cellDataObjectForIndexPath:(NSIndexPath *)indexPath;
@end
