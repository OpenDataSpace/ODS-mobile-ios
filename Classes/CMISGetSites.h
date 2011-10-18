//
//  CMISGetSites.h
//  Alfresco
//
//  Created by Michael Muller on 10/29/09.
//  Copyright 2009 Michael J Muller. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CMISQueryDownload.h"

@interface CMISGetSites : CMISQueryDownload {
}

- (CMISGetSites *)initWithDelegate:(id <AsynchronousDownloadDelegate>)del;
@end
