//
//  RepositoryInfo.h
//  FreshDocs
//
//  Created by Gi Hyun Lee on 9/27/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 * NOTE: Make sure that the property name matches the element name (without the namespace) from the
 * service document and by key-value coding, the property will be set when the service document is loaded.
 *
 * Currently does not handle capabilities.
 */

@interface RepositoryInfo : NSObject {
@private
	NSString *repositoryId;
	NSString *repositoryName;
	NSString *vendorName;
	
	NSString *rootFolderId;
	NSString *cmisVersionSupported;
	
	NSString *rootFolderHref;
	NSString *cmisQueryHref;
//	NSString *queryHref;  TODO: Implement 
}
@property (nonatomic, retain) NSString *repositoryId;
@property (nonatomic, retain) NSString *repositoryName;
@property (nonatomic, retain) NSString *vendorName;

@property (nonatomic, retain) NSString *rootFolderId;
@property (nonatomic, retain) NSString *cmisVersionSupported;

@property (nonatomic, retain) NSString *rootFolderHref;
@property (nonatomic, retain) NSString *cmisQueryHref;

- (BOOL)isPreReleaseCmis;

@end
