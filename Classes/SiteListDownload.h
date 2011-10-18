//
//  SiteListDownload.h
//  Alfresco
//
//  Created by Michael Muller on 10/21/09.
//  Copyright 2009 Michael J Muller. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsynchonousDownload.h"

@interface SiteListDownload : AsynchonousDownload {
	NSMutableArray *results;
}

@property (nonatomic, retain) NSMutableArray *results;

- (SiteListDownload *)initWithDelegate:(id <AsynchronousDownloadDelegate>)del;

@end
