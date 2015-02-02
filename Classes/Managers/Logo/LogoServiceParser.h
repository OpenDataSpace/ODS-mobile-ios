//
//  LogoServiceParser.h
//  FreshDocs
//
//  Created by  Tim Lei on 1/6/15.
//
//

#import <Foundation/Foundation.h>
#import "RepositoryInfo.h"

@protocol NSXMLParserDelegate;
@interface LogoServiceParser : NSObject <NSXMLParserDelegate>

@property (nonatomic, copy, readonly) NSData *serviceDocData;
@property (nonatomic, strong) RepositoryInfo *currentRepositoryInfo;
@property (nonatomic, strong) NSMutableDictionary *repositoryInfoDictionary;
@property (nonatomic, copy) NSString *currentCollectionHref;
@property (nonatomic, copy) NSString *elementBeingParsed;
@property (nonatomic, copy) NSString *namespaceBeingParsed;
@property (nonatomic, copy) NSString *collectionType;
@property (nonatomic, strong) NSMutableArray *collectionMediaTypeAcceptArray;
@property (nonatomic, assign) BOOL inCMISRepositoryInfoElement;
@property (nonatomic, copy) NSString *currentTemplateValue;
@property (nonatomic, copy) NSString *currentTemplateType;
@property (nonatomic, copy) NSString *accountUuid;
@property (nonatomic, copy) NSString *tenantID;

@property (nonatomic, strong) NSMutableArray *parserResult;

- (id)initWithAtomPubServiceDocumentData:(NSData *)appData;
- (void)parse; // synchronous parse

@end
