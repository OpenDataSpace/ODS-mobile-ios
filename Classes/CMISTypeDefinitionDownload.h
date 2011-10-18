//
//  CMISTypeDefinitionDownload.h
//  FreshDocs
//
//  Created by Michael Muller on 5/11/10.
//  Copyright 2010 Michael J Muller. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsynchonousDownload.h"
#import "PropertyInfo.h"
#import "RepositoryItem.h"

@protocol NSXMLParserDelegate;

@interface CMISTypeDefinitionDownload : AsynchonousDownload<NSXMLParserDelegate> {
	NSString *elementBeingParsed;
	PropertyInfo *propertyBeingParsed;
	NSMutableDictionary *properties;
	RepositoryItem *repositoryItem;
}

@property (nonatomic, retain) NSString *elementBeingParsed;
@property (nonatomic, retain) PropertyInfo *propertyBeingParsed;
@property (nonatomic, retain) NSMutableDictionary *properties;
@property (nonatomic, retain) RepositoryItem *repositoryItem;

@end
