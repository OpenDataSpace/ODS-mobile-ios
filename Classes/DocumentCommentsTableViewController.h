//
//  DocumentCommentsTableViewController.h
//  FreshDocs
//
//  Created by Gi Hyun Lee on 7/20/11.
//  Copyright 2011 Zia Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFGenericTableViewController.h"
#import "AddCommentViewController.h"

@interface DocumentCommentsTableViewController : IFGenericTableViewController <AddCommentViewDelegate, ASIHTTPRequestDelegate> {
    NSString *cmisObjectId;
}

@property (nonatomic, retain) NSString *cmisObjectId;

- (id)initWithCMISObjectId:(NSString *)objectId;
@end
