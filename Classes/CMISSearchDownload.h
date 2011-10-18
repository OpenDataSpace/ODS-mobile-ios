//
//  CMISSearchDownload.h
//  Alfresco
//
//  Created by Michael Muller on 10/28/09.
//  Copyright 2009 Michael J Muller. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CMISQueryDownload.h"

@interface CMISSearchDownload : CMISQueryDownload {
}

- (id)initWithSearchPattern:(NSString *)pattern delegate:(id <AsynchronousDownloadDelegate>)del;

@end
