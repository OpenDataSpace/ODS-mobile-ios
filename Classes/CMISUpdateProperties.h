//
//  CMISUpdateProperties.h
//  FreshDocs
//
//  Created by Michael Muller on 5/13/10.
//  Copyright 2010 Michael J Muller. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsynchonousDownload.h"

@interface CMISUpdateProperties : AsynchonousDownload {
	NSString *putData;
}

@property (nonatomic, retain) NSString *putData;

- (id) initWithURL:(NSURL *)u propertyInfo:(NSMutableDictionary *)propertyInfo originalMetadata:(NSMutableDictionary *)orig editedMetadata:(NSMutableDictionary *) edit delegate: (id <AsynchronousDownloadDelegate>) del;

@end

