//
//  ServiceDocumentParser.h
//  FreshDocs
//
//  Created by Gi Hyun Lee on 11/10/10.
//  Copyright 2010 Zia Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RepositoryServices.h"

@protocol NSXMLParserDelegate;
@interface ServiceDocumentParser : NSObject<NSXMLParserDelegate> {
@private
	NSData *serviceDocData;
	RepositoryInfo *currentRepositoryInfo;
	NSMutableDictionary *repositoryInfoDictionary;
	
	NSString *currentCollectionHref;
	NSString *elementBeingParsed;
	NSString *namespaceBeingParsed;
	NSString *collectionType;
	NSMutableArray *collectionMediaTypeAcceptArray;
	
	BOOL inCMISRepositoryInfoElement;
}
@property (nonatomic, copy, readonly) NSData *serviceDocData;
@property (nonatomic, retain) RepositoryInfo *currentRepositoryInfo;
@property (nonatomic, retain) NSMutableDictionary *repositoryInfoDictionary;
@property (nonatomic, retain) NSString *currentCollectionHref;
@property (nonatomic, retain) NSString *elementBeingParsed;
@property (nonatomic, retain) NSString *namespaceBeingParsed;
@property (nonatomic, retain) NSString *collectionType;
@property (nonatomic, retain) NSMutableArray *collectionMediaTypeAcceptArray;
@property (nonatomic, assign) BOOL inCMISRepositoryInfoElement;

- (id)initWithAtomPubServiceDocumentData:(NSData *)appData;
- (void)parse; // synchronous parse

@end
