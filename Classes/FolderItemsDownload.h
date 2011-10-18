//
//  FolderItemsDownload.h
//  Alfresco
//
//  Created by Michael Muller on 10/21/09.
//  Copyright 2009 Michael J Muller. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsynchonousDownload.h"
#import "RepositoryItem.h"

@protocol NSXMLParserDelegate;

@interface FolderItemsDownload : AsynchonousDownload<NSXMLParserDelegate>  {
	RepositoryItem *item;
	NSMutableArray *children;
	NSString *currentCMISName;
	NSString *elementBeingParsed;
	NSString *context;
	NSString *parentTitle;
	NSString *valueBuffer;
    NSString *currentNamespaceURI;
}

@property (nonatomic, retain) RepositoryItem *item;
@property (nonatomic, retain) NSMutableArray *children;
@property (nonatomic, retain) NSString *currentCMISName;
@property (nonatomic, retain) NSString *elementBeingParsed;
@property (nonatomic, retain) NSString *context;
@property (nonatomic, retain) NSString *parentTitle;
@property (nonatomic, retain) NSString *valueBuffer;
@property (nonatomic, retain) NSString *currentNamespaceURI;

// TODO: Remove the 1 deprecated method!!!
- (FolderItemsDownload *) initWithNode:(NSString *)node delegate:(id <AsynchronousDownloadDelegate>)del __attribute__ ((deprecated));

- (FolderItemsDownload *)initWithAtomFeedUrlString:(NSString *)urlString delegate:(id <AsynchronousDownloadDelegate>)theDelegate;
@end
