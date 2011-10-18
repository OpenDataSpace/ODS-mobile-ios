//
//  SearchResultsDownload.h
//  Alfresco
//
//  Created by Michael Muller on 10/23/09.
//  Copyright 2009 Michael J Muller. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsynchonousDownload.h"

@protocol NSXMLParserDelegate;

@interface SearchResultsDownload : AsynchonousDownload<NSXMLParserDelegate>  {
	NSMutableArray *results;
	NSString *elementBeingParsed;
    NSString *currentNamespaceURI;
}

@property (nonatomic, retain) NSMutableArray *results;
@property (nonatomic, retain) NSString *elementBeingParsed;
@property (nonatomic, retain) NSString *currentNamespaceURI;

- (SearchResultsDownload *) initWithSearchPattern:(NSString *)pattern delegate: (id <AsynchronousDownloadDelegate>) del;

@end
