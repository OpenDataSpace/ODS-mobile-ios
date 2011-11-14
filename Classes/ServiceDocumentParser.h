/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Alfresco Mobile App.
 *
 * The Initial Developer of the Original Code is Zia Consulting, Inc.
 * Portions created by the Initial Developer are Copyright (C) 2011
 * the Initial Developer. All Rights Reserved.
 *
 *
 * ***** END LICENSE BLOCK ***** */
//
//  ServiceDocumentParser.h
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
    
    BOOL isUriTemplate;
    NSString *currentTemplateValue;
    NSString *currentTemplateType;
	
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
@property (nonatomic, retain) NSString *currentTemplateValue;
@property (nonatomic, retain) NSString *currentTemplateType;

- (id)initWithAtomPubServiceDocumentData:(NSData *)appData;
- (void)parse; // synchronous parse

@end
