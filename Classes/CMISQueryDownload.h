//
//  CMISQueryDownload.h
//  Alfresco
//
//  Created by Michael Muller on 10/29/09.
//  Copyright 2009 Michael J Muller. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsynchonousDownload.h"

@protocol NSXMLParserDelegate;

@interface CMISQueryDownload : AsynchonousDownload<NSXMLParserDelegate> {
	NSMutableArray *results;
	NSString *elementBeingParsed;
    NSString *namespaceBeingParsed;
	NSString *currentCMISProperty;
	NSString *currentCMISPropertyValue;
	NSString *postData;
}

@property (nonatomic, retain) NSMutableArray *results;
@property (nonatomic, retain) NSString *currentCMISProperty;
@property (nonatomic, retain) NSString *currentCMISPropertyValue;
@property (nonatomic, retain) NSString *elementBeingParsed;
@property (nonatomic, retain) NSString *namespaceBeingParsed;
@property (nonatomic, retain) NSString *postData;

- (id)initWithQuery:(NSString *)cql delegate:(id <AsynchronousDownloadDelegate>)del;


@end
