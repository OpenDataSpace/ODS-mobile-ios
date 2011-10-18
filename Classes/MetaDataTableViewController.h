//
//  MetaDataTableViewController.h
//  FreshDocs
//
//  Created by Gi Hyun Lee on 7/11/11.
//  Copyright 2011 Zia Consulting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IFGenericTableViewController.h"
#import "TaggingHttpRequest.h"



@protocol MetaDataTableViewDelegate;

@interface MetaDataTableViewController : IFGenericTableViewController <ASIHTTPRequestDelegate>
{
    id <MetaDataTableViewDelegate> delegate;
    NSString *cmisObjectId;
    NSDictionary *metadata;
	NSDictionary *propertyInfo;
    NSURL *describedByURL;
    NSString *mode;
    NSArray *tagsArray;
}

@property (nonatomic, assign) id <MetaDataTableViewDelegate> delegate;

@property (nonatomic, retain) NSString *cmisObjectId;
@property (nonatomic, retain) NSDictionary *metadata;
@property (nonatomic, retain) NSDictionary *propertyInfo;
@property (nonatomic, retain) NSURL *describedByURL;
@property (nonatomic, retain) NSString *mode;
@property (nonatomic, retain) NSArray *tagsArray;

@end


@protocol MetaDataTableViewDelegate <NSObject>
@optional
- (void)tableViewController:(MetaDataTableViewController *)controller metadataDidChange:(BOOL)metadataDidChange;
@end
